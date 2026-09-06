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
  a **physical `turtle.drop()`**, not a network push, since turtle-as-
  peripheral-target is the same unresolved capability flagged for the
  pickup vault (see "Vaults" below). The head never needs an explicit
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
  land for a player to grab, exactly one per terminal. This exists
  because a turtle targeting **its own inventory** as a named
  `pushItems`/`pullItems` peripheral isn't reliably supported by
  CC:Tweaked (an open upstream request, not a shipped feature) — so
  rather than assume it works, results are pushed to an ordinary vault
  peripheral next to the terminal instead. Revisit if/when turtle-as-
  inventory-peripheral is confirmed to work.
- **Trash vault** (`job.type: "trash"`) — dumps whatever's pushed into it
  into lava, permanently. Functionally identical wiring to a feeder
  vault (a vault + funnel), but semantically very different: it's never
  a target for anything automatic (no resource-tree.json entry, nothing
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
  remote command (see "Terminal roles" → Head.kt, and
  `lib/PassiveFeeder.kt`) rather than on an independent timer. A head
  sitting fully idle won't top these up until its next command — an
  accepted, disclosed limitation (a real timer risks starving itself:
  see the code comment for why). This is a narrower, much more
  tractable version of the #3b factory-balancing idea floated earlier
  and deferred entirely — "maintain N of item X" needs none of the
  cross-item-precedence logic that made #3b hard.

Stockpile Switch is a good fit for storage-vault fullness (aggregate fill
%, doesn't care about item identity) but **not** for per-item shortage
detection on a mixed vault — that still requires software-side counting
via `list()`/`getItemDetail`. Not wired up in phase 1; noted for later.

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

## Configs (JSON — confirmed native via `textutils.serializeJSON`/
`unserializeJSON`; no XML support exists in CC:Tweaked at all)

**Ownership split, revised:** only `peripherals.json` is 100% player-owned
— it encodes physical facts about one specific world (which peripheral
sits where), which the code must never hardcode and `ghfetch` must never
overwrite; the player maintains it starting from the shipped
`peripherals.example.json` template. `job-types.json` and
`resource-tree.json` describe the *game's* recipe graph — the same
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

**2. `job-types.json`** — what each job type can produce, its execution
`kind` (`"machine"` — redstone relay + feeder vault; `"crafter"` — a
crafty turtle running `turtle.craft()`; defaults to `"machine"` when
omitted, so every job type from before crafty turtles existed still
works unchanged), and an optional per-job `timeoutSeconds` override.
Semi-hardcoded but editable (new modpacks/items mean this needs updating
over time). Seeded with a couple of illustrative entries only — NOT an
attempt at a complete Create recipe database, to avoid fabricating game
data that turns out wrong:

```json
{
  "smelter": { "produces": ["minecraft:iron_ingot", "minecraft:copper_ingot"], "kind": "machine" },
  "mechanical_press_depot": { "produces": ["create:iron_sheet", "create:copper_sheet"], "kind": "machine" },
  "mixer_basin": { "produces": ["create:brass_ingot"], "kind": "machine", "timeoutSeconds": 45 }
}
```

**3. `resource-tree.json`** — a **flat list of recipes**, not keyed by a
single input (see below for why), each with ratios (input:output counts)
so the executor knows how much raw material to push for a requested
output quantity, and a list of inputs so multi-ingredient recipes (brass:
copper + zinc) and shaped crafter recipes (an ingredient pinned to a
specific turtle crafting-grid slot) both fit the same shape:

```json
{
  "recipes": [
    {
      "output": "create:copper_sheet",
      "outputCount": 1,
      "job": "mechanical_press_depot",
      "inputs": [
        { "item": "minecraft:copper_ingot", "count": 1 }
      ]
    },
    {
      "output": "create:brass_ingot",
      "outputCount": 1,
      "job": "mixer_basin",
      "inputs": [
        { "item": "minecraft:copper_ingot", "count": 1 },
        { "item": "minecraft:zinc_ingot", "count": 1 }
      ]
    }
  ]
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

**4. Job-types registry** — explicitly skipped as a separate file (per
discussion: optional, derivable from the union of job types appearing in
configs 1/2/3 — no need for a fourth source of truth).

## CLI

Verbs, run either locally at a terminal's own `read()` or forwarded from a
secondary over rednet — same dispatcher either way:

- `list [--stocked|--craftable|--unavailable] [substring]` — aggregate
  counts across the storage pool; classify each item as stocked (count >
  0), craftable (not stocked, but a direct `resource-tree.json` conversion
  exists whose inputs *are* stocked), or unavailable (neither).
- `pull <name> <qty>` — straight withdrawal from the pool into the
  pickup vault via `pullItems`, no job logic involved.
- `craft <name> <qty>` — **combined craft+pull, chained** (phase 2's
  planner is live — see "Scope" above): pulls whatever's already stocked
  toward the requested quantity, and for the remaining shortfall,
  recursively ensures each level of the resource-tree chain exists —
  producing a missing input before the level that needs it, however many
  levels deep — then triggers the actual job: pushes input materials
  into the feeder vault, toggles the machine on via its Relay, polls the
  storage pool for the expected output count to appear, with a
  **configurable per-job timeout** (different machines have different
  throughput/delay). Timeout resets to zero whenever the output count
  increases (progress, not stalled). One retry after a timeout; if the
  retry also times out, that level's job gives up and everything above
  it in the chain gives up too (no input to work with) — double-feeding
  a machine on retry is acceptable (confirmed), no dedup/interlock needed
  there. A chain that bottoms out at an unstocked, non-convertible item
  (or hits `MAX_PLANNER_DEPTH`) just produces as much as it can, which
  may be nothing.
- `trash <name> <qty>` — permanently destroys items via the trash vault.
  Its own explicit command on purpose; nothing else ever routes here.

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
  Implemented (`programs/Head.kt`/`Secondary.kt`, `common/Rednet.kt`,
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
- Storage-vault load balancing (push-to-emptiest, farm→vault preference
  routing) — problem #3b territory, deferred.
- Stockpile Switch integration for fast vault-fullness queries — deferred.
- Recursive planner (phase 2).
- Monitor/touch dashboard UI — deferred behind CLI.
- Config-driven stock-percentage preferences (#3b) and its precedence
  question (shared ingredient with conflicting consumer preferences —
  current lean: the item closer to the top of the tree wins) — deferred
  entire problem, not just the precedence question.
