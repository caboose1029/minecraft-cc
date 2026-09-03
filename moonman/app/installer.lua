--- Executes install plans: downloads every file, then writes them.
---
--- Downloads complete before any write happens, so a mid-transfer failure
--- leaves the previous install untouched rather than half-replaced.
local planModule = require("moonman.domain.plan")

local installer = {}

--- Fetch every file in a plan into memory.
---@param ctx table
---@param plan table
---@return table|nil contents keyed by target path, string|nil err
local function fetchAll(ctx, plan)
  local contents = {}
  for index, file in ipairs(plan.files) do
    ctx.log.detail(("[%d/%d] %s"):format(index, #plan.files, file.source))
    local body, err = ctx.http.get(ctx:url(file.source))
    if body == nil then
      return nil, "fetch " .. file.source .. ": " .. err
    end
    contents[file.target] = body
  end
  return contents
end

--- Run a plan.
---@param ctx table
---@param plan table
---@param opts table|nil { dryRun = boolean, replaceRoot = boolean }
---@return boolean ok, string|nil err
function installer.apply(ctx, plan, opts)
  opts = opts or {}

  if opts.dryRun then
    for _, target in ipairs(planModule.targets(plan)) do
      ctx.log.detail(target)
    end
    return true
  end

  local contents, err = fetchAll(ctx, plan)
  if contents == nil then
    return false, err
  end

  -- Clearing the package root drops files that a previous version installed
  -- but the current one no longer ships.
  if opts.replaceRoot and plan.root and ctx.fs.isDir(plan.root) then
    local ok, deleteErr = ctx.fs.delete(plan.root)
    if not ok then
      return false, deleteErr
    end
  end

  for _, file in ipairs(plan.files) do
    local ok, writeErr = ctx.fs.write(file.target, contents[file.target])
    if not ok then
      return false, writeErr
    end
  end

  if plan.launcher then
    local ok, writeErr = ctx.fs.write(plan.launcher, planModule.launcherSource(plan.entry))
    if not ok then
      return false, writeErr
    end
  end

  return true
end

--- Delete every path a previous install recorded.
---@param ctx table
---@param record table
---@return boolean ok, string|nil err
function installer.removeRecorded(ctx, record)
  for _, target in ipairs(record.paths or {}) do
    local ok, err = ctx.fs.delete(target)
    if not ok then
      return false, err
    end
    ctx.fs.pruneEmptyParents(target, "/")
  end
  if record.root then
    ctx.fs.delete(record.root)
  end
  return true
end

return installer
