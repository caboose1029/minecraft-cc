-- Hand-written, not ktox-generated (see AGENTS.md's "hand-written Lua"
-- list). Deliberately pure, dependency-free Lua - no require("ktox-lib"),
-- no call through ktox-cc-shim.lua - so a fresh turtle/computer can
-- bootstrap with ONE wget (this file) and ONE run, instead of needing
-- ktox-lib.lua/ktox-cc-shim.lua/startup.lua already present (and a
-- reboot to actually load them into real _G - see AGENTS.md's
-- ktox_sourcemap_traceback writeup) before it could even start. This
-- file talks to CC:Tweaked's native http/fs APIs directly.
--
-- Setup, start to finish:
--   wget https://raw.githubusercontent.com/caboose1029/minecraft-cc/<branch>/src/pkg/player/8durt/GhFetch.lua GhFetch.lua
--   GhFetch
--   reboot
-- One GhFetch run pulls everything listed in files.manifest in a single
-- pass - including ktox-lib.lua/ktox-cc-shim.lua/startup.lua themselves
-- and this very file's own up-to-date copy - so there's never a need to
-- run it twice just to "unlock" the rest of the sync.
--
-- Usage: ghfetch [branch]
--   - branch (optional): git ref to fetch from, e.g. a feature branch
--     you're iterating on. Defaults to DEFAULT_BRANCH when omitted.
--
-- DEFAULT_BRANCH tracks whichever branch is under active iteration -
-- currently feat/add-ktox-lua-cc. main doesn't have
-- src/pkg/player/8durt yet, so this can't point there - move it to
-- "main" (matching moonman's manifest convention) once that merges.
--
-- The actual file list lives in FILES_MANIFEST (fetched, not hardcoded
-- here) - see PLAN.md's "GhFetch's file manifest" for how to maintain
-- it. This file only knows the ONE thing that can't itself come from
-- the manifest: where to find it - the unavoidable bootstrap problem,
-- something has to be the fixed starting point.

local args = { ... }

local DEFAULT_BRANCH = "feat/add-ktox-lua-cc"
local FILES_MANIFEST = "files.manifest"

local branch = args[1] or DEFAULT_BRANCH
local repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/" .. branch .. "/src/pkg/player/8durt"
print("Fetching from branch: " .. branch)

-- Best-effort "did this actually pull the latest commit" check, via
-- GitHub's own commit API rather than a build-time version stamp (no
-- post-commit hook needed, so it can never go stale relative to what
-- was actually pushed). A separate network call from the raw-file
-- fetches below - a small window where the two could disagree if
-- someone pushes mid-run, acceptable for a personal server, not a
-- strong guarantee. GitHub's API requires a real User-Agent header on
-- every request or it 403s; raw.githubusercontent.com has no such
-- requirement, which is why downloadFile/downloadText below don't send
-- one. Never fatal - a broken/blocked API call just skips the version
-- line and the real fetch continues.
local function reportLatestCommit(branchName)
    local response = http.get(
        "https://api.github.com/repos/caboose1029/minecraft-cc/commits/" .. branchName,
        { ["User-Agent"] = "ghfetch" }
    )
    if response == nil then
        print("(couldn't check latest commit - continuing anyway)")
        return
    end
    local body = response.readAll()
    response.close()
    local ok, data = pcall(textutils.unserializeJSON, body)
    if not ok or data == nil or data.sha == nil then
        print("(couldn't parse latest commit info - continuing anyway)")
        return
    end
    local message = "?"
    if data.commit ~= nil and data.commit.message ~= nil then
        message = string.match(data.commit.message, "^[^\n]*") or data.commit.message
    end
    local date = "?"
    if data.commit ~= nil and data.commit.author ~= nil and data.commit.author.date ~= nil then
        date = data.commit.author.date
    end
    print("Latest commit on " .. branchName .. ": " .. string.sub(data.sha, 1, 7) .. " - " .. message .. " (" .. date .. ")")
end

reportLatestCommit(branch)

-- Downloads `url`, writing the raw response body to `path`. Does NOT
-- create parent directories - call fs.makeDir first for any path with a
-- folder in it.
local function downloadFile(url, path)
    local response = http.get(url)
    if response == nil then
        return false
    end
    local body = response.readAll()
    response.close()
    local file = fs.open(path, "w")
    if file == nil then
        return false
    end
    file.write(body)
    file.close()
    return true
end

-- Same GET, but returns the response body directly instead of writing it
-- to disk - for the manifest, whose content is needed immediately.
local function downloadText(url)
    local response = http.get(url)
    if response == nil then
        return nil
    end
    local body = response.readAll()
    response.close()
    return body
end

local manifestUrl = repoBase .. "/" .. FILES_MANIFEST
local manifestText = downloadText(manifestUrl)
if manifestText == nil then
    print("Could not fetch the file manifest (" .. FILES_MANIFEST .. ") - aborting.")
    return
end

-- Also save it to disk, same as every other synced file - not strictly
-- needed for this run (already have the text above), but keeps it
-- inspectable and consistent with everything else this fetches.
downloadFile(manifestUrl, FILES_MANIFEST)

-- One path per line - gmatch's "[^\n]+" pattern naturally skips blank
-- lines (including a trailing one, which a text file conventionally
-- ends with), so there's no separate empty-line check needed here.
local files = {}
for line in string.gmatch(manifestText, "[^\n]+") do
    files[#files + 1] = line
end

local fetched = 0
local failures = 0
for i = 1, #files do
    local path = files[i]
    -- Every real path in this tree is either bare ("Foo.lua") or exactly
    -- one directory deep ("lib/Foo.lua") - never nested further, so the
    -- directory is just the part before the first "/", when there is one.
    local slashPos = string.find(path, "/")
    if slashPos ~= nil then
        fs.makeDir(string.sub(path, 1, slashPos - 1))
    end
    local url = repoBase .. "/" .. path
    print("Fetching " .. path .. "...")
    if downloadFile(url, path) then
        print("  ok")
        fetched = fetched + 1
    else
        print("  FAILED: " .. path)
        failures = failures + 1
    end
end

if failures > 0 then
    print(failures .. " file(s) failed.")
else
    print("Fetched " .. fetched .. " file(s).")
end
