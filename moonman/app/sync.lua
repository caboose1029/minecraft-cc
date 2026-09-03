--- Raw path-prefix sync: the escape hatch for pulling arbitrary manifest
--- files without going through package resolution.
---
--- Directory structure is preserved (minus a leading "src/") so the device
--- tree mirrors the repository.
local installer = require("moonman.app.installer")
local planModule = require("moonman.domain.plan")

local sync = {}

---@param ctx table
---@param prefix string
---@param opts table|nil { into = string, dryRun = boolean }
---@return boolean ok, string|nil err
function sync.run(ctx, prefix, opts)
  opts = opts or {}
  if prefix == nil or prefix == "" then
    return false, "sync requires a path prefix, e.g. \"moonman sync share/test\""
  end

  local mf, err = ctx:manifest()
  if mf == nil then
    return false, err
  end

  local plan, planErr = planModule.forSync(mf, prefix, { into = opts.into })
  if plan == nil then
    return false, planErr
  end

  ctx.log.info(("%s %d file(s) matching \"%s\""):format(
    opts.dryRun and "Would sync" or "Syncing", #plan.files, prefix))

  local ok, applyErr = installer.apply(ctx, plan, { dryRun = opts.dryRun })
  if not ok then
    return false, applyErr
  end

  if not opts.dryRun then
    for _, file in ipairs(plan.files) do
      ctx.log.detail(file.source .. " -> " .. file.target)
    end
    ctx.log.ok("Synced " .. #plan.files .. " file(s)")
  end
  return true
end

return sync
