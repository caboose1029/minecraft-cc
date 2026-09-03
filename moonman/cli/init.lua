--- Command dispatch.
---
--- Adding a command means dropping a module in cli/commands/ and adding one
--- line to REGISTRY. Modules are loaded lazily so startup cost stays at a
--- single file read regardless of how many commands exist.
local context = require("moonman.app.context")
local version = require("moonman.version")

local cli = {}

--- Command name -> module. Order here is the order `help` lists them in.
cli.REGISTRY = {
  { name = "install", module = "moonman.cli.commands.install" },
  { name = "remove", module = "moonman.cli.commands.remove" },
  { name = "update", module = "moonman.cli.commands.update" },
  { name = "list", module = "moonman.cli.commands.list" },
  { name = "search", module = "moonman.cli.commands.search" },
  { name = "info", module = "moonman.cli.commands.info" },
  { name = "sync", module = "moonman.cli.commands.sync" },
  { name = "use", module = "moonman.cli.commands.use" },
  { name = "config", module = "moonman.cli.commands.config" },
  { name = "self-update", module = "moonman.cli.commands.selfupdate" },
  { name = "help", module = "moonman.cli.commands.help" },
}

cli.ALIASES = {
  i = "install",
  add = "install",
  rm = "remove",
  uninstall = "remove",
  ls = "list",
  up = "update",
  upgrade = "update",
  ["--help"] = "help",
  ["-h"] = "help",
}

--- Resolve a command name (following aliases) to its module.
---@param name string
---@return table|nil command, string|nil err
function cli.resolve(name)
  local resolved = cli.ALIASES[name] or name
  for _, entry in ipairs(cli.REGISTRY) do
    if entry.name == resolved then
      local command = require(entry.module)
      command.name = entry.name
      return command
    end
  end
  return nil, "unknown command: " .. name
end

--- Every command module, loaded. Used by `help`.
---@return table[]
function cli.all()
  local commands = {}
  for _, entry in ipairs(cli.REGISTRY) do
    local command = require(entry.module)
    command.name = entry.name
    commands[#commands + 1] = command
  end
  return commands
end

--- Entry point.
---@param raw string[]
---@return boolean ok
function cli.main(raw)
  local name = table.remove(raw, 1)
  if name == nil then
    name = "help"
  end
  if name == "version" or name == "--version" or name == "-v" then
    print("moonman " .. version)
    return true
  end

  local command, resolveErr = cli.resolve(name)
  if command == nil then
    printError(resolveErr)
    printError("Run \"moonman help\" for a list of commands.")
    return false
  end

  local ctx = context.new()
  local ok, err = command.run(ctx, raw)
  if not ok then
    if err then
      ctx.log.error("moonman: " .. err)
    end
    return false
  end
  return true
end

return cli
