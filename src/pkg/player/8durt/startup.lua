-- Hand-written, not ktox-generated. Runs at computer boot, before any
-- program.
--
-- v1 of the roadmap's "startup script" item — GitHub-hosted script syncing
-- comes later; see AGENTS.md.
--
-- WORKAROUND for a real ktox-lua plugin bug (confirmed by reading
-- CraftOS-PC's actual bios.lua/rom/programs/shell.lua source, not
-- guessed) that otherwise reproduces on every real turtle/computer as:
-- "attempt to call global 'ktox_sourcemap_traceback' (a nil value)" (or
-- any other ktox-lib.lua function, or any lib/*.lua function) — on
-- every program run EXCEPT the first one after a reboot.
--
-- Root cause: every program the shell launches (shell.lua's
-- executeProgram) gets its OWN fresh, private environment table (its own
-- `require`/`package.loaded` included — see cc/require.lua's
-- make_package, called fresh per program). Plain `function foo() ... end`
-- definitions in a required file land in THAT table, not in the true
-- shared `_G` — global reads still fall through to `_G` (via each env's
-- `__index = _G` metatable), but writes don't propagate back up. So the
-- FIRST program in a boot session to `require("ktox-lib")` defines
-- ktox_sourcemap_traceback/println/ktox_require/etc. only in ITS OWN
-- env (works fine for that one program) — and ktox-lib.lua's own
-- top-of-file module guard (`if _G.ktox_lib_loaded then return end`)
-- is keyed on the ONE true `_G`, so it now looks "already loaded"
-- forever, for every other program, even though none of those
-- functions exist anywhere THOSE programs can see. Same failure mode
-- for lib/*.lua files, one layer down: ktox_require's own dedup cache
-- (`_ktox_required`) is a single closure upvalue shared for the whole
-- session (once ktox_require itself is real-global, per this fix),
-- so only the first program to `ktox_require("lib/X")` actually runs
-- lib/X.lua's body; every later program's own call to it just no-ops.
-- A reboot clears the real `_G`, which is why exactly one program run
-- works right after — then the next one poisons it again.
--
-- Fix: `dofile()` (unlike a normal program run, or unlike this very
-- startup.lua's own execution — it too runs through shell.lua's
-- sandboxed executeProgram, per rom/startup.lua's `shell.run(v)`) is
-- special-cased in bios.lua to always load+run its target directly
-- against the TRUE `_G`, regardless of the calling code's own
-- environment (`loadfile(_sFile, nil, _G)`). So `dofile`-ing every
-- runtime dependency here, once, makes their definitions real,
-- permanent globals — visible via inheritance to every program for
-- the rest of the session, no working `require()`/`ktox_require()`
-- needed by any of them ever again.
--
-- The one wrinkle: `_G` (unlike a normal program's env) has no
-- `require` global at all (shell.lua's own comment: "require... is
-- part of the shell, and so is not [available in bios]"), and every
-- lib/*.lua file's own top line is `require("ktox-lib")` (Shape.lua
-- additionally has a top-level `ktox_require("lib/Span")`) — run with
-- env=`_G` via dofile, that would crash immediately on a nil call.
-- The stub below makes it a harmless no-op instead: safe because
-- every actual dependency is dofile'd explicitly below regardless of
-- what these top-level calls do, and it can't affect any real
-- program's own `require()` later, since each program's env always
-- defines its own fresh `require` (shadowing this one, never falling
-- through to it).
--
-- Order of the dofile calls below doesn't matter: none of these files
-- resolve their cross-file references (e.g. Shape.lua's use of
-- Span.lua's IntSpan) until a function body actually RUNS, which only
-- happens later, once every dofile here has already completed.
--
-- New lib/*.lua file added? Add its dofile call here too (same
-- proactive-update requirement as GhFetch.kt's files list — see
-- AGENTS.md).
--
-- ktox-lib.lua's own module guard (`if _G.ktox_lib_loaded then return
-- end`) is itself an instance of this exact bug, and can bite even this
-- fix: if ANYTHING already required "ktox-lib" earlier in the session
-- (e.g. something running before this startup.lua gets a chance to —
-- confirmed happening inside scripts/validate.sh's own harness, where
-- the --script payload's own require("ktox-lib") runs first and flips
-- this flag on the real `_G` before this file gets to dofile it), the
-- guard sees "already loaded" and skips redefining anything into real
-- `_G` here too - silently defeating this whole fix. Force it back to
-- unloaded immediately before dofile-ing it ourselves, so our load
-- always actually happens regardless of what ran earlier - safe, since
-- re-running ktox-lib.lua's body just redefines the same functions
-- again (no other side effects).
_G.ktox_lib_loaded = nil
_G.require = function() end

-- Wrapped in pcall, not a bare dofile: a turtle whose files predate a
-- newly-added dependency (e.g. this list itself just grew, but the
-- turtle hasn't re-run ghfetch yet) would otherwise hard-error out of
-- this whole chunk on the FIRST missing file — silently skipping every
-- dofile after it too, including ktox-cc-shim.lua at the end, which has
-- nothing to do with whatever was actually missing. Reported live: a
-- reboot failing on a missing lib/Shape.lua (added the same time as this
-- fix) because ghfetch hadn't been re-run since. Print a clear pointer
-- to ghfetch and keep going instead, so everything else still loads.
local function tryDofile(path)
    local ok, err = pcall(dofile, path)
    if not ok then
        print("startup.lua: couldn't load " .. path .. " (" .. tostring(err) .. ")")
        print("  -> run ghfetch to sync missing/updated files, then reboot.")
    end
end

tryDofile("ktox-lib.lua")
tryDofile("lib/Span.lua")
tryDofile("lib/Position.lua")
tryDofile("lib/Movement.lua")
tryDofile("lib/Chest.lua")
tryDofile("lib/Shape.lua")
tryDofile("ktox-cc-shim.lua")
