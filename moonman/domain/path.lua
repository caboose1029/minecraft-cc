--- Pure path and module-name helpers.
---
--- This module is deliberately free of CC APIs so it stays testable off-device.
--- Paths use "/" separators; a leading "/" marks an absolute device path and is
--- preserved through every operation.
local path = {}

--- Resolve "." and ".." segments and collapse duplicate separators.
---@param p string
---@return string
function path.normalise(p)
  local absolute = p:sub(1, 1) == "/"
  local parts = {}
  for part in p:gmatch("[^/]+") do
    if part == ".." then
      if #parts > 0 and parts[#parts] ~= ".." then
        table.remove(parts)
      elseif not absolute then
        parts[#parts + 1] = part
      end
    elseif part ~= "." then
      parts[#parts + 1] = part
    end
  end
  local joined = table.concat(parts, "/")
  if absolute then
    return "/" .. joined
  end
  return joined
end

--- Join any number of path fragments, skipping empty ones.
---@vararg string|nil
---@return string
function path.join(...)
  local parts = {}
  for i = 1, select("#", ...) do
    local part = select(i, ...)
    if part ~= nil and part ~= "" then
      parts[#parts + 1] = part
    end
  end
  return path.normalise(table.concat(parts, "/"))
end

--- The parent directory of a path, or "/" for a top-level absolute path.
---@param p string
---@return string
function path.dirname(p)
  local normalised = path.normalise(p)
  local parent = normalised:match("^(.*)/[^/]+$")
  if parent == nil or parent == "" then
    return normalised:sub(1, 1) == "/" and "/" or ""
  end
  return parent
end

--- The final segment of a path.
---@param p string
---@return string
function path.basename(p)
  local normalised = path.normalise(p)
  return normalised:match("([^/]+)$") or normalised
end

--- Strip a ".lua" suffix if present.
---@param p string
---@return string
function path.stripExtension(p)
  return (p:gsub("%.lua$", ""))
end

--- Convert a require() module name into the file path CC will look for.
--- `share.test.sharetest` -> `share/test/sharetest.lua`
---@param name string
---@return string
function path.moduleToPath(name)
  return (name:gsub("%.", "/")) .. ".lua"
end

--- Convert a repo path (relative to src/) into the module name CC requires.
--- `share/test/sharetest.lua` -> `share.test.sharetest`
--- `share/test/init.lua`      -> `share.test`
---@param p string
---@return string
function path.pathToModule(p)
  local stripped = path.stripExtension(path.normalise(p)):gsub("/init$", "")
  return (stripped:gsub("/", "."))
end

--- True when `p` sits at or beneath `prefix`, matching on whole segments only
--- so that "share/te" never matches "share/test/...".
---@param p string
---@param prefix string
---@return boolean
function path.hasPrefix(p, prefix)
  if prefix == "" then
    return true
  end
  local normalisedPrefix = path.normalise(prefix)
  if p == normalisedPrefix then
    return true
  end
  return p:sub(1, #normalisedPrefix + 1) == normalisedPrefix .. "/"
end

--- Every ancestor directory of `p`, deepest first. Used when pruning empties.
---@param p string
---@param stopAt string directory to stop before (exclusive)
---@return string[]
function path.ancestors(p, stopAt)
  local result = {}
  local current = path.dirname(p)
  stopAt = path.normalise(stopAt or "/")
  while current ~= "" and current ~= "/" and current ~= stopAt do
    result[#result + 1] = current
    current = path.dirname(current)
  end
  return result
end

return path
