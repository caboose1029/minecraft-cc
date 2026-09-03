--- Minimal flag parser for command arguments.
---
--- Supports "--flag", "--flag=value", and "--flag value". Anything that is not
--- a recognised flag becomes a positional argument.
local args = {}

--- Parse a raw argument list against a flag spec.
---@param raw string[]
---@param spec table<string, "boolean"|"string"> flag name -> kind
---@return table|nil positional, table|string flags_or_error
function args.parse(raw, spec)
  spec = spec or {}
  local positional, flags = {}, {}
  local index = 1

  while index <= #raw do
    local token = raw[index]
    local name, inlineValue = token:match("^%-%-([%w%-_]+)=(.*)$")
    if name == nil then
      name = token:match("^%-%-([%w%-_]+)$")
    end

    if name == nil then
      if token:sub(1, 2) == "--" then
        return nil, "malformed flag: " .. token
      end
      positional[#positional + 1] = token
    else
      local kind = spec[name]
      if kind == nil then
        return nil, "unknown flag: --" .. name
      end
      if kind == "boolean" then
        if inlineValue ~= nil then
          return nil, "--" .. name .. " does not take a value"
        end
        flags[name] = true
      else
        local value = inlineValue
        if value == nil then
          index = index + 1
          value = raw[index]
        end
        if value == nil or value == "" then
          return nil, "--" .. name .. " requires a value"
        end
        flags[name] = value
      end
    end
    index = index + 1
  end

  return positional, flags
end

return args
