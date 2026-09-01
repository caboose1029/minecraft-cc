local MANIFEST_URL = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/refs/heads/main/dist/manifest.json"
local SCHEMA_VERSION = 1

local function download(url)
  local response, err = http.get(url)
  if response == nil then
    return nil, err
  end
  local body = response.readAll()
  response.close()
  if body == nil then
    return nil, "read response"
  end
  return body
end

local function writeFile(path, contents)
  local file = fs.open(path, "w")
  if file == nil then
    return false, "open file: " .. path
  end
  file.write(contents)
  file.close()
  return true
end

local function fetchManifest()
  local body, err = download(MANIFEST_URL)
  if body == nil then
    return nil, err
  end
  local manifest, parseErr = textutils.unserialiseJSON(body)
  if manifest == nil then
    return nil, "failed to parse manifest: " .. parseErr
  end
  if manifest.schema ~= SCHEMA_VERSION then
    return nil, "unsupported manifest schema: " .. tostring(manifest.schema)
  end
  return manifest
end

local function searchManifest(lst, tgt, idx, match)
  if match == nil then
    match = {}
  end
  if idx > #lst then
    return match
  end
  if lst[idx]:sub(1, #tgt) == tgt then
    match[#match + 1] = lst[idx]
  end
  return searchManifest(lst, tgt, idx + 1, match)
end

local function syncFile(src, dest)
  local contents, err = download(src)
  if contents == nil then
    return false, err
  end
  local written, writeErr = writeFile(dest, contents)
  if written == false then
    return false, writeErr
  end
  return true, nil
end

local function sync(manifest, args)
  local tgt = args[1]
  if tgt == nil then
    printError("sync requires a target path")
    return
  end
  local entries = {}
  for path, _ in pairs(manifest.files) do
    table.insert(entries, path)
  end
  if #entries == 0 then
    printError("no files found in manifest")
    return
  end
  local startIdx = 1
  local srcPaths = searchManifest(entries, tgt, startIdx)
  if #srcPaths == 0 then
    printError("no matching file found for path: " .. tgt)
    return
  end
  for _, path in ipairs(srcPaths) do
    local src = manifest.source.base_url .. "/" .. path
    local dest = "/" .. fs.getName(path)
    local ok, err = syncFile(src, dest)
    if ok == false then
      printError("sync file " .. path .. ": " .. err)
      return
    end
    print("Synced " .. path .. " -> " .. dest)
  end
end

local args = { ... }
local command = table.remove(args, 1)

if command == nil or command == "help" then
  print("Usage: ")
  print("moonman sync <path>")
end

local manifest, err = fetchManifest()

if manifest == nil then
  printError(err)
  return
end

if command == "sync" then
  sync(manifest, args)
else
  printError("unknown command: " .. command)
end
