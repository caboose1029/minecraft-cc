--- moonman bootstrap.
---
--- The one file a fresh computer needs. Fetches the manifest for a ref of the
--- minecraft-cc monorepo, installs moonman from it, and records the ref so
--- every later command follows the same branch.
---
--- Usage:
---   wget run https://raw.githubusercontent.com/caboose1029/minecraft-cc/main/bootstrap.lua
---   wget run https://raw.githubusercontent.com/caboose1029/minecraft-cc/main/bootstrap.lua feat/my-branch
---   wget run https://raw.githubusercontent.com/caboose1029/minecraft-cc/main/bootstrap.lua main other-owner/other-repo
---
--- Deliberately self-contained: it cannot require() anything, because nothing
--- is installed yet.

local DEFAULT_REPO = "caboose1029/minecraft-cc"
local DEFAULT_REF = "main"
local MANIFEST_PATH = "dist/manifest.json"
local SCHEMA_VERSION = 2
local CONFIG_PATH = "/.moonman/config.json"
local RAW_HOST = "https://raw.githubusercontent.com"

local args = { ... }
local ref = args[1]
local repo = args[2]
if ref == nil or ref == "" then
  ref = DEFAULT_REF
end
if repo == nil or repo == "" then
  repo = DEFAULT_REPO
end

local function fail(message)
  printError("bootstrap: " .. message)
end

local function rawUrl(sourcePath)
  return ("%s/%s/%s/%s"):format(RAW_HOST, repo, ref, sourcePath)
end

local function download(url)
  local response, err = http.get(url, { ["Cache-Control"] = "no-cache", ["Pragma"] = "no-cache" })
  if response == nil then
    return nil, (err or "request failed") .. " (" .. url .. ")"
  end
  local body = response.readAll()
  response.close()
  if body == nil then
    return nil, "empty response from " .. url
  end
  return body
end

local function writeFile(target, contents)
  local parent = target:match("^(.*)/[^/]+$")
  if parent ~= nil and parent ~= "" and not fs.exists(parent) then
    fs.makeDir(parent)
  end
  local handle, err = fs.open(target, "w")
  if handle == nil then
    return false, err or ("cannot write " .. target)
  end
  handle.write(contents)
  handle.close()
  return true
end

if http == nil then
  fail("this computer has the http API disabled; moonman cannot install")
  return
end

print("Bootstrapping moonman from " .. repo .. "@" .. ref)

local manifestBody, manifestErr = download(rawUrl(MANIFEST_PATH))
if manifestBody == nil then
  fail(manifestErr)
  fail("check that the ref \"" .. ref .. "\" exists and has a committed " .. MANIFEST_PATH)
  return
end

local manifest, decodeErr = textutils.unserialiseJSON(manifestBody)
if manifest == nil then
  fail("manifest is not valid JSON: " .. tostring(decodeErr))
  return
end
if manifest.schema ~= SCHEMA_VERSION then
  fail("manifest schema is " .. tostring(manifest.schema) .. ", this bootstrap expects " .. SCHEMA_VERSION)
  return
end
if type(manifest.moonman) ~= "table" or type(manifest.moonman.files) ~= "table" or #manifest.moonman.files == 0 then
  fail("manifest lists no moonman files")
  return
end

local files = manifest.moonman.files
local version = manifest.moonman.version or "unknown"

-- Fetch everything before writing anything, so a network failure part-way
-- through leaves any existing install intact.
local contents = {}
for index, file in ipairs(files) do
  if type(file.source) ~= "string" or type(file.target) ~= "string" then
    fail("manifest moonman entry #" .. index .. " is malformed")
    return
  end
  write(("\r[%d/%d] %s        "):format(index, #files, file.target))
  local body, err = download(rawUrl(file.source))
  if body == nil then
    print()
    fail(err)
    return
  end
  contents[index] = body
end
print()

if fs.exists("/moonman") and fs.isDir("/moonman") then
  fs.delete("/moonman")
end

for index, file in ipairs(files) do
  local target = "/" .. file.target
  local ok, err = writeFile(target, contents[index])
  if not ok then
    fail(err)
    return
  end
end

local ok, configErr = writeFile(CONFIG_PATH, textutils.serialiseJSON({
  repo = repo,
  ref = ref,
  manifest_path = MANIFEST_PATH,
}))
if not ok then
  fail("could not write " .. CONFIG_PATH .. ": " .. tostring(configErr))
  return
end

print("Installed moonman " .. version .. " (" .. #files .. " files) from " .. repo .. "@" .. ref)
print()
print("  moonman help              list commands")
print("  moonman list --available  see what you can install")
print("  moonman use <ref>         switch branches later")
