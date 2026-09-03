local version = require("moonman.version")

return {
  summary = "Show this help, or detailed help for one command",
  usage = {
    "moonman help [<command>]",
  },
  run = function(ctx, argv)
    -- Required here rather than at the top so that loading `help` never pulls
    -- in every other command module unless help is actually run.
    local cli = require("moonman.cli")
    local name = argv[1]

    if name ~= nil then
      local command, err = cli.resolve(name)
      if command == nil then
        return false, err
      end
      for _, line in ipairs(command.usage) do
        ctx.log.info(line)
      end
      return true
    end

    ctx.log.info("moonman " .. version .. " - package manager for the minecraft-cc monorepo")
    ctx.log.info("")
    ctx.log.info("Usage: moonman <command> [args]")
    ctx.log.info("")
    for _, command in ipairs(cli.all()) do
      ctx.log.detail(("%-12s %s"):format(command.name, command.summary))
    end
    ctx.log.info("")
    ctx.log.field("tracking", ctx:origin())
    ctx.log.info("Run \"moonman help <command>\" for details.")
    return true
  end,
}
