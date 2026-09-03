local packages = require("moonman.app.packages")
local args = require("moonman.cli.args")

return {
  summary = "List installed or available packages",
  usage = {
    "moonman list [--available]",
    "",
    "  --available   list every package in the manifest instead of what is",
    "                installed here",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, { available = "boolean" })
    if positional == nil then
      return false, flags
    end

    if flags.available then
      local mf, err = ctx:manifest()
      if mf == nil then
        return false, err
      end
      local names = mf:packageNames()
      if #names == 0 then
        ctx.log.info("No packages in the manifest.")
        return true
      end
      ctx.log.info(("Available from %s:"):format(ctx:origin()))
      for _, name in ipairs(names) do
        local pkg = mf:getPackage(name)
        ctx.log.detail(name .. (pkg.description and ("  -- " .. pkg.description) or ""))
      end
      return true
    end

    local installed = packages.installed(ctx)
    if #installed == 0 then
      ctx.log.info("Nothing installed. Try \"moonman list --available\".")
      return true
    end
    ctx.log.info("Installed:")
    for _, entry in ipairs(installed) do
      ctx.log.detail(("%s  (%s @ %s)"):format(
        entry.name, entry.record.install_name or "?", entry.record.ref or "?"))
    end
    return true
  end,
}
