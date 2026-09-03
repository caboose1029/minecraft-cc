local args = require("moonman.cli.args")

return {
  summary = "Search available packages by name or description",
  usage = {
    "moonman search <query>",
  },
  run = function(ctx, argv)
    local positional, flags = args.parse(argv, {})
    if positional == nil then
      return false, flags
    end
    local query = positional[1]
    if query == nil then
      return false, "search requires a query"
    end

    local mf, err = ctx:manifest()
    if mf == nil then
      return false, err
    end
    local matches = mf:search(query)
    if #matches == 0 then
      ctx.log.info("No packages match \"" .. query .. "\".")
      return true
    end
    for _, name in ipairs(matches) do
      local pkg = mf:getPackage(name)
      ctx.log.detail(name .. (pkg.description and ("  -- " .. pkg.description) or ""))
    end
    return true
  end,
}
