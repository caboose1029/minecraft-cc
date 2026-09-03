--- Record of what moonman has installed, so removals and updates are exact
--- rather than guesswork over the filesystem.
local state = {}

state.PATH = "/.moonman/installed.json"

---@param ports table
---@return table entries keyed by package name
function state.load(ports)
  if not ports.fs.exists(state.PATH) then
    return {}
  end
  local contents = ports.fs.read(state.PATH)
  if contents == nil then
    return {}
  end
  local decoded = ports.json.decode(contents)
  if type(decoded) ~= "table" then
    return {}
  end
  -- An empty JSON object round-trips as an array; both decode to {}.
  local entries = {}
  for name, entry in pairs(decoded) do
    if type(name) == "string" and type(entry) == "table" then
      entries[name] = entry
    end
  end
  return entries
end

---@param ports table
---@param entries table
---@return boolean ok, string|nil err
function state.save(ports, entries)
  return ports.fs.write(state.PATH, ports.json.encode(entries))
end

--- Names of installed packages, sorted.
---@param entries table
---@return string[]
function state.names(entries)
  local names = {}
  for name in pairs(entries) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Build the record written after a successful install.
---@param plan table
---@param ref string
---@return table
function state.record(plan, ref)
  local paths = {}
  for _, file in ipairs(plan.files) do
    paths[#paths + 1] = file.target
  end
  if plan.launcher then
    paths[#paths + 1] = plan.launcher
  end
  return {
    install_name = plan.installName,
    root = plan.root,
    entry = plan.entry,
    launcher = plan.launcher,
    ref = ref,
    paths = paths,
    installed_at = os.epoch("utc"),
  }
end

return state
