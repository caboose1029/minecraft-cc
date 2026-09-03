--- Filesystem adapter over CC's fs API.
local path = require("moonman.domain.path")

local fs_port = {}

---@param target string
---@return boolean
function fs_port.exists(target)
  return fs.exists(target)
end

---@param target string
---@return boolean
function fs_port.isDir(target)
  return fs.exists(target) and fs.isDir(target)
end

---@param target string
---@return string|nil contents, string|nil err
function fs_port.read(target)
  if not fs.exists(target) or fs.isDir(target) then
    return nil, "not a file: " .. target
  end
  local handle, err = fs.open(target, "r")
  if handle == nil then
    return nil, err or ("cannot open " .. target)
  end
  local contents = handle.readAll()
  handle.close()
  return contents or ""
end

--- Write a file, creating parent directories as needed.
---@param target string
---@param contents string
---@return boolean ok, string|nil err
function fs_port.write(target, contents)
  local parent = path.dirname(target)
  if parent ~= "" and parent ~= "/" and not fs.exists(parent) then
    fs.makeDir(parent)
  end
  if fs.exists(target) and fs.isDir(target) then
    return false, "refusing to overwrite directory: " .. target
  end
  local handle, err = fs.open(target, "w")
  if handle == nil then
    return false, err or ("cannot write " .. target)
  end
  handle.write(contents)
  handle.close()
  return true
end

---@param target string
---@return boolean ok, string|nil err
function fs_port.delete(target)
  if not fs.exists(target) then
    return true
  end
  if fs.isReadOnly(target) then
    return false, "read-only: " .. target
  end
  fs.delete(target)
  return true
end

--- Remove now-empty ancestor directories of `target`, stopping at `stopAt`.
--- Keeps uninstall from leaving hollow directory trees behind.
---@param target string
---@param stopAt string|nil
function fs_port.pruneEmptyParents(target, stopAt)
  for _, dir in ipairs(path.ancestors(target, stopAt or "/")) do
    if fs.exists(dir) and fs.isDir(dir) and #fs.list(dir) == 0 and not fs.isReadOnly(dir) then
      fs.delete(dir)
    else
      return
    end
  end
end

return fs_port
