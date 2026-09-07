# PLAN.md — Vault Terminal + On-Demand Production

Working plan for the item-vault interface (design doc problem #2) and on-demand
production (#3a), arrived at over a long design conversation. Committed to the
repo (rather than kept only in chat) so it survives context compaction during
an unattended implementation run, and so the reasoning behind each decision is
recoverable later. Superseded/updated sections should be edited in place, not
left stale — this is a working doc, not a changelog.

## Scope

**Built (phase 1):** vault terminal (list/pull/craft CLI), head/secondary
terminal roles over rednet, config-driven peripheral/job/resource mapping.

**Built (phase 2):** `craft`'s executor now chains multiple job levels via
`lib/Planner.kt`'s `ensureStocked` (e.g. raw copper → copper ingot →
copper sheet) rather than only a single direct recipe — see "CLI" below.
Recurses into a missing input before running the current level's job, so
jobs execute in dependency order purely via call-stack unwinding (no
explicit job-list data structure, which ktox has no good collection type
for anyway). Guarded by `MAX_PLANNER_DEPTH` (5) against a cyclic
resource-tree config. **Known gap:** `list --craftable`'s classification
(`ktoxListCatalog` in ktox-cc-shim.lua) still only checks ONE hop — an
item needing a 2+-level chain to produce shows as "unavailable" in `list`
even though `craft` could actually produce it. Left as-is for now
(disclosed here rather than fixed) since `list`'s job is just a quick
status glance, not a plan preview — worth revisiting if that mismatch
turns out to confuse people in practice.

**Explicitly out of scope for this pass:** factory-floor load balancing
(problem #3b, config-driven stock-percentage preferences — deferred entire
problem), monitor touch UI (CLI supersedes it for now; monitors would be
read-only dashboards if built later, never interactive), concurrent push/
pull handling, the GraphQL/web dashboard idea (someday-later).

## Terminal roles

One **head** terminal is the sole decision-maker — owns all vault/redstone/
job state, runs the actual program. Any number of **secondary** terminals
are thin clients: they capture local keyboard input (their own `read()`),
forward the raw command text to the head via `rednet`, and print back
whatever response the head sends. Secondaries never decide anything and
never run the real logic — this is a deliberate simplification agreed on
specifically to avoid distributed-decision bugs (two terminals disagreeing
about what to do).

`rednet` works over a **wired** modem, not just wireless — since terminals
are already on the wired peripheral network for vault access, no separate
wireless infrastructure is needed for head↔secondary messaging.

**Startup, not remote exec:** CC:Tweaked has no remote-code-execution
primitive — one computer cannot make another start running a program. Each
terminal's client/head program is deployed independently (via `ghfetch`,
same as everything else) and auto-starts from its own local `startup.lua`.
The head never "launches" secondaries; it only exchanges rednet messages
with whichever ones happen to already be running.

**Role collision detection**, in two places:
1. The `TerminalSetup` program pings the network before committing a fresh
   machine to the head role, and refuses (with a clear message) if a head
   already answers.
2. The head's own `startup.lua`/boot path repeats this check as a safety
   net, in case setup was bypassed — refuses to proceed if another head
   answers.

Ping responses carry role directly, over their own `rednet` protocol tag
(`"vault-role-query"`/`"vault-role-reply"`). As-built this uses plain
string payloads, not Lua tables as originally sketched here — Kotlin's
native bindings need concrete scalar types, and a fixed protocol tag
already does the job of separating message kinds cleanly (see "Generic
peripheral-call shim" below for the same lesson learned the hard way with
`ktoxPeripheralCall`'s argument packing).

**No retry/self-heal loop for terminals** — they don't move, and a player
will manually reboot one that's stuck. Not worth the complexity.

**Crafter role** — a third kind of terminal, for a crafty turtle running
`turtle.craft()`. Like a secondary, it never decides anything and is a
thin client to the head's commands — but unlike a secondary, it has no
player-facing CLI at all, it just sits listening on rednet for two things
on its own dedicated protocols:
- `"vault-crafter-query"` (payload: a job type) — if the payload matches
  this crafter's own configured job type (set at provisioning time, see
  below), reply "yes" (echoing the job type back) on
  `"vault-crafter-reply"`. This is how the head finds "who handles job
  X" — same broadcast-and-listen shape as head discovery, just filtered
  by job type instead of role, and deliberately with **no** collision
  detection: multiple crafters answering the same job type isn't guarded
  against in phase 1 (unlike a second head, which is refused outright).
- `"vault-crafter-cmd"` (payload: a quantity) — craft that many, then
  drop everything the turtle is holding toward whatever it's physically
  facing. This turtle is expected to be positioned facing an ordinary
  storage vault, so the drop lands the result straight back in the pool —
  a **physical `turtle.drop()`**, not a network push. (Not a workaround
  for anything unsupported — see "Vaults" below, a network push/pull
  targeting the turtle's own inventory is now assumed to work fine, same
  as a pickup vault — this is just the simpler, already-working mechanism
  and hasn't been changed.) The head never needs an explicit
  "done" signal back — it just polls the storage pool for the output
  count exactly like a machine job (see "CLI" below), so a crafter job
  and a machine job look identical from the executor's point of view
  once the craft command has been sent.

The head still does all the deciding: it computes how many ingredient
sets are needed, pushes each ingredient into the crafter turtle's
*specific* crafting-grid slot (`pushItems`'s optional 4th argument,
target slot — slot numbers 1, 2, 3, 5, 6, 7, 9, 10, 11 form the 3x3 grid
inside the turtle's 16 slots; this mapping is my best understanding of
`turtle.craft()`'s expected layout, **unverified in-game**), then sends
the craft command. The crafter turtle only ever executes, never plans.

Provisioning: `terminalsetup crafter <jobType>` writes `role.txt` as
`crafter:<jobType>` (vs. plain `head`/`secondary`) — `startup.lua` parses
the `crafter:` prefix and launches `Crafter <jobType>` automatically on
every boot, same auto-launch mechanism as the other two roles.

**Unverified, flagged for in-game testing** (same caveat as the rest of
the rednet/parallel work — see "Known open items"): the exact
`turtle.craft()` grid-slot mapping, whether `turtle.craft()`'s result
lands somewhere `dumpAllForward()`'s "select every slot, drop if
non-empty" sweep actually catches, and the full head→crafter round trip
end to end.

## Vaults

Five kinds, distinguished by `job.type` in `peripherals.json` (see below):

- **Storage vaults** — raw pooled storage. Machines/farms drop output into
  these. All storage-job vaults are treated as **one logical resource
  pool** — `list`/`pull`/`craft` reason about total counts across every
  storage vault, not any single one. Load-balancing (spreading pushes
  toward the emptiest vault, preference-routing toward the vault a given
  farm normally feeds) is a real requirement but **not built in phase 1**
  — flagged here so it isn't forgotten, not attempted yet.
- **Job-input (feeder) vaults** — sit next to a funnel/chute feeding a
  machine, and must be empty except when a job is actively running. The
  `type` of machine they can trigger comes from `peripherals.json`
  (`job.type`, e.g. `"mechanical_press_depot"`). Triggering a job means
  toggling the relevant Clutch/Funnel via a Redstone Relay (see below),
  then pushing the required input material into the feeder vault.
- **Pickup vault** (`job.type: "pickup"`) — where `pull`/`craft` results
  land for a player (or turtle) to grab. Any addressable inventory
  peripheral can be a pickup vault, **including a turtle's own
  inventory** — earlier revisions of this doc treated "a turtle
  targeting its own inventory as a named `pushItems`/`pullItems`
  peripheral" as unreliable and routed around it (an ordinary vault
  block next to the terminal, always). That caveat was never actually
  verified against real hardware — it was an untested assumption, not a
  confirmed CC:Tweaked limitation — and is now treated as working; see
  "Known open items" below. `peripherals.json` can configure any number
  of pickup vaults, each optionally labeled with a `"name"` (its
  routable location name — see "CLI" below for `craft --location=`) and
  at most one marked `"default": true` (a missing `"default"` field
  behaves as `false`, no separate handling needed — Lua's own falsy
  `nil`). A head/secondary terminal that's itself wired in as a pickup
  vault (i.e. its own peripheral name has a `job.type: "pickup"` entry)
  is preferred over the configured default for that terminal's own
  `pull`/`craft` calls — see `ktoxSelfPeripheralName()` in
  `ktox-cc-shim.lua`.
- **Trash vault** (`job.type: "trash"`) — dumps whatever's pushed into it
  into lava, permanently. Functionally identical wiring to a feeder
  vault (a vault + funnel), but semantically very different: it's never
  a target for anything automatic (no resource-tree.lua entry, nothing
  routes to it implicitly) — only the explicit `trash <name> <qty>`
  command touches it, since destroying items is irreversible.
- **Passive feeder** (`job.type: "passive"`, with `item`, `lowWatermark`,
  `highWatermark` fields alongside `type`) — sits above a Deployer (the
  vault+chute+deployer pattern is a very consistent piece of Create
  logistics, and lets the deployer pull what it needs on its own once
  the feeder above it is stocked). Unlike a job-input feeder, nothing
  *triggers* this — the head opportunistically tops it up (pulling from
  the storage pool up to `highWatermark`) whenever its current count
  drops below `lowWatermark`, checked after handling each local or
  remote command (see "Terminal roles" → HeadTerminal.kt, and
  `lib/PassiveFeeder.kt`) rather than on an independent timer. A head
  sitting fully idle won't top these up until its next command — an
  accepted, disclosed limitation (a real timer risks starving itself:
  see the code comment for why). This is a narrower, much more
  tractable version of the #3b factory-balancing idea floated earlier
  and deferred entirely — "maintain N of item X" needs none of the
  cross-item-precedence logic that made #3b hard. The top-up itself calls
  `ensureStocked()` (the phase-2 planner) before pulling from the pool,
  not just a flat pull — so a passive feeder can trigger real production
  when the pool itself is short (e.g. a Blaze Burner's charcoal supply
  triggers the `smelter` job smelting logs, not just redistributing
  whatever charcoal already happens to exist).

  **"Fuel" is a conceptual category, not a vault/job type of its own** —
  a Blaze Burner accepts charcoal, coal, Dried Kelp Block, *and* Lava
  Bucket interchangeably. Rather than generalize `"passive"` to accept a
  list of interchangeable items (real complexity: summing across several
  items for one watermark, deciding which to pull first), each fuel type
  the player actually wants automated just gets its **own** independent
  passive feeder — four small feeders is simpler than one feeder with
  list-valued config, and physically matches how a player would wire
  several funnels (each with its own item filter) into one Blaze Burner
  anyway. No schema change needed for this; `job-types.lua`/
  `resource-tree.lua` just needed the actual chains that *produce* the
  less-obvious fuels: Dried Kelp Block needs `smoker` (kelp → dried kelp
  — a Smoker, not a Furnace/`smelter`, matters here: smoking and smelting
  are genuinely different vanilla mechanics that happen to both be
  redstone-optional "machine" jobs in this schema) then
  `mechanical_press_basin` (9 dried kelp → 1 block, a *compacting*
  recipe — the same Mechanical Press block as `mechanical_press_depot`,
  but positioned over a Basin instead of a Depot/belt, a genuinely
  different physical setup and so a genuinely different job type despite
  sharing a machine name). Lava Bucket needs `lava_spout`: a Spout fills
  a Bucket with Lava from a Tank — since the Lava itself is a fluid
  (out of scope, see above), this is modeled as a single solid-only
  input/output pair (`minecraft:bucket` → `minecraft:lava_bucket`),
  treating the lava supply as ambient/always-available rather than
  tracked — a deliberate simplification, not an oversight. The empty
  buckets a Spout needs are themselves just another passive feeder
  (`minecraft:bucket`, low 4 / high 16 in the example config) sitting at
  the Spout's depot.

Stockpile Switch is a good fit for storage-vault fullness (aggregate fill
%, doesn't care about item identity) but **not** for per-item shortage
detection on a mixed vault — that still requires software-side counting
via `list()`/`getItemDetail`. Not wired up in phase 1; noted for later.

## Farms

A **farm** (`job-types.lua` entries with `kind: "farm"`) is an external,
always-running process this system can gate on/off — a cobblestone
generator feeding a crushing/washing chain, a kelp farm, a wood farm.
This system doesn't know or care how a farm works internally (chance-
based crushing, mob farming, crop farming — the internal mechanism is
irrelevant); it's just a relay toggle plus a list of outputs to watch in
the storage pool:

```json
"iron_andesite_farm": {
  "kind": "farm",
  "watermarks": [
    { "item": "minecraft:iron_ingot", "lowWatermark": 64, "highWatermark": 256 },
    { "item": "minecraft:andesite", "lowWatermark": 64, "highWatermark": 256 }
  ]
}
```

`manageFarms()` (`lib/Farm.kt`) turns a farm **on** if ANY tracked output
is below its low watermark (something's genuinely short), and **off**
only once ALL tracked outputs are above their high watermark — a
multi-output farm (like the one above) only shuts off once every output
it's responsible for is oversupplied, since turning it off while even
one is still short would starve that one. Left alone in the hysteresis
band between low and high, same reasoning as passive feeders (avoids
flapping on/off near a threshold). Called opportunistically after each
head interaction, same mechanism and same "not a real timer" reasoning
as `topUpPassiveFeeders()` — a head sitting fully idle won't gate farms
until its next command, an accepted limitation for the same reason.

This is why farms exist as a *concept* separate from jobs at all: a farm
that produces something via a chance-based recipe (Splashing's Gravel →
Flint 25%/Iron Nugget 12.5%, for instance) can never be modeled as a job
(no guaranteed yield to poll for), but it very much *can* be watched and
gated based on its own accumulated output — the farm doesn't need to
know or report how much it made this cycle, the system just checks the
pool periodically and decides whether the tap should be open or closed.
A handful of always-on farms with no gating at all risk quickly
saturating storage precisely because they never stop — this is the
actual motivating problem manageFarms() solves.

**A farm's own inputs are the same "raw material" question as an**
**ungated one** — `wood_farm` produces `minecraft:oak_log` with no
resource-tree.lua entry needed at all (nothing converts *into* a log in
this system; it just appears via the farm). Downstream consumers (the
`smelter` job's `oak_log → charcoal` recipe, say) treat farm output
exactly like any other stocked item — the farm boundary is invisible to
everything past the storage pool.

## Redstone control

- **Clutch** — gates rotational power into a machine (the general-purpose
  "turn this machine off" mechanism, since most Create machines have no
  native redstone input).
- **Funnel/Chute** — gates item flow in/out, redstone-blockable.
- **Redstone Relay** — a real CC:Tweaked peripheral (not Advanced
  Peripherals) mirroring the `redstone` global API (`getInput`/
  `setOutput`/analog variants), reachable remotely over the wired network
  from any computer, as long as the Relay itself has its own wired modem.
  Since the vault peripheral network already needs cable everywhere, this
  cable does double duty for redstone control — no separate redstone wire
  run needed within the network's footprint.
- **Redstone Link** (Create) — wireless redstone, for the one case cable
  isn't run (a machine on another floor). Not a CC peripheral itself; a
  Relay feeds the physical signal into the Link transmitter's face, the
  Link carries it wirelessly, the far end drives the Clutch/Funnel
  directly or through another local Relay.

## Configs (`peripherals.json` — JSON, confirmed native via
`textutils.serializeJSON`/`unserializeJSON`; `job-types.lua`/
`resource-tree.lua` — plain Lua data files, see below for why)

**Ownership split, revised:** only `peripherals.json` is 100% player-owned
— it encodes physical facts about one specific world (which peripheral
sits where), which the code must never hardcode and `ghfetch` must never
overwrite; the player maintains it starting from the shipped
`peripherals.example.json` template. `job-types.lua` and
`resource-tree.lua` describe the *game's* recipe graph — the same
across every world running this mod list — so they're centrally
maintained in this repo and **fetched fresh every `ghfetch` run**,
overwriting whatever's on the turtle, same as any other program file.
That's a change from the original plan (all three were meant to be
player-owned) — recipes are objective facts about the modpack, not
per-world configuration, so keeping them in sync centrally is strictly
better than asking every player to hand-maintain their own copy.

**1. `peripherals.json`** — maps peripheral name → type/job. Example
shape:

A "job" is recursive — `{"type": "<kind>", "job"?: <nested job>}` — so a
feeder vault's job nests the machine it feeds:

```json
{
  "create:item_vault_0": { "type": "vault", "job": { "type": "storage" } },
  "create:item_vault_1": {
    "type": "vault",
    "job": {
      "type": "feeder",
      "job": { "type": "mechanical_press_depot" }
    }
  },
  "create:item_vault_2": { "type": "vault", "job": { "type": "pickup" } },
  "computercraft:redstone_relay_0": {
    "type": "relay",
    "connections": {
      "right": { "job": { "type": "smelter" } },
      "left": { "job": { "type": "mechanical_press_depot" } }
    }
  }
}
```

**2. `job-types.lua`** — what each job type's execution `kind` is
(`"machine"` — redstone relay + feeder vault; `"crafter"` — a crafty
turtle running `turtle.craft()`; `"farm"` — an always-running external
process gated by watermarks; defaults to `"machine"` when omitted, so
every job type from before crafty turtles existed still works
unchanged), and an optional per-job `timeoutSeconds` override. No
`"produces"` list (an earlier version had one) — nothing ever read it,
and keeping it in sync with thousands of `resource-tree.lua` entries
would be pure maintenance burden for no runtime benefit:

```lua
return {
  smelter = { kind = "machine" },
  pressing = { kind = "machine" },
  mixing_heated = { kind = "machine", timeoutSeconds = 45 },
}
```

**3. `resource-tree.lua`** — a **flat list of recipes**, not keyed by a
single input (see below for why), each with ratios (input:output counts)
so the executor knows how much raw material to push for a requested
output quantity, and a list of inputs so multi-ingredient recipes (brass:
copper + zinc) and shaped crafter recipes (an ingredient pinned to a
specific turtle crafting-grid slot) both fit the same shape:

```lua
return {
  recipes = {
    {
      output = "create:copper_sheet",
      outputCount = 1,
      job = "pressing",
      inputs = { { item = "minecraft:copper_ingot", count = 1 } },
    },
    {
      output = "create:brass_ingot",
      outputCount = 2,
      job = "mixing_heated",
      inputs = {
        { item = "minecraft:copper_ingot", count = 1 },
        { item = "create:zinc_ingot", count = 1 },
      },
    },
  },
}
```

`"slot"` (1-9) is an optional third field on an input — present only for
a `kind: "crafter"` job's recipe, naming which of the turtle's 3x3
crafting-grid slots that ingredient goes in; absent for ordinary machine
recipes, where placement doesn't matter.

Note: `job` here is a plain job-type-name string (a leaf reference), unlike
`peripherals.json`'s recursive `{"type": ..., "job": ...}` descriptor —
this file only ever needs to *name* which job type performs a conversion,
never to describe physical routing/nesting.

**Schema history:** this file was originally keyed by a single input item
("what does X convert into"), which cannot represent a recipe needing two
different inputs simultaneously — brass needs copper AND zinc, and no
single top-level key could answer "what produces brass." Restructured to
a flat recipe list once that limitation became concrete, per the design
conversation — expect this file's shape to keep evolving as more real
recipes get defined; the JSON syntax is very much not "done."

**Multiple recipes per output, with automatic preference.** A single
output can legitimately have more than one real recipe — e.g.
`create:andesite_alloy` can be made from andesite + iron nugget *or*
andesite + zinc nugget (both real recipes shipped in Create's own data).
Rather than "first entry wins" (silently arbitrary, and dependent on
`pairs()` iteration order, which Lua does not guarantee), every recipe
lookup (`ktoxConfigProducesLookup`, used by `craft`/the planner; and
`ktoxListCatalog`'s catalog-building pass, used by `list --craftable`)
runs all matching entries through a shared `ktoxPreferRecipe(candidate,
currentBest)` helper in `ktox-cc-shim.lua`, so both call sites can never
disagree about which recipe "the" output resolves to. Preference order:
an explicit `"priority"` field on the recipe (lower number wins) beats
everything else; absent that, the recipe with the lower
`totalInputCount / outputCount` (i.e. fewer raw materials per unit
output) wins as a heuristic guess at "more efficient." `"priority"` is
optional — most recipes still only have one entry and never need it.

**Config reads are cached per file path for the process lifetime,
regardless of format.** `ktoxReadJSONFile`/`ktoxReadLuaDataFile` in
`ktox-cc-shim.lua` each keep their own cache table keyed by path; a
second read of the same config file (re-parsed on every single recipe
lookup before this change) returns the already-loaded table instead of
re-reading the file from disk. Safe because none of these config files
change while a program is running — they're only ever refreshed by
`ghfetch`, which runs as its own separate program invocation, not
concurrently with `Head`/`Secondary`/`Crafter`.

**`job-types.lua`/`resource-tree.lua` were later converted to
hand-authored Lua data files** (`config/job-types.lua`,
`config/resource-tree.lua`, each just a `return { ... }` table literal)
once the caching fix above stopped being enough — the resource tree grew
into the thousands of entries during the comprehensive-recipe pass (see
below), and `textutils.unserializeJSON` is a hand-written Lua parser
walking the text byte by byte, while a `.lua` file loads through Lua's
native chunk compiler. `peripherals.json` stays JSON — it's the one file
a player actually hand-edits; a format switch only makes sense for files
this repo generates and `ghfetch` overwrites wholesale. Consuming code
(`ktoxPreferRecipe`, `ktoxConfigProducesLookup`, `ktoxListCatalog`, ...)
didn't change at all, since a `.lua`-returned table and a JSON-parsed
table are the same Lua table shape either way — only the loader changed.

**Fluids are entirely out of scope.** `list()`/`getItemDetail()` only see
solid inventory slots — a Tank peripheral (or any fluid container) isn't
modeled anywhere in this system. Several real, verified Create recipes
were excluded from the actual content specifically for this reason (Lava
from stone/cobble, Builder's Tea, Chocolate as a fluid, Enchantment
Industry's Liquid Experience → Liquid Hyper Experience) — not because
they're unconfirmed, but because this system has no way to track a fluid
quantity at all. Revisit if fluid automation ever becomes a real
requirement; it'd need a new peripheral type and its own counting
primitive, not a small patch to the existing item-counting code.

**Probabilistic-yield recipes are entirely out of scope too, same
category as fluids.** Create's "Splashing" mechanic (colloquially
"washing" — an Encased Fan blowing air through a water source block;
*not* a Water Wheel, an earlier assumption here that turned out wrong)
is mostly chance-based with no deterministic yield at all — e.g. Gravel
→ Flint (25%) *or* Iron Nugget (12.5%), nothing guaranteed either way.
That can't fit a schema built entirely around "push N in, get exactly
M out." Only Splashing's few genuinely deterministic 1:1 recipes made it
into `resource-tree.lua` (a `"washing"` job type: Ice → Packed Ice,
Wheat Flour → Dough, Magma Block → Obsidian) — everything chance-based
was excluded, not approximated.

**This directly resolves how the "endless cobblestone → iron/andesite"
automation pattern should be modeled: as an external farm, not a job.**
It's built entirely on chance-based Splashing/crushing steps (Cobblestone
→ Gravel → Flint/Iron Nugget via Splashing, Andesite via a fluid-
consuming Press+Basin recipe — two more reasons it doesn't fit the job
schema even before considering yield), and it's explicitly "endless" —
always running, nothing ever needs to start or stop it. That's exactly
the mining/farming-turtle pattern from early design: an external process
that just continuously dumps output into a storage vault. Nothing in
`resource-tree.lua` represents this chain's internal steps at all —
`job-types.lua`'s `iron_andesite_farm` entry (see "Farms" above) treats
it as a black box, watching only the final iron ingot/andesite counts
and toggling a relay to gate the whole apparatus on or off, exactly like
`wood_farm`, `kelp_farm`, and `copper_farm`. The system only ever reasons
about what's *inside* the recipe graph after the farm's output lands in
storage (iron ingot → iron sheet, already modeled). A general lesson
worth keeping: **any Create recipe with a percentage chance instead of a
guaranteed count belongs in the farm bucket, not the job bucket** — it
can still be watched and gated as a farm, just never expressed as a
resource-tree recipe — don't try to force one in later without
re-deriving this same conclusion.

**Redstone relays are optional per job, confirmed necessary by real
research** (see `lib/Executor.kt`'s `runDirectJob`): plenty of real
Create machines — a Deployer applying an ingredient to a passing item, a
Mixer basin fed by an always-lit Blaze Burner — run continuously with no
redstone control at all. A job type with no relay configured in
`peripherals.json` is treated as "always on," not as a configuration
error; only a relay that's configured but unreachable in-world counts as
a real failure. This was a genuine bug until the real-recipe research
surfaced it — casing production (a Deployer recipe) would have always
failed under the original "no relay = give up" logic.

**Content build, v1 (2026-09-07):** initial real content, built from two
web-research passes (see `AGENTS.md` "Modpack" section) rather than the
original one-or-two-entry placeholders. Superseded by v2 below almost
immediately — kept here as a record of why v2's methodology change
mattered, not as still-current guidance.

**Methodology change, v2 (2026-09-07, same day):** research from
memory/WebSearch turned out to have real, confirmed error rates —
wrong item IDs (`create:crushed_iron_ore` doesn't exist; the real item
is `create:crushed_raw_iron`), wrong mechanic assumptions (`create:milling`
and `create:crushing` were assumed to be the same recipe type at
different speeds; they're genuinely different machines — Millstone mills
plants/wheat/dyes, Crushing Wheels crush ores/raw materials — with
non-overlapping recipe sets), wrong namespaces (`wheat_flour`/`dough`
are `create:`, not `farmersdelight:`), and at least one fully fabricated
recipe (a `washing: wheat_flour → dough` entry that doesn't exist in any
form — the real `create:dough` recipe needs water, a fluid, so no
solid-only path to it exists in Create's own data at all).

**The actual fix: mod `.jar` files are ZIP archives containing every
recipe as a real JSON file** (Minecraft's own data-driven recipe system,
which every mod here uses) — `data/<namespace>/recipe/**/*.json`,
extractable and inspectable directly, with a `"type"` field naming the
exact mechanic and structured `ingredients`/`results` (results can carry
a `"chance"` field for probabilistic-yield entries — see "Probabilistic-
yield recipes" above; only chance-less entries are guaranteed yield and
schema-eligible). This is strictly better ground truth than any research
pass, including JEI's own approach — JEI doesn't hardcode recipe data
either, it just reads exactly these same files at runtime and renders
them; going straight to the source skips an unnecessary layer. Create's
jar alone has 1884 recipe JSON files (only counting `data/create/recipe`)
across ~24 distinct recipe types — genuinely too many to include
individually (many are decorative-block/stonecutting variants, or
"compat" entries for mods not in this list), so **scope is still
curated, not literally exhaustive** — the difference is every entry that
*is* included is now verified against the actual file, not recalled or
guessed. Re-derive this way (not via web research) whenever expanding
coverage further; `unzip -l <jar> | grep recipe` plus reading the JSONs
directly is fast and authoritative.

**Job types consolidated to be machine-based, not per-item** (raised
directly: a `chest_crafter` job type for one specific crafted item
doesn't scale to the hundreds of things a crafter turtle could plausibly
make). Renamed/merged: `mechanical_press_depot`→`pressing`,
`andesite_mixer`→`mixing_unheated`, `mixer_basin`→`mixing_heated`,
`washing`→`splashing`, `lava_spout`→`filling`, and — the one that was
wrong on the merits, not just the name — the old ore-crushing `"milling"`
job type is now `"crushing"` (Crushing Wheels), freeing up `"milling"`
for the real Millstone mechanic (plant/wheat grinding). Three separate
per-casing job types (`andesite_casing_deployer`/`brass_casing_deployer`/
`copper_casing_deployer`) collapsed into one `"deploying"` job type,
same shared-feeder-vault reasoning as multi-ingredient machine jobs.
`chest_crafter` is now plain `"crafter"` — one generic job type for
*every* turtle-craftable recipe (`minecraft:chest`,
`minecraft:dried_kelp_block`, and anything added later), each recipe
still carrying its own full slot layout in `resource-tree.lua`, so
adding a new turtle-craftable item is a content change, never a new job
type or a new peripheral registration.

**One recipe moved to `crafter` for a mechanism reason, not just
naming:** `minecraft:dried_kelp_block` was originally assumed to be a
Create `"compacting"` recipe (Mechanical Press over a Basin, matching the
9-in-a-square shape) — the real jar data shows no such recipe exists;
Dried Kelp Block is plain vanilla 3×3 crafting, which only the `crafter`
job (a real turtle running `turtle.craft()`) can actually perform in this
system. `"compacting"` survived as a job type on its own real recipe
instead (9× Snow Block → Ice — verified, solid-only).

Coverage, by confidence, current as of the jar-extraction pass:
- **High confidence** (verified directly against the mod jar's own recipe
  JSON): `crushing` (4 metals, corrected item IDs), `smelter` (crushed
  ore → ingot per the jar's bundled vanilla-smelting recipes, plus
  well-established vanilla smelting — cobblestone→stone, sand→glass,
  clay ball→brick — and `create:dough`→`minecraft:bread`, confirmed in
  the jar), `pressing` (all 4 sheets, including `create:brass_sheet`,
  found via the jar and previously missing entirely), `mixing_unheated`
  (Andesite Alloy), `mixing_heated` (Brass Ingot, 2x output confirmed —
  an earlier version had this wrong at 1x), `deploying` (all 3 casings,
  exact ingredient tags confirmed), `compacting` (Snow Block → Ice),
  `milling` (Wheat → Wheat Flour).
- **Medium confidence**: `splashing`'s deterministic entries (Ice→Packed
  Ice, Magma Block→Obsidian — the wrong Wheat Flour→Dough entry was
  removed, not fixed, since no valid solid-only recipe for Dough exists
  at all), `smoker` (vanilla food-cooking pairs — high-confidence general
  knowledge, not individually jar-verified since vanilla recipes aren't
  in any mod's jar). Log stripping via the Slicer, listed here in v2, was
  **wrong** — corrected in the v3 pass below (no such recipe exists at
  all; stripping a log is a vanilla axe interaction, not automatable).
- **Lower confidence** (plausible item IDs, not individually verified —
  spot-check against JEI before relying on these): Farmer's Delight items
  via Slice & Dice (`farmersdelight:chicken_cuts`,
  `farmersdelight:pumpkin_slice`, `farmersdelight:beef_stew`), `filling`
  (`minecraft:bucket`→`minecraft:lava_bucket` — no explicit
  `create:filling` JSON exists for this; a Spout filling a plain bucket
  is inferred to be generic vanilla bucket-fill behavior the Spout also
  performs, not a data-driven recipe, so this one genuinely can't be
  jar-verified either way).
- **Deliberately excluded, not overlooked:** Precision Mechanism (Create's
  Sequenced Assembly is a genuinely different recipe shape — an ordered
  multi-step sequence with a final success-*chance*, not expressible in
  the current single-batch schema; would need real schema work, not a
  content addition — treat as a manually-supplied/raw item for now).
  Create Aeronautics, Create Dragons Plus, and Create Food were
  researched and found to add nothing both concrete and fluid-free enough
  to include confidently — excluded rather than guessed at. Byproduct/
  bonus-chance outputs (e.g., ore crushing's bonus Experience Nugget,
  chicken cutting's bonus bone meal) are ignored throughout — only
  results with no `"chance"` field are modeled, to keep the schema's
  single-deterministic-output assumption intact rather than adding
  chance handling for comparatively low value. Sandpaper Polishing (Rose
  Quartz → Polished Rose Quartz) is real but a single niche recipe with
  unconfirmed Deployer-automation status — excluded as not worth the
  uncertainty. The full "endless cobblestone → iron/andesite" chain is
  excluded for a different reason: see "Probabilistic-yield recipes"
  above — it's a farm, not a job, by design, not by omission.

**Comprehensive extraction pass, v3 (2026-09-06):** v2 above was still
"curated, not literally exhaustive" by design — individual items were
added as they came up in conversation. Superseded by a scripted pipeline
that walks *every* recipe JSON in every installed mod's jar (create,
computercraft, farmersdelight, createfood, bits_n_bobs, sliceanddice,
create_enchantment_industry, displaydelight, create_dragons_plus),
converts each to a `resource-tree.lua` entry, and applies filters rather
than one-at-a-time human judgment:
- Skip anything under a jar's own `.../compat/<mod>/` subfolder for a mod
  that isn't installed, and skip any recipe whose ingredients OR whose
  recipe `"type"` itself belongs to a namespace not in the installed set
  — a recipe can reference only installed-mod items yet still need a
  mechanic/machine from an uninstalled mod (several createfood-bundled
  compat recipes for `ratatouille_fried_delights`/`hearthandharvest`/
  `expandeddelight`/`immersiveengineering` fell into this trap and are
  excluded).
- Skip decorative/cosmetic families entirely: the 16-dye-color axis
  (seats, postboxes, table cloths, toolboxes, chairs, wool/carpet/bed/
  banner/candle/concrete/terracotta/shulker-box/stained-glass variants),
  copper's weathering-stage and wax-toggle axis (`_from_deoxidising`/
  `_from_removing_wax` axe-scraping conversions — the base unweathered,
  unwaxed item still gets its own ordinary recipe elsewhere), and a
  handful of novelty/joke items (CC:Tweaked's easter-egg player heads).
- Skip fluid-bearing recipes wholesale (`create:filling`/`create:emptying`
  in full — every entry of these types involves a fluid on one side by
  definition), **except** two hand-kept exceptions:
  `minecraft:bucket`→`minecraft:water_bucket`/`minecraft:lava_bucket`,
  treating water/lava as the same kind of "ambient, always-available"
  input a farm's watermark gate already assumes, consistent with how
  `filling` was handled before this pass.
- Skip recipe types needing a mechanic this system doesn't model at all:
  `create:mechanical_crafting` (its own 3x3-of-9-simultaneous-items
  machine, not a turtle), `create:sequenced_assembly` (multi-step with a
  final success chance), `create:haunting`, `create:item_copying`,
  `create:toolbox_dyeing`, `create:sandpaper_polishing`,
  `computercraft:impostor_*`/`transform_*` (NBT-preserving "upgrade"
  recipes — attaching a peripheral to a turtle/pocket computer, not a
  plain item-in-item-out conversion), `minecraft:smithing_transform`.
- Skip `minecraft:blasting`/`create:blasting`/`minecraft:campfire_cooking`
  as redundant — they duplicate `smelting`/`smoking` outputs at a
  different speed this system doesn't model, adding volume with no new
  content.
- Ingredient tags (NeoForge `c:` common tags and similar) are resolved
  against tag data **merged across every installed mod's own jar**
  (unioned per tag id, not overwritten by whichever jar happened to
  extract last — an early version of this script got this wrong and
  silently dropped real tag members as a result), falling back to a
  small hand-written override table for well-known conventions
  (redstone dust, glass panes, dyes, crops, nuggets, ...) that aren't
  populated by any installed mod's own tag contribution — those are
  normally supplied by the vanilla game jar or NeoForge itself, neither
  of which this project has a copy of, so they're a documented judgment
  call, not jar-verified.
- **CreateFood scoped down deliberately, not by the same rules as
  everything else above.** The raw extraction pulled 3,280 CreateFood
  entries — a huge per-fruit/topping combinatorial system (cream cakes,
  ice creams, milkshakes, jams, pastries; e.g. `apple_cream_chocolate_
  donut`), not decorative in the dye-color sense but the same kind of
  low-value bulk. Trimmed to just outputs matching soup/pie/pizza/
  skewer/burger, **plus the full ingredient-dependency closure of each**
  (a kept burger still needs its own bun/patty/cheese, even though
  those don't contain "burger" in their own name — an early version of
  this filter missed that and silently produced burgers with no
  reachable ingredients). 165 seed dishes pull in 272 total outputs.
  Explicit scoping decision, not a size accident — the alternative was
  a ~1MB file at or over typical CC:Tweaked computer storage limits;
  this brought the whole corpus (2,246 entries across every mod) to
  about 512KB.

**Real corrections this pass found** (the reason a full re-extraction
was worth doing over patching individual reports of missing items):
- **`minecraft:stripped_oak_log` was wrong to model as a job, initially.**
  An earlier version had it as a `"slicer"` (Mechanical Saw) recipe from
  `oak_log` — no such recipe exists anywhere in Create's *data-driven*
  recipe JSON. Removed rather than fixed, on the assumption stripping was
  a vanilla axe-only interaction with no automatable path at all — this
  assumption itself turned out wrong: **confirmed in-game (2026-09-07)
  that the Mechanical Saw does strip logs**, just as a hardcoded Java
  behavior rather than a JSON recipe, so no amount of jar extraction
  would ever have found it. Re-added to `resource-tree.lua`'s
  `MANUAL_VANILLA_RECIPES` (job `"cutting"`) once confirmed. Farmer's
  Delight's Cutting Board (`"cutting_board"`) turns out to also strip
  logs at the same 1:1 ratio — an explicit `priority` pins the Saw as the
  default winner, since that's the machine actually being built; flip it
  if a build relies on the Cutting Board for this instead.
- **The old `"slicer"` job type conflated two different real machines.**
  It held both `farmersdelight:chicken_cuts`/`pumpkin_slice` (Farmer's
  Delight's Cutting Board) and the (incorrect) stripped-log entry above,
  under one name, as if they were the same machine. Split into
  `"cutting"` (Create's Mechanical Saw — genuinely real, see next point)
  and `"cutting_board"` (Farmer's Delight's Cutting Board) once jar
  extraction made clear these are unrelated pieces of equipment.
- **Shaft is a second real multi-recipe-per-output case, beyond
  Andesite Alloy.** `create:shaft` can be made via ordinary crafting (2x
  `create:andesite_alloy` → 8x shaft) *or* via the Mechanical Saw
  (`create:cutting`, 1x andesite_alloy → 6x shaft) — the saw recipe is
  more input-efficient (1/6 ≈ 0.167 alloy per shaft vs. 2/8 = 0.25), so
  `ktoxPreferRecipe`'s heuristic correctly prefers it with no explicit
  `priority` needed, a good real-world validation of that preference
  logic beyond the Andesite Alloy case it was originally built for.

**Known rough edges flagged for review, not silently resolved:**
- Vanilla-only recipes (ore smelting, food smoking, vanilla crafting-
  table tools/blocks) are still not jar-verifiable — no installed mod
  ships the vanilla game's own recipe data, only mods' own additions.
  The small hand-curated vanilla block in `resource-tree.lua` remains
  general-knowledge-sourced, same confidence level as `v2` above.
- `create:item_vault`'s "wooden barrel" ingredient and a couple of
  CC:Tweaked recipes' "glass pane" ingredient resolved to
  `minecraft:barrel`/`create:tiled_glass_pane` respectively via the
  manual-override/tag-fallback path above, since vanilla's own
  contribution to those shared tags isn't visible without the vanilla
  jar — plausible, not verified.
- `computercraft:wired_modem` has two real recipes: craft from scratch,
  or break a `wired_modem_full` back down into one. The efficiency
  heuristic currently prefers the down-conversion (1 input → 1 output)
  as "the" way to make a modem, which is legitimate but may not be the
  intended default — add an explicit `priority` in `resource-tree.lua`
  if the from-scratch recipe should win instead.
- A handful of CreateFood ingredients (peanut butter, cooked eggplant,
  popcorn, tortilla chips, coffee beans, a few spice items) only
  resolve, in CreateFood's own tag data, to items from OTHER uninstalled
  food mods (croptopia, hearthandharvest, expandeddelight) — CreateFood
  apparently expects one of those to also be installed to supply its own
  concrete item. Excluded rather than guessed at; the handful of recipes
  needing them are missing from the tree as a result.

**One shared job type can't represent several dedicated physical
machines of the same kind, found while wiring up real casing
production (2026-09-07):** `ktoxConfigFeederForJob`/
`ktoxConfigRelayForJob` each return only the *first* peripheral matching
a job type name — fine when one physical machine handles a job type, but
a build with e.g. four separate Deployers (one dedicated to each casing
recipe) can't be told apart by job type alone; every casing would race
for whichever single feeder/relay happened to be found first in
`pairs()` iteration order. Fixed by splitting `"deploying"` into one job
type per physical Deployer — `deploying_andesite`/`deploying_brass`/
`deploying_copper`/`deploying_railway` — each getting its own dedicated
feeder (and optionally relay, though a Deployer that runs continuously
needs none, same as other always-on Create machines). `scripts/
extract_recipes.py`'s `JOB_OVERRIDES_BY_OUTPUT` renames these four
outputs' job field on every regeneration, so re-running the extraction
doesn't silently revert the split back to one shared `"deploying"` type.
This same pattern — several dedicated physical machines producing
different recipes that a generic type-based job mapping would otherwise
lump together — will recur for other job types as more machines are
added; watch for it rather than assuming one feeder/relay per job type
name is always enough.

**A Deployer's held item is a standing supply, not a per-request
ingredient — same category as furnace fuel, found in the same casing
build-out (2026-09-07).** A Deployer holds one item persistently and
reapplies it to whatever passes beneath it; the physical build has a
dedicated `"passive"` vault sitting on top of each Deployer keeping that
held item topped up independently (exactly the existing charcoal/coal
pattern), while a *separate* `"feeder"` vault in front of each Deployer's
belt is what `craft` actually pushes the per-request ingredient
(`minecraft:stripped_oak_log`, or `create:brass_casing` for the railway
casing) into. Every smelter recipe already omits fuel from its `inputs`
for exactly this reason — a smelter recipe only lists its ore, never the
charcoal that has to be burning alongside it — so the four casing
recipes in `resource-tree.lua` were brought in line with that same
precedent: `create:andesite_alloy`/`create:brass_ingot`/
`minecraft:copper_ingot`/`create:sturdy_sheet` were dropped from their
respective casing recipes' `inputs` entirely (`scripts/
extract_recipes.py`'s `STANDING_SUPPLY_INPUT_OVERRIDES`), leaving only
the belt-fed ingredient the executor actually pushes. The standing item
is never explicitly requested — it's kept available the same
opportunistic way fuel always has been, via `topUpPassiveFeeders`
running after every command, which itself can trigger real production
(`ensureStocked`) if the pool runs short, not just redistribute what
already exists. Watch for this same split — one ingredient pushed
per-request, one ingredient held as a standing supply — wherever a
future machine works the same way a Deployer or furnace does.

**4. Job-types registry** — explicitly skipped as a separate file (per
discussion: optional, derivable from the union of job types appearing in
configs 1/2/3 — no need for a fourth source of truth).

## CLI

Verbs, run either locally at a terminal's own `read()` or forwarded from a
secondary over rednet — same dispatcher either way:

Every verb accepts a trailing `-h`/`--help` and prints its own usage
string instead of running (`lib/Cli.kt`'s `isHelpFlag`/`*_USAGE`
constants) — checked first, before any other argument parsing, so it
short-circuits cleanly even with a malformed rest of the command line.

- `list (--stocked|--craftable|--unavailable) (item-name-filter)` —
  aggregate counts across the storage pool; classify each item as
  stocked (count > 0), craftable (not stocked, but a direct
  `resource-tree.lua` conversion exists whose inputs *are* stocked), or
  unavailable (neither). The optional trailing filter narrows to item
  names containing that substring (e.g. `list --stocked iron`).
- `pull <name> <qty>` — straight withdrawal from the pool into a pickup
  location via `pullItems`, no job logic involved. See "Vaults" above
  for how the target pickup vault is resolved (self, then default).
- `craft <name> <qty> (--location=<name>) (--fetch=false)` — **combined
  craft+pull, chained** (phase 2's planner is live — see "Scope" above):
  pulls whatever's already stocked toward the requested quantity, and for
  the remaining shortfall, recursively ensures each level of the
  resource-tree chain exists — producing a missing input before the
  level that needs it, however many levels deep — then triggers the
  actual job: pushes input materials into the feeder vault, toggles the
  machine on via its Relay, polls the storage pool for the expected
  output count to appear, with a **configurable per-job timeout**
  (different machines have different throughput/delay). Timeout resets
  to zero whenever the output count increases (progress, not stalled).
  One retry after a timeout; if the retry also times out, that level's
  job gives up and everything above it in the chain gives up too (no
  input to work with) — double-feeding a machine on retry is acceptable
  (confirmed), no dedup/interlock needed there. A chain that bottoms out
  at an unstocked, non-convertible item (or hits `MAX_PLANNER_DEPTH`)
  just produces as much as it can, which may be nothing. Fetches (pulls
  the result into a pickup location) by default; pass `--fetch=false` to
  craft without pulling — the result is left in the storage pool
  instead, e.g. for building up stock ahead of time rather than an
  immediate hand-off. **Which pickup vault "fetch" delivers into**
  (`lib/Cli.kt`'s `resolvePickupLocation`): `--location=<name>` targets
  whichever pickup vault has that exact `"name"` label in
  `peripherals.json`; without it, this terminal's own inventory if
  it's itself configured as a pickup location (see `ktoxSelfPeripheralName`
  in "Vaults" above), otherwise whichever pickup vault is marked
  `"default": true`. `pull` uses the same self-then-default resolution
  but has no `--location=` override yet — only `craft` was asked for
  one; extend `pull` the same way if that gap turns out to matter in
  practice.
- `trash <name> <qty>` — permanently destroys items via the trash vault.
  Its own explicit command on purpose; nothing else ever routes here.

**Literal `[`/`]` in a Kotlin string transpiles to invalid Lua** (ktox
emits `\[`/`\]`, not a real Lua escape — confirmed via CraftOS-PC:
`invalid escape sequence near '\['`, the whole file fails to load). Hit
writing the `*_USAGE` strings above; already flagged in AGENTS.md's ktox
quirks list, worth restating here since it bit this exact file. Fixed by
using parens for optional-arg notation instead of brackets.

**Real bug, found during physical build-out testing (2026-09-07): a
non-numeric `<qty>` crashed the whole head loop, not just that one
command.** `pull`/`craft`/`trash` all parsed their quantity argument with
`.toDouble()`, which transpiles to `ktox_toDouble` — `tonumber(s)` then
`error(...)` if that's `nil`. Nothing in the CLI dispatch chain catches
Lua errors (this codebase doesn't use try/catch anywhere — untested
territory for ktox, and not needed once the actual fix is this simple),
so a mistyped quantity propagated all the way up through
`parallel.waitForAny` in `HeadTerminal.kt`'s main loop and killed the whole
program — which is what actually explains "the terminal doesn't give me
the cursor back after a bad command": the program wasn't hung, it had
crashed, dropping to whatever's underneath (the raw CraftOS shell, or a
frozen screen depending on how it's launched). Diagnosed by testing
`runCliCommand` directly against real CraftOS-PC with a battery of bad
inputs (`"asdf"`, `""`, `"craft"`, `"craft <item> notanumber"`) rather
than guessing — only the last one actually threw. Fixed by switching to
`.toDoubleOrNull()` (backed by `ktox_toDoubleOrNull`, which already
existed in the runtime for exactly this) and returning a normal `Usage:
...` string on `null` instead of ever reaching `.toDouble()`'s error
path. Worth grepping for `.toDouble()`/`.toInt()` calls on any other
string that ultimately originates from a human typing at a live prompt
(as opposed to internally-generated, machine-formatted strings) if a
similar hang gets reported elsewhere.

## Generic peripheral-call shim

Built after touching a second concrete peripheral shape (inventory calls),
not generalized from the monitor example alone — `list()`'s nested
table-of-tables return would have broken the monitor's ad-hoc comma-string
packing, confirming that one example wasn't enough to generalize correctly.

Design: one generic Lua dispatcher —

```lua
function ktoxPeripheralCall(peripheralName, methodName, argsPacked)
    local p = peripheral.wrap(peripheralName)
    if p == nil then return "MISSING" end
    local method = p[methodName]
    if method == nil then return "MISSING" end
    local args = {}
    if argsPacked ~= "" then
        for piece in string.gmatch(argsPacked, "[^|]+") do
            local tag = string.sub(piece, 1, 1)
            local value = string.sub(piece, 3)
            if tag == "B" then args[#args + 1] = (value == "true")
            elseif tag == "N" then args[#args + 1] = tonumber(value)
            else args[#args + 1] = value end
        end
    end
    local result = method(table.unpack(args, 1, #args))
    if result == nil then return "null" end
    return textutils.serializeJSON(result)
end
```

This solves the dynamic-handle dispatch problem the monitor work hit
(index by method name string, instead of one bespoke shim per operation).
Arguments are deliberately **not** JSON array syntax: a Kotlin string
literal containing `[` or `]` transpiles to invalid Lua (confirmed live —
`"[\"${side}\"]"` came out as `"\[" .. "\"" ...`, matching the documented
ktox escaping bug in AGENTS.md), so the Kotlin call site can never safely
build `"[...]"` text. Arguments are instead packed as `"<tag>:<value>"`
pairs joined by `"|"` (tag `S`/`B`/`N` for string/boolean/number), which
only ever needs `:`/`|`/word characters in a Kotlin string literal —
already-proven-safe territory. Multi-return isn't handled (no caller here
needs more than one return value — `table.pack` was in an earlier draft
of this design but added complexity for a case that doesn't exist yet).

ktox still has no `Map`/working `MutableList` and no JSON parser on the
Kotlin side, so Kotlin never receives a raw JSON blob to deserialize
itself — instead, small purpose-built Lua helpers sit on top of
`ktoxPeripheralCall` (or bypass it and talk to `peripheral.wrap` directly,
for operations needing real logic over a table's contents, like inventory
aggregation) and do the final narrowing to a scalar/flat-string *in Lua*,
exactly like the existing `ktoxGpsLocate`/`ktoxInspectName` shims. That's
the actual scope of "generic" here: the find-and-call step is unified for
simple single-call operations; anything needing real logic over a
peripheral's returned data still needs its own function, because ktox's
data-modeling gap (no collections) doesn't go away just because dispatch
does.

## Known open items (not blocking phase 1, listed so they aren't lost)

- **Head/secondary rednet + `parallel.waitForAny` is unverified in-game.**
  Implemented (`programs/HeadTerminal.kt`/`SecondaryTerminal.kt`, `common/Rednet.kt`,
  `common/Parallel.kt`) and confirmed to load/compile/run its no-modem
  and no-head-found fallback paths cleanly via CraftOS-PC, but the actual
  multi-computer behavior — role collision detection finding a real
  second head, a secondary's command actually reaching the head and a
  result coming back, `parallel.waitForAny` genuinely multiplexing local
  `read()` against `rednet.receive` — has never been exercised, since
  that needs two real computers with real modems and there's no headless
  emulation for either. **Test this first**, before relying on any
  multi-terminal setup: boot a head, boot a secondary, confirm a command
  round-trips, then boot a second head and confirm it refuses to start.
- **Crafter role is equally unverified, plus two extra unknowns beyond
  the rednet/parallel question above:** the exact `turtle.craft()`
  crafting-grid slot mapping (assumed 1, 2, 3, 5, 6, 7, 9, 10, 11), and
  where the craft result actually lands (assumed `dumpAllForward()`'s
  sweep-every-slot approach catches it regardless). Test with a real
  crafter turtle and a simple known recipe before trusting this for
  anything real.
- **Turtle-as-pickup-vault is unverified in-game, on two independent
  points:** (1) a network `pushItems`/`pullItems` call actually landing
  items in a turtle's own inventory when addressed by peripheral name —
  previously assumed broken and routed around (see "Vaults" above), now
  assumed to work instead, but neither direction has been confirmed
  against real hardware; and (2) `ktoxSelfPeripheralName()`
  (`ktox-cc-shim.lua`) — a head/secondary terminal finding its own
  network peripheral name by asking every `"computer"`/`"turtle"`-type
  peripheral for `getID()` and matching against `os.getComputerID()`,
  relying on CC:Tweaked's documented `"computer"` peripheral
  (https://tweaked.cc/peripheral/computer.html) actually exposing itself
  this way for a machine's OWN wired modem, which has never been
  confirmed either. If either assumption is wrong, the practical effect
  is just that self-preference silently falls through to the configured
  `"default": true` pickup vault instead (`resolvePickupLocation` in
  `lib/Cli.kt` treats `"MISSING"` as "no self location", not an error) —
  not a crash, but worth confirming before relying on "the terminal
  defaults to its own inventory" in practice.
- Storage-vault load balancing (push-to-emptiest, farm→vault preference
  routing) — problem #3b territory, deferred.
- Stockpile Switch integration for fast vault-fullness queries — deferred.
- Recursive planner (phase 2).
- Monitor/touch dashboard UI — deferred behind CLI.
- Config-driven stock-percentage preferences (#3b) and its precedence
  question (shared ingredient with conflicting consumer preferences —
  current lean: the item closer to the top of the tree wins) — deferred
  entire problem, not just the precedence question.
