--- Replace moonman's own files from the manifest at the active ref.
---
--- This is the same operation the bootstrap script performs, reused so that
--- switching branches or picking up a new release needs no re-bootstrap.
local installer = require("moonman.app.installer")
local planModule = require("moonman.domain.plan")

local selfupdate = {}

---@param ctx table
---@param opts table|nil { dryRun = boolean }
---@return boolean ok, string|nil err
function selfupdate.run(ctx, opts)
  opts = opts or {}
  local mf, err = ctx:manifest()
  if mf == nil then
    return false, err
  end

  local plan, planErr = planModule.forMoonman(mf)
  if plan == nil then
    return false, planErr
  end

  ctx.log.info(("%s moonman %s from %s"):format(
    opts.dryRun and "Would update" or "Updating", plan.version, ctx:origin()))

  -- The library tree is cleared first so files dropped between versions do not
  -- linger and shadow their replacements via require().
  if not opts.dryRun and ctx.fs.isDir("/moonman") then
    local ok, deleteErr = ctx.fs.delete("/moonman")
    if not ok then
      return false, deleteErr
    end
  end

  local ok, applyErr = installer.apply(ctx, plan, { dryRun = opts.dryRun })
  if not ok then
    return false, applyErr
  end

  if not opts.dryRun then
    ctx.log.ok("moonman is now at " .. plan.version)
  end
  return true
end

return selfupdate
