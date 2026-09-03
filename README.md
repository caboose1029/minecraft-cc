# minecraft-cc

Lua for our Minecraft server's [CC: Tweaked](https://tweaked.cc) computers, plus
**moonman** — the package manager that gets it onto them, so nobody has to
`wget` files one at a time.

## Bootstrap a computer

One command on a fresh computer:

```
wget run https://raw.githubusercontent.com/caboose1029/minecraft-cc/main/bootstrap.lua
```

To track a dev branch instead of `main`, pass the ref:

```
wget run https://raw.githubusercontent.com/caboose1029/minecraft-cc/main/bootstrap.lua feat/my-branch
```

The ref is saved to `/.moonman/config.json`, so every later command follows the
same branch. Switch at any time with `moonman use <ref>`.

## Using moonman

```
moonman list --available          see what you can install
moonman install caboose/test      install a package
moonman info caboose/multi_test   files, dependencies, install layout
moonman update                    refresh everything from the current ref
moonman remove caboose/test       delete exactly what was installed
moonman use feat/my-branch        switch branch, tag, or commit
moonman self-update               pull a newer moonman
moonman sync share/test           raw file copy, structure preserved
moonman help <command>            details for any command
```

`install` resolves a bare leaf name when it is unambiguous, so `moonman install
multi_test` finds `caboose/multi_test`.

## How require() works here

This is the part worth understanding, because it drives the whole layout.

CC resolves `require("a.b.c")` against **the directory of the running program**
(`shell.lua` passes `fs.getDir(path)` into `cc.require`). It does not have a
project root or a search path you can rely on. So moonman makes the program's
directory the unit of resolution:

| repo                                  | device                                 |
| ------------------------------------- | -------------------------------------- |
| `src/player/caboose/multi_test/main.lua` | `/multi_test/main.lua`                 |
| `src/player/caboose/multi_test/test2.lua` | `/multi_test/test2.lua`               |
| `src/share/test/sharetest.lua`        | `/multi_test/share/test/sharetest.lua` |
|                                       | `/multi_test.lua` (generated launcher)  |

Shared code is **vendored into each package that declares it**, at the path its
module name implies. The result is that one string works everywhere:

```lua
local sharetest = require("share.test.sharetest")  -- vendored dependency
local test2 = require("test2")                     -- sibling in this package
```

On-device that resolves through the package directory. In the repo, LuaLS finds
it through `runtime.path` (`src/?.lua`) in `.luarc.json`. No build step, no
path shims, no separate dev and prod spellings.

The launcher stub at `/<name>.lua` exists so `multi_test` still runs from the
shell; it `shell.run`s the real entry point, which re-roots require() at the
package directory.

A package with a single file and no dependencies skips all of this and installs
flat as `/<name>.lua`.

moonman installs itself the same way: `/moonman.lua` is the entry point, so its
directory is `/` and `require("moonman.cli")` finds `/moonman/cli/init.lua`.
That is why the repo has `moonman/main.lua` next to `moonman/<module>.lua` —
the require strings are identical on both sides.

## Repository layout

```
bootstrap.lua              the single file a fresh computer fetches
dist/manifest.json         generated; the index moonman reads
moonman/                   the package manager
  main.lua                 entry point -> /moonman.lua
  domain/                  pure logic: paths, manifest model, install plans
  app/                     use cases: install, remove, update, sync, config
  platform/                the only code that touches CC APIs
  cli/                     argument parsing and the command registry
src/
  share/<ns>/<mod>.lua     shared modules, required as "share.<ns>.<mod>"
  pkg/<name>/              shared packages
  player/<player>/         personal programs, packaged as "<player>/<name>"
tools/                     manifest generator and test suites
types/                     LuaLS definitions for the CC API
```

### moonman's layers

Dependencies point inward: `cli` → `app` → `domain`, with `platform` plugged in
at the edge.

- **domain** is pure. No `fs`, no `http`, no globals. An install is planned as
  inert data before anything is written, which is what makes `--dry-run` free
  and the logic testable off-device.
- **platform** wraps the CC APIs behind small ports (`fs`, `http`, `log`,
  `json`). `app/context.lua` is the composition root that wires them together.
- **cli** parses arguments and dispatches. Command modules load lazily, so
  startup reads one file no matter how many commands exist.

Adding a command: drop a module in `moonman/cli/commands/` exposing `summary`,
`usage`, and `run(ctx, argv)`, then add one line to `REGISTRY` in
`moonman/cli/init.lua`.

## Adding code

Put the file where its kind belongs and the generator does the rest:

- `src/share/<ns>/<mod>.lua` — a shared module. Return a table; don't define
  globals.
- `src/pkg/<name>/` — a package. Entry point is `main.lua` (or `<name>.lua`).
- `src/player/<you>/<name>.lua` — a personal single-file program.
- `src/player/<you>/<name>/` — a personal multi-file program.

**Dependencies are not declared by hand.** `tools/gen_manifest.py` scans
`require()` calls and records any that name a real module under `src/`, then
moonman resolves them transitively at install time. Requires it cannot resolve
(siblings, `cc.expect`) are left alone; a `require("share.…")` that names
nothing real is reported as a warning.

Drop a `moonman.json` in a package directory to override the entry point, add a
description, or force extra dependencies.

## Development

```
mise run manifest         regenerate dist/manifest.json
mise run test:moonman     off-device test suite (fake ports, no emulator)
mise run verify           boot CraftOS-PC and confirm require() resolves
mise run check            all of the above, as CI runs it
mise run test <file>      run one repo file headless in CraftOS-PC
```

`mise run test:moonman` drives the real `app` and `domain` code through an
in-memory filesystem and an HTTP port backed by the working tree — the payoff
of keeping CC out of everything but `platform/`.

`mise run verify` covers what it cannot: it lays out a package the way moonman
would, boots a real computer, and checks that both the vendored and sibling
requires resolve.

### The manifest

`dist/manifest.json` is generated, never hand-edited. The
[`manifest` workflow](.github/workflows/manifest.yml) regenerates and commits it
on push to **any** branch, so dev branches stay bootstrappable. Run
`mise run manifest` locally when you want to test before pushing.

URLs are composed at runtime from moonman's configured repo and ref rather than
baked into the manifest, so the same manifest works from whatever branch you
fetched it.
