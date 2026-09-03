local selfupdate = require("moonman.app.selfupdate")
local args = require("moonman.cli.args")

return {
  summary = "Reinstall moonman itself from the current ref",
  usage = {
    "moonman self-update [--dry-run]",
    "",
    "Replaces /moonman.lua and the /moonman/ library tree. Your config and",
    "install records live in /.moonman/ and are left alone.",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, { ["dry-run"] = "boolean" })
    if positional == nil then
      return false, flags
    end
    return selfupdate.run(ctx, { dryRun = flags["dry-run"] })
  end,
}
