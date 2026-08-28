local MANIFEST_URL = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/refs/heads/main/dist/manifest.json"
local SUPPORTED_SCHEMA = 1

local function fetchManifest()
  local response, err = http.get(MANIFEST_URL)
  if response == nil then
    return nil, "failed to download manifest: " .. err
  end
  local body = response.readAll()
  response.close()
  if body == nil then
    return nil, "failed to read manifest response"
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

local manifest, err = fetchManifest()

if manifest == nil then
  printError(err)
  return
end

print("Manifest loaded successfully")
print("Schema: " .. tostring(manifest.schema))

local pkgName = "test_package"
local pkg = manifest.pkgs[pkgName]

if pkg == nil then
  printError("unknown package: " .. pkgName)
  return
end

print()
print("Found package: " .. pkgName)
print("Entrypoint: " .. pkg.entry)

for _, path in ipairs(pkg.files) do
  print("File: " .. path)
end
