local packages = require("moonman.app.packages")
local args = require("moonman.cli.args")

return {
  summary = "Reinstall packages from the current ref",
  usage = {
    "moonman update [<package>...] [--dry-run]",
    "",
    "With no arguments, refreshes every installed package. Each package keeps",
    "the name it was installed under.",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, { ["dry-run"] = "boolean" })
    if positional == nil then
      return false, flags
    end
    return packages.update(ctx, positional, { dryRun = flags["dry-run"] })
  end,
}
