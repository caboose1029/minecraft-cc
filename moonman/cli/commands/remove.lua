local packages = require("moonman.app.packages")
local args = require("moonman.cli.args")

return {
  summary = "Remove installed packages",
  usage = {
    "moonman remove <package>...",
    "",
    "Deletes exactly the paths recorded at install time, then prunes any",
    "directories left empty. Files you created yourself are never touched.",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, {})
    if positional == nil then
      return false, flags
    end
    return packages.remove(ctx, positional)
  end,
}
