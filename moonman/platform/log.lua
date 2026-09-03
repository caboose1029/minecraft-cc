--- Terminal output adapter.
---
--- Every user-facing message goes through here so commands stay free of
--- formatting concerns and so output can be silenced or captured in tests.
local log = {}

local function colour(c, fn)
  local supported = term ~= nil and term.isColour ~= nil and term.isColour()
  if supported then
    term.setTextColour(c)
  end
  fn()
  if supported then
    term.setTextColour(colours.white)
  end
end

function log.info(message)
  print(message)
end

function log.detail(message)
  colour(colours and colours.lightGrey, function()
    print("  " .. message)
  end)
end

function log.ok(message)
  colour(colours and colours.lime, function()
    print(message)
  end)
end

function log.warn(message)
  colour(colours and colours.yellow, function()
    print(message)
  end)
end

function log.error(message)
  printError(message)
end

--- A key/value line used by `info` and `config`.
function log.field(label, value)
  colour(colours and colours.lightGrey, function()
    write(label .. ": ")
  end)
  print(tostring(value))
end

return log
