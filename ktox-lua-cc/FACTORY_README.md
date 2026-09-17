# Factory / Vault Terminal — Setup Guide

> **⚠ Unpolished, under development.** This is a much bigger system than the
> standalone tools in `README.md` — it needs real setup work (a wired
> network, hand-written config describing your own base), and large parts
> of it have never been exercised against a real multi-computer session.
> Expect rough edges. If something behaves strangely, `PLAN.md` has the
> full design history, every known bug, and an exhaustive "unverified in
> real gameplay" list — check there before assuming it's just you.

This is a shared item-storage and on-demand-crafting system: one or more
terminals let you type (or tap) commands like "give me 5 iron ingots" or
"craft a chest," and the system pulls from storage and/or runs the Create
machines/crafter turtles needed to make it happen, without you having to
manually operate anything.

## The moving parts

- **One Head terminal** — the only decision-maker. It owns all the state
  (what's in storage, what's running) and does all the real work. Exactly
  one is allowed on the network; a second one will refuse to start.
- **Any number of Secondary terminals** — thin remote clients. Typing a
  command at one just forwards it to the Head over `rednet` and prints
  back whatever the Head replies. A secondary never decides anything
  itself.
- **Crafter turtles** — one per job type that needs an actual crafting
  grid (`turtle.craft()`), e.g. anything that isn't a Create machine. Each
  one just listens for the Head to tell it what to craft and how many.
- **A touch dashboard** — an on-screen alternative to typing commands,
  available on any terminal's own screen (not a wall-mounted monitor).
  Browse what's stocked/craftable, tap an item, adjust quantity, tap
  Fetch or Craft.

All of this talks over a **wired** modem network — the same cable that
already needs to reach every vault also carries the Head/Secondary/crafter
traffic and the redstone control signals, so there's no separate wireless
setup needed for a single build.

## Setting up from scratch

1. **Wire up your base**: every storage vault, feeder vault, pickup
   location, crafter turtle, and redstone relay needs to be on the same
   wired network as whichever computer will be the Head.
2. **Run `GhFetch` on every machine** (see `README.md`'s getting-started
   section) — this pulls the actual programs.
3. **Write `config/peripherals.json`** describing your own base: which
   peripheral name is which vault, which job type each feeder feeds, which
   relay controls what, which vault is the pickup/trash/deposit spot, etc.
   Copy `config/peripherals.example.json` as a starting point. This file
   is **yours** — `GhFetch` never overwrites it. (`config/job-types.lua`
   and `config/resource-tree.lua`, by contrast, describe the game's own
   recipes and get refreshed by every `GhFetch` run — you don't maintain
   those.)
4. **Run `TerminalSetup` on each machine** to tell it what it is:
   - `TerminalSetup head` — the one decision-maker. Refuses to run if
     another head already answers on the network.
   - `TerminalSetup secondary` — a remote client.
   - `TerminalSetup crafter <jobType>` — a crafting turtle dedicated to
     one job type from `config/job-types.lua`.
5. **Reboot each machine** — this writes a `role.txt` that gets picked up
   automatically on every future boot, so you don't need to manually start
   anything again after this.

## Using it

Whether typed at the Head directly or forwarded from a Secondary, the same
commands work everywhere:

- `list (--stocked|--craftable|--unavailable) (filter)` — see what's in
  the storage pool, what could be crafted from what's on hand, or search
  by name.
- `pull <item> <qty> (--location=<name>)` — withdraw straight from
  storage, no crafting involved.
- `craft <item> <qty> (--location=<name>) (--fetch=false)` — craft
  (chaining through as many intermediate steps as needed) and deliver the
  result. `--fetch=false` leaves it in storage instead of handing it to
  you.
- `trash <item> <qty>` — permanently destroys items (dumped into lava) —
  its own explicit command since this is irreversible.
- `deposit` — for a turtle-based terminal only: sweeps whatever's
  currently sitting in the turtle's own inventory back into storage.

Add `-h` to any command to print its own usage instead of running it.
The dashboard (if your terminal has a screen — most turtles/computers do)
is a tap-driven alternative to all of the above; it produces the exact
same commands under the hood.

## What to actually expect right now

This system compiles cleanly and its pure logic (the dashboard's
state machine, the CLI parsing, the recipe/planner chaining) has been
exercised through an offline test harness — but the parts that need two or
more real computers talking to each other over real hardware have not been
watched happen in a real world. In particular, before trusting this for
anything you care about:

- **Test the basic multi-terminal round trip first**: boot a Head, boot a
  Secondary, confirm a command typed at the Secondary actually reaches the
  Head and a result comes back. Then boot a second Head and confirm it
  correctly refuses to start.
- **Test one crafter turtle on one simple recipe** before relying on it
  for anything real — the exact crafting-grid slot layout and where the
  finished item ends up are both best-effort assumptions, not confirmed
  behavior.
- **Any turtle acting as a pickup/deposit/crafting location needs a real
  chest directly above and/or below it**, per the `job.aboveChest`/
  `job.belowChest` config — whether `turtle.suckUp()`/`turtle.dropDown()`
  actually reach chests placed there the way this assumes hasn't been
  confirmed against a real world either.
- The same "double chest confuses it" and "a missing chest can eat your
  items" warnings from `README.md`'s "Buyer beware" section apply here too,
  anywhere this system interacts with a physical chest — and its "a
  turtle dying/logging off/chunk unloading stops a program cold, with no
  clean resume" warning applies doubly hard here: a crafter turtle or a
  Head terminal is meant to sit there running indefinitely, so a silent
  mid-job interruption is easier to miss than with a one-shot tool you're
  actively watching.

`PLAN.md`'s "Known open items" section has the complete, current list of
what's built vs. what's still just a documented assumption — read it
before you invest a lot of build time around this system.
