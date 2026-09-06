# PLAN.md — Vault Terminal + On-Demand Production

Working plan for the item-vault interface (design doc problem #2) and on-demand
production (#3a), arrived at over a long design conversation. Committed to the
repo (rather than kept only in chat) so it survives context compaction during
an unattended implementation run, and so the reasoning behind each decision is
recoverable later. Superseded/updated sections should be edited in place, not
left stale — this is a working doc, not a changelog.

## Scope

**In scope now:** vault terminal (list/pull/craft CLI), single-hop craft
(pull what's stocked + trigger one direct job for the shortfall), head/
secondary terminal roles over rednet, config-driven peripheral/job/resource
mapping.

**Explicitly phase 2 (build only if phase-1 is solid and time remains):**
a recursive planner that chains multiple job levels (e.g. raw log → stripped
log → casing) when a *direct* recipe isn't enough to cover a shortfall.

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

Ping responses carry role directly (`rednet` messages can be whole Lua
tables, not just strings — `{role = "head", ...}` / `{role = "secondary",
...}`), so this needs no separate protocol.

**No retry/self-heal loop for terminals** — they don't move, and a player
will manually reboot one that's stuck. Not worth the complexity.

## Vaults

Three kinds, distinguished by `job.type` in `peripherals.json` (see below):

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

**1. `peripherals.json`** — maps peripheral name → type/job. 100% player-
maintained (this encodes physical facts about a specific world, which the
code must never hardcode). Example shape:

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

**2. `job-types.json`** — what each job type can produce. Semi-hardcoded
but editable (new modpacks/items mean this needs updating over time).
Seeded with a couple of illustrative entries only — NOT an attempt at a
complete Create recipe database, to avoid fabricating game data that turns
out wrong:

```json
{
  "smelter": { "produces": ["minecraft:iron_ingot", "minecraft:copper_ingot"] },
  "mechanical_press_depot": { "produces": ["create:iron_sheet", "create:copper_sheet"] }
}
```

**3. `resource-tree.json`** — per item, what direct conversions exist, WITH
ratios (input:output counts) — required so the executor knows how much raw
material to push for a requested output quantity:

```json
{
  "minecraft:copper_ingot": {
    "convertsTo": [
      {
        "output": "create:copper_sheet",
        "job": "mechanical_press_depot",
        "inputCount": 1,
        "outputCount": 1
      }
    ]
  }
}
```

Note: `job` here is a plain job-type-name string (a leaf reference), unlike
`peripherals.json`'s recursive `{"type": ..., "job": ...}` descriptor —
this file only ever needs to *name* which job type performs a conversion,
never to describe physical routing/nesting.

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
- `craft <name> <qty>` — **combined craft+pull, single-hop only** (this is
  "the first planner pass" per discussion, not the real phase-2 planner):
  pull whatever's already stocked toward the requested quantity, and for
  the remaining shortfall, if a *direct* recipe exists (one level, not a
  chain), trigger it — push the input materials into the feeder vault,
  toggle the machine on via its Relay, poll the storage pool for the
  expected output count to appear, with a **configurable per-job timeout**
  (different machines have different throughput/delay). Timeout resets to
  zero whenever the output count increases (progress, not stalled). One
  retry after a timeout; if the retry also times out, fail the job and any
  jobs that depended on it, and move on to the next queued request or go
  back to waiting for input. Double-feeding a machine on retry is
  acceptable (confirmed) — no dedup/interlock needed there.

Multi-hop requests (need sheets, only raw ore exists, no direct
ore→sheet recipe) are exactly what phase 2's planner is for; phase 1's
`craft` should simply report "not directly craftable" for those rather
than attempting to chain jobs itself.

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

- Storage-vault load balancing (push-to-emptiest, farm→vault preference
  routing) — problem #3b territory, deferred.
- Stockpile Switch integration for fast vault-fullness queries — deferred.
- Recursive planner (phase 2).
- Monitor/touch dashboard UI — deferred behind CLI.
- Config-driven stock-percentage preferences (#3b) and its precedence
  question (shared ingredient with conflicting consumer preferences —
  current lean: the item closer to the top of the tree wins) — deferred
  entire problem, not just the precedence question.
