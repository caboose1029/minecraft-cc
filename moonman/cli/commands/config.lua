local configModule = require("moonman.app.config")
local args = require("moonman.cli.args")

return {
  summary = "Show or change moonman's settings",
  usage = {
    "moonman config",
    "moonman config get <key>",
    "moonman config set <key> <value>",
    "",
    "Keys: repo, ref, manifest_path",
    "Stored in " .. configModule.PATH .. ", outside the tree self-update replaces.",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, {})
    if positional == nil then
      return false, flags
    end
    local action = positional[1]

    if action == nil or action == "list" then
      for _, key in ipairs(configModule.KEYS) do
        ctx.log.field(key, ctx.config[key])
      end
      return true
    end

    local key = positional[2]
    if key == nil then
      return false, "config " .. action .. " requires a key"
    end
    local known = false
    for _, candidate in ipairs(configModule.KEYS) do
      known = known or candidate == key
    end
    if not known then
      return false, "unknown key \"" .. key .. "\" (valid: " .. table.concat(configModule.KEYS, ", ") .. ")"
    end

    if action == "get" then
      ctx.log.info(tostring(ctx.config[key]))
      return true
    end

    if action == "set" then
      local value = positional[3]
      if value == nil then
        return false, "config set requires a value"
      end
      ctx.config[key] = value
      local ok, err = configModule.save(ctx.ports, ctx.config)
      if not ok then
        return false, err
      end
      ctx.log.ok(key .. " = " .. value)
      return true
    end

    return false, "unknown action \"" .. action .. "\" (expected get, set, or list)"
  end,
}
