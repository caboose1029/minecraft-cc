local packages = require("moonman.app.packages")
local args = require("moonman.cli.args")

return {
  summary = "Install packages onto this computer",
  usage = {
    "moonman install <package>... [--as <name>] [--dry-run]",
    "",
    "Installs each package and vendors its shared dependencies alongside it, so",
    "require(\"share.ns.mod\") resolves the same on-device as it does in the repo.",
    "",
    "A single-file package with no dependencies installs flat as /<name>.lua.",
    "Anything else installs to /<name>/ with a /<name>.lua launcher, so the",
    "package still runs as \"<name>\" from the shell.",
    "",
    "  --as <name>   install under a different name (resolves collisions)",
    "  --dry-run     print what would be written, change nothing",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, { as = "string", ["dry-run"] = "boolean" })
    if positional == nil then
      return false, flags
    end
    return packages.install(ctx, positional, { as = flags.as, dryRun = flags["dry-run"] })
  end,
}
