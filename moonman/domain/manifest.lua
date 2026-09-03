--- Manifest domain model: validation and queries over a decoded manifest.
---
--- Takes an already-decoded table (from textutils.unserialiseJSON or any other
--- source) so that nothing here depends on CC APIs.
local path = require("moonman.domain.path")

local manifest = {}

--- Manifest schema this build of moonman understands.
manifest.SCHEMA = 2

local Manifest = {}
Manifest.__index = Manifest

local function isTable(value)
  return type(value) == "table"
end

local function sortedKeys(tbl)
  local keys = {}
  for key in pairs(tbl) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

--- Normalise a list of {source, target} file records.
local function readFileList(raw, owner)
  local files = {}
  if raw == nil then
    return files
  end
  if not isTable(raw) then
    return nil, owner .. ": files must be a list"
  end
  for index, entry in ipairs(raw) do
    if not isTable(entry) or type(entry.source) ~= "string" then
      return nil, owner .. ": file #" .. index .. " is missing a source path"
    end
    files[#files + 1] = {
      source = path.normalise(entry.source),
      target = path.normalise(entry.target or path.basename(entry.source)),
    }
  end
  return files
end

local function readDependencies(raw, owner)
  local deps = {}
  if raw == nil then
    return deps
  end
  if not isTable(raw) then
    return nil, owner .. ": dependencies must be a list"
  end
  for index, name in ipairs(raw) do
    if type(name) ~= "string" then
      return nil, owner .. ": dependency #" .. index .. " is not a module name"
    end
    deps[#deps + 1] = name
  end
  return deps
end

--- Validate and wrap a decoded manifest table.
---@param decoded table
---@return table|nil model, string|nil err
function manifest.parse(decoded)
  if not isTable(decoded) then
    return nil, "manifest is not a JSON object"
  end
  if decoded.schema ~= manifest.SCHEMA then
    return nil,
      ("unsupported manifest schema %s (this moonman speaks %d) - run \"moonman self-update\"")
        :format(tostring(decoded.schema), manifest.SCHEMA)
  end
  if not isTable(decoded.source) or type(decoded.source.repo) ~= "string" then
    return nil, "manifest is missing source.repo"
  end

  local model = setmetatable({
    schema = decoded.schema,
    generatedAt = decoded.generated_at,
    source = {
      repo = decoded.source.repo,
      ref = decoded.source.ref,
      manifestPath = decoded.source.manifest_path or "dist/manifest.json",
    },
    modules = {},
    packages = {},
    moonman = { version = "unknown", files = {} },
  }, Manifest)

  if isTable(decoded.moonman) then
    local files, err = readFileList(decoded.moonman.files, "moonman")
    if files == nil then
      return nil, err
    end
    model.moonman = { version = decoded.moonman.version or "unknown", files = files }
  end

  for name, entry in pairs(decoded.modules or {}) do
    if not isTable(entry) or type(entry.source) ~= "string" then
      return nil, "module " .. name .. " is missing a source path"
    end
    local deps, err = readDependencies(entry.dependencies, "module " .. name)
    if deps == nil then
      return nil, err
    end
    model.modules[name] = { name = name, source = path.normalise(entry.source), dependencies = deps }
  end

  for name, entry in pairs(decoded.packages or {}) do
    if not isTable(entry) then
      return nil, "package " .. name .. " is not an object"
    end
    local files, err = readFileList(entry.files, "package " .. name)
    if files == nil then
      return nil, err
    end
    if #files == 0 then
      return nil, "package " .. name .. " has no files"
    end
    local deps, depErr = readDependencies(entry.dependencies, "package " .. name)
    if deps == nil then
      return nil, depErr
    end
    model.packages[name] = {
      name = name,
      description = entry.description,
      entry = entry.entry or files[1].target,
      files = files,
      dependencies = deps,
    }
  end

  return model
end

--- All package names, sorted.
---@return string[]
function Manifest:packageNames()
  return sortedKeys(self.packages)
end

--- All module names, sorted.
---@return string[]
function Manifest:moduleNames()
  return sortedKeys(self.modules)
end

---@param name string
---@return table|nil
function Manifest:getPackage(name)
  return self.packages[name]
end

---@param name string
---@return table|nil
function Manifest:getModule(name)
  return self.modules[name]
end

--- Find a package by exact name, or by unique leaf name so that `install test`
--- resolves `caboose/test` when it is unambiguous.
---@param name string
---@return table|nil pkg, string|nil err
function Manifest:findPackage(name)
  local exact = self.packages[name]
  if exact ~= nil then
    return exact
  end
  local matches = {}
  for _, candidate in ipairs(self:packageNames()) do
    if path.basename(candidate) == name then
      matches[#matches + 1] = candidate
    end
  end
  if #matches == 1 then
    return self.packages[matches[1]]
  end
  if #matches > 1 then
    table.sort(matches)
    return nil, "\"" .. name .. "\" is ambiguous: " .. table.concat(matches, ", ")
  end
  return nil, "no such package: " .. name
end

--- Package names whose name or description contains `query` (case-insensitive).
---@param query string
---@return string[]
function Manifest:search(query)
  local needle = query:lower()
  local matches = {}
  for _, name in ipairs(self:packageNames()) do
    local pkg = self.packages[name]
    local haystack = (name .. " " .. (pkg.description or "")):lower()
    if needle == "" or haystack:find(needle, 1, true) ~= nil then
      matches[#matches + 1] = name
    end
  end
  return matches
end

--- Every source path the manifest knows about, sorted. Backs `moonman sync`.
---@return string[]
function Manifest:sourcePaths()
  local seen, paths = {}, {}
  local function add(source)
    if not seen[source] then
      seen[source] = true
      paths[#paths + 1] = source
    end
  end
  for _, entry in pairs(self.modules) do
    add(entry.source)
  end
  for _, pkg in pairs(self.packages) do
    for _, file in ipairs(pkg.files) do
      add(file.source)
    end
  end
  table.sort(paths)
  return paths
end

--- Resolve a package's dependencies transitively.
--- Returns modules in dependency-first order; cycles are reported, not followed.
---@param pkg table
---@return table[]|nil modules, string|nil err
function Manifest:resolveDependencies(pkg)
  local ordered, visiting, visited = {}, {}, {}

  local function visit(name, trail)
    if visited[name] then
      return true
    end
    if visiting[name] then
      return nil, "dependency cycle: " .. table.concat(trail, " -> ") .. " -> " .. name
    end
    local module = self.modules[name]
    if module == nil then
      return nil, "unknown dependency \"" .. name .. "\" required by " .. table.concat(trail, " -> ")
    end
    visiting[name] = true
    trail[#trail + 1] = name
    for _, dep in ipairs(module.dependencies) do
      local ok, err = visit(dep, trail)
      if not ok then
        return nil, err
      end
    end
    table.remove(trail)
    visiting[name] = nil
    visited[name] = true
    ordered[#ordered + 1] = module
    return true
  end

  for _, name in ipairs(pkg.dependencies) do
    local ok, err = visit(name, { "package " .. pkg.name })
    if not ok then
      return nil, err
    end
  end
  return ordered
end

return manifest
