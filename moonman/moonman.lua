local MANIFEST_URL = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/refs/heads/main/dist/manifest.json"
local SUPPORTED_SCHEMA = 1

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
  if manifest.schema ~= SUPPORTED_SCHEMA then
    return nil, "unsupported manifest schema: " .. tostring(manifest.schema)
  end
  return manifest
end

local function sync(manifest, args)
  local sourcePath = args[1]
  if sourcePath == nil then
    printError("sync requires a source path")
    return
  end
  local entry = manifest.files[sourcePath]
  if entry == nil then
    printError("file not found in manifest: " .. sourcePath)
    return
  end
  local url = manifest.source.base_url .. "/" .. sourcePath
  local contents, err = download(url)
  if contents == nil then
    printError("failed to download file: " .. tostring(err))
    return
  end
  local destination = "/" .. fs.getName(sourcePath)
  local ok, writeErr = writeFile(destination, contents)
  if not ok then
    printError(writeErr)
  end
  print("Synced " .. sourcePath .. " -> " .. destination)
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
