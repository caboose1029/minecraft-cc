--- Persisted moonman configuration: which repo and ref to install from.
local config = {}

--- Config and install state live outside /moonman so that self-update, which
--- replaces that whole tree, can never clobber them.
config.PATH = "/.moonman/config.json"

config.DEFAULTS = {
  repo = "caboose1029/minecraft-cc",
  ref = "main",
  manifest_path = "dist/manifest.json",
}

--- Keys a user may set with `moonman config set`.
config.KEYS = { "repo", "ref", "manifest_path" }

---@param ports table
---@return table config, string|nil warning
function config.load(ports)
  local loaded = {}
  local warning
  if ports.fs.exists(config.PATH) then
    local contents, readErr = ports.fs.read(config.PATH)
    if contents == nil then
      warning = "could not read " .. config.PATH .. ": " .. readErr
    else
      local decoded, decodeErr = ports.json.decode(contents)
      if decoded == nil then
        warning = config.PATH .. " is corrupt (" .. decodeErr .. "); using defaults"
      else
        loaded = decoded
      end
    end
  end

  local merged = {}
  for key, value in pairs(config.DEFAULTS) do
    merged[key] = value
  end
  for _, key in ipairs(config.KEYS) do
    if type(loaded[key]) == "string" and loaded[key] ~= "" then
      merged[key] = loaded[key]
    end
  end
  return merged, warning
end

---@param ports table
---@param values table
---@return boolean ok, string|nil err
function config.save(ports, values)
  local persisted = {}
  for _, key in ipairs(config.KEYS) do
    persisted[key] = values[key]
  end
  return ports.fs.write(config.PATH, ports.json.encode(persisted))
end

return config
