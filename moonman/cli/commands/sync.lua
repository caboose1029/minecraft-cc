local sync = require("moonman.app.sync")
local args = require("moonman.cli.args")

return {
  summary = "Copy manifest files matching a path prefix, keeping structure",
  usage = {
    "moonman sync <path-prefix> [--into <dir>] [--dry-run]",
    "",
    "Fetches every manifest source path at or below <path-prefix> and writes it",
    "preserving directory structure, with a leading \"src/\" stripped. This is the",
    "raw escape hatch; prefer \"moonman install\" for anything with dependencies.",
    "",
    "  moonman sync share/test          -> /share/test/...",
    "  moonman sync player/caboose --into /work",
    "",
    "  --into <dir>  write beneath <dir> instead of /",
    "  --dry-run     print what would be written, change nothing",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, { into = "string", ["dry-run"] = "boolean" })
    if positional == nil then
      return false, flags
    end
    return sync.run(ctx, positional[1], { into = flags.into, dryRun = flags["dry-run"] })
  end,
}
