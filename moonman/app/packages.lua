--- Package use cases: install, remove, update.
local installer = require("moonman.app.installer")
local planModule = require("moonman.domain.plan")
local stateModule = require("moonman.app.state")

local packages = {}

--- Install one or more packages by name.
---@param ctx table
---@param names string[]
---@param opts table|nil { as = string, dryRun = boolean }
---@return boolean ok, string|nil err
function packages.install(ctx, names, opts)
  opts = opts or {}
  if #names == 0 then
    return false, "install requires at least one package name"
  end
  if opts.as and #names > 1 then
    return false, "--as can only be used with a single package"
  end

  local mf, err = ctx:manifest()
  if mf == nil then
    return false, err
  end

  local entries = stateModule.load(ctx.ports)
  for _, name in ipairs(names) do
    local pkg, findErr = mf:findPackage(name)
    if pkg == nil then
      return false, findErr
    end

    local plan, planErr = planModule.forPackage(mf, pkg, { as = opts.as })
    if plan == nil then
      return false, planErr
    end

    ctx.log.info(("%s %s"):format(opts.dryRun and "Would install" or "Installing", pkg.name))
    local ok, applyErr = installer.apply(ctx, plan, { dryRun = opts.dryRun, replaceRoot = true })
    if not ok then
      return false, applyErr
    end

    if not opts.dryRun then
      entries[pkg.name] = stateModule.record(plan, ctx.config.ref)
      ctx.log.ok(("Installed %s -> run \"%s\""):format(pkg.name, plan.installName))
    end
  end

  if opts.dryRun then
    return true
  end
  return stateModule.save(ctx.ports, entries)
end

--- Remove installed packages, deleting exactly the paths that were written.
---@param ctx table
---@param names string[]
---@return boolean ok, string|nil err
function packages.remove(ctx, names)
  if #names == 0 then
    return false, "remove requires at least one package name"
  end
  local entries = stateModule.load(ctx.ports)

  for _, name in ipairs(names) do
    local record = entries[name]
    if record == nil then
      -- Accept the short install name too, matching how `install` resolves.
      for installed, candidate in pairs(entries) do
        if candidate.install_name == name then
          name, record = installed, candidate
          break
        end
      end
    end
    if record == nil then
      return false, "not installed: " .. name
    end
    local ok, err = installer.removeRecorded(ctx, record)
    if not ok then
      return false, err
    end
    entries[name] = nil
    ctx.log.ok("Removed " .. name)
  end

  return stateModule.save(ctx.ports, entries)
end

--- Reinstall packages from the current ref. With no names, updates everything.
---@param ctx table
---@param names string[]
---@param opts table|nil
---@return boolean ok, string|nil err
function packages.update(ctx, names, opts)
  local entries = stateModule.load(ctx.ports)
  local targets = names
  if #targets == 0 then
    targets = stateModule.names(entries)
    if #targets == 0 then
      ctx.log.info("Nothing installed.")
      return true
    end
  end

  -- Preserve each package's original install name across the update.
  for _, name in ipairs(targets) do
    local record = entries[name]
    local ok, err = packages.install(ctx, { name }, {
      as = record and record.install_name or nil,
      dryRun = opts and opts.dryRun,
    })
    if not ok then
      return false, err
    end
  end
  return true
end

--- Installed packages with their records, sorted by name.
---@param ctx table
---@return table[] list of { name, record }
function packages.installed(ctx)
  local entries = stateModule.load(ctx.ports)
  local list = {}
  for _, name in ipairs(stateModule.names(entries)) do
    list[#list + 1] = { name = name, record = entries[name] }
  end
  return list
end

return packages
