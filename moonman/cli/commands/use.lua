local configModule = require("moonman.app.config")
local selfupdate = require("moonman.app.selfupdate")
local args = require("moonman.cli.args")

return {
  summary = "Switch to a different branch, tag, or commit",
  usage = {
    "moonman use <ref> [--repo <owner/name>]",
    "",
    "Points moonman at another ref of the monorepo and pulls its own files from",
    "there. Installed packages stay on their old ref until you run",
    "\"moonman update\".",
    "",
    "  moonman use main",
    "  moonman use feat/add-ktox-lua-cc",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, { repo = "string" })
    if positional == nil then
      return false, flags
    end
    local ref = positional[1]
    if ref == nil then
      return false, "use requires a ref (branch, tag, or commit)"
    end

    ctx.config.ref = ref
    if flags.repo then
      ctx.config.repo = flags.repo
    end

    -- Verify the ref resolves before committing it to disk.
    ctx._manifest = nil
    local mf, err = ctx:manifest()
    if mf == nil then
      return false, "cannot switch to " .. ctx:origin() .. ": " .. err
    end

    local saved, saveErr = configModule.save(ctx.ports, ctx.config)
    if not saved then
      return false, saveErr
    end

    local ok, updateErr = selfupdate.run(ctx)
    if not ok then
      return false, updateErr
    end
    ctx.log.info("Now tracking " .. ctx:origin() .. ".")
    ctx.log.info("Run \"moonman update\" to move installed packages onto it.")
    return true
  end,
}
