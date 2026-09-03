local planModule = require("moonman.domain.plan")
local args = require("moonman.cli.args")

return {
  summary = "Show a package's files, dependencies, and install layout",
  usage = {
    "moonman info <package>",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, {})
    if positional == nil then
      return false, flags
    end
    local name = positional[1]
    if name == nil then
      return false, "info requires a package name"
    end

    local mf, err = ctx:manifest()
    if mf == nil then
      return false, err
    end
    local pkg, findErr = mf:findPackage(name)
    if pkg == nil then
      return false, findErr
    end
    local plan, planErr = planModule.forPackage(mf, pkg)
    if plan == nil then
      return false, planErr
    end

    ctx.log.field("package", pkg.name)
    if pkg.description then
      ctx.log.field("description", pkg.description)
    end
    ctx.log.field("source", ctx:origin())
    ctx.log.field("entry", plan.entry)
    ctx.log.field("layout", plan.root and (plan.root .. "/ + launcher " .. plan.launcher) or "single file")
    if #pkg.dependencies > 0 then
      ctx.log.field("requires", table.concat(pkg.dependencies, ", "))
    end
    ctx.log.info("files:")
    for _, file in ipairs(plan.files) do
      ctx.log.detail(("%s -> %s%s"):format(
        file.source, file.target, file.role == "dependency" and "  (vendored)" or ""))
    end
    return true
  end,
}
