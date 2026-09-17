# Turtle Programs — User Guide

This is a plain-language guide to the standalone turtle/computer programs in
this pack — how to get them onto a machine, and how to run each one safely.
It's written for playing the game, not for reading the code. If you want the
technical design (how the code works, what's been tested, known bugs), see
`AGENTS.md` and `PLAN.md` instead.

The shared item-vault/crafting system (Head/Secondary terminals, crafter
turtles, the touch dashboard) is a separate, much more involved setup — see
`FACTORY_README.md` for that. This guide is just the tools you can pick up
and run on their own.

## Getting started: installing/updating with GhFetch

Every program in this pack lives on GitHub. `GhFetch` is the one tool that
pulls everything else onto a turtle or computer — you need it on a machine
before anything else here will work.

**First time on a fresh turtle/computer:**

```
wget https://raw.githubusercontent.com/caboose1029/minecraft-cc/feat/add-ktox-lua-cc/src/pkg/player/8durt/GhFetch.lua GhFetch.lua
GhFetch
reboot
```

That's it — one `wget`, one run, one reboot. `GhFetch` fetches everything it
needs (including its own updates) in that single run; you don't need to
fetch anything else by hand first.

**To update a machine later** (new features, bug fixes), just run:

```
GhFetch
reboot
```

again. It re-downloads everything fresh, so it's always safe to re-run.
The reboot afterward matters — some updates add new library files that only
get loaded into memory at boot.

When it runs, `GhFetch` prints the actual latest commit on the branch it's
pulling from (short hash, message, date) before it fetches anything — that's
worth glancing at to confirm you actually got the update you expected, not a
stale cached page.

**Working off a different branch:** pass it as an argument, e.g.
`GhFetch feat/some-experiment`. Without an argument it uses the pack's
current default branch (shown above).

**If it fails to fetch anything:** it needs the server's CC:Tweaked HTTP
access to actually be enabled (this is normal on most servers, but if it's
locked down you'll need to ask whoever runs the server). It also just talks
to GitHub directly, so it needs the branch to actually exist there.

Once `GhFetch` has run and the machine has rebooted, every program below can
be run directly by name at the shell, e.g. just type `Digsite` or `Wall` and
press enter.

## Digsite, Wall, ExcavatePro, DiamondFinder

These four are all standalone tools — no other computers, no config files,
no network setup. Point one at a turtle, run it, done. A few things they all
have in common:

- **Fuel:** the turtle needs fuel in it, or (for Digsite/ExcavatePro/
  DiamondFinder) a fuel chest set up as described below. Wall has no chest
  support at all — just make sure the turtle already has fuel before running
  it.
- **GPS is optional, but recommended.** Without a GPS network in range,
  these programs fall back to tracking position by counting their own
  moves, which works fine as long as nothing interrupts them mid-run.
  DiamondFinder is the exception — see its own section below.
- **They dig through obstructions automatically.** See "Buyer beware"
  at the bottom before running any of these somewhere you care about.

### Digsite — excavate a shape

```
digsite <width> (<length>) (<height>)      rectangle
digsite -t <side> (<height>)               isoceles triangle
digsite -rt <side> (<height>)              right triangle
digsite -c <radius> (<height>)             circle
digsite -h                                 show help in-game
```

Stand the turtle where you want one corner (or the shape's reference point,
see below) of the excavation, facing the direction you want it to dig into.

- **Rectangle:** `width` extends along the turtle's right-hand side,
  `length` extends forward. Leave `length` off for a square.
- **Triangle (`-t`):** the turtle stands at the middle of the base, apex
  pointing straight ahead.
- **Right triangle (`-rt`):** the turtle stands at the right-angle corner.
- **Circle (`-c`):** the turtle stands on the edge, with the circle
  extending forward from there.
- **Height:** leave it off entirely for "clear-cut" mode — the turtle's own
  starting height becomes the floor, and it sweeps upward layer by layer
  until an entire layer digs nothing (good for clearing a surface area of
  unknown height). Give a height (positive = up, negative = down) for
  "room" mode — an exact, bounded box instead.

**Chest setup:** place a single chest directly **behind** the turtle's
starting position (the block it'll be facing once it turns around to go
home). This is the fuel supply — it should hold **only** fuel: charcoal,
coal, coal blocks, dried kelp blocks, or lava buckets. If you want the
turtle to be able to dump more material than fits in its own inventory,
extend a row of single chests from there toward the turtle's **original
right-hand side** — one chest per "slot" the turtle might need. Nothing
else needs to be pre-loaded; Digsite dumps whatever it digs into that row
automatically.

### Wall — build a simple wall

```
wall <length> <height>
```

No chest, no config — put the wall's material in **slot 1** of the
turtle's own inventory before running it, then just run `wall <length>
<height>`. Only that exact item is ever placed, even if other slots hold
different blocks (safe if the turtle's also carrying mined loot) — if it
runs out of that material partway through, it stops and tells you how many
blocks it managed to place.

**It does not return to its starting position when it's done or when it
stops early** — it just stops wherever it happens to be, whether that's
because the wall finished or because it ran out of material or got
blocked partway through. Expect to have to walk over and collect it.

The turtle builds by walking the wall's own footprint and placing blocks
straight down as it goes, climbing one level after each full pass — so it
needs clear air above it for the full `height`, and the strip of ground
along `length` shouldn't be blocked (though the turtle will dig through a
blockage if it has to — see "Buyer beware").

### ExcavatePro — a proper mineshaft with stairs

```
excavatepro <width> (<length>) (<depth>)
```

Same starting orientation as Digsite's rectangle mode (`width` to the
right, `length` forward), but this one digs **straight down** instead of
sideways, lining the shaft with a self-built cobblestone staircase and
torches as it descends. Leave `depth` off to dig until it hits bedrock;
give it a number to stop after that many levels.

**Chest setup:** same fuel chest directly behind the start position, same
overflow row to the turtle's original right — but this time the fuel
chest should hold **fuel and torches together** (charcoal etc. mixed with
`minecraft:torch`). The turtle sorts them out itself: fuel gets burned,
torches get set aside for lighting the stairs as it goes. You do **not**
need to supply cobblestone for the steps — it mines its own as it digs
through stone. If the ground here is mostly dirt/sand rather than stone,
it may run short on step material.

### DiamondFinder — branch-mine for ore

```
diamondfinder <branchLength> <branchCount> (<spacing>)
```

Bores a set of parallel branch-mine tunnels at the two Y-levels most likely
to hit diamonds in current world generation, and will detour to fully
clear out any valuable ore vein (diamond, redstone, gold, iron, copper,
zinc, lapis, emerald) it runs into along the way before continuing.

**GPS strongly recommended here**, more than the others: this program
targets fixed real-world depths, not a depth relative to wherever it
started. If it can't get a GPS fix, it'll stop and ask you to type in the
turtle's current Y coordinate directly before it'll continue — if you
don't know that, don't run it without GPS.

**Chest setup:** same fuel chest directly behind the start position and
overflow row to the right as Digsite — but this one expects **fuel only**,
no torches or anything else mixed in.

## Buyer beware — read this before you run any of these unattended

- **A turtle dying, you logging off, or the game unloading its chunk will
  stop a program dead, mid-action, with no way to resume cleanly.** None
  of these programs save any progress — if the turtle stops moving for
  any of those reasons partway through a dig, a wall, or a mining run,
  the next time it starts up you're just running the command fresh
  again from wherever it physically ended up, not picking up where it
  left off. This matters most for anything long-running (a deep
  ExcavatePro shaft, a long DiamondFinder session) — don't assume it's
  still working just because you haven't checked on it in a while, and
  don't count on it noticing and recovering from an interruption like
  that on its own.
- **A double chest where a single chest is expected will confuse the
  program.** The fuel/supply chest and the first overflow chest are two
  *separate* single-block positions as far as the code is concerned. If
  you place a double chest that spans both of those spots (i.e. you extend
  the supply chest one block to the right, into where the first overflow
  chest should go), both halves become one merged inventory in-game. The
  turtle will then try to pull "fuel" from a chest that also has your
  overflow junk sitting in it — and it stops restocking the moment it
  hits the first item it doesn't recognize as fuel, rather than skipping
  past it. **Keep every chest in the row a single block.**
- **A missing chest doesn't fail loudly — it can eat your items.** If an
  overflow chest isn't actually placed where the turtle expects it, and it
  tries to dump cargo there, CC:Tweaked lets a turtle "drop" an item into
  empty air — the item is just thrown onto the ground as a normal dropped
  entity, and the game reports that as a **successful** drop. The turtle
  has no way to tell "landed safely in a chest" apart from "got thrown on
  the floor and may despawn." If you're not sure how much overflow storage
  a big job will need, build out more chests than you think you need
  first, rather than finding out the hard way.
- **These programs dig through obstructions automatically**, and don't
  distinguish terrain from anything you built. Forward/up/down movement
  will mine through whatever's blocking it rather than stopping — and the
  recovery logic used when a program gets properly stuck (e.g. a bedrock
  pocket) can send the turtle climbing straight up looking for a way out,
  potentially surfacing somewhere you didn't expect. Don't point one of
  these at, or run one near, anything you don't want dug through.
- **None of this has been tested against a real live server/turtle this
  session** — everything above has been checked for correctness by
  building it and running it through an offline emulator, not by actually
  watching a turtle do it in a real world. Keep an eye on the first run of
  anything new.
