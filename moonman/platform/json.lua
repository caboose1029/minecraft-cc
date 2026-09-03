--- JSON adapter over CC's textutils.
local json = {}

---@param text string
---@return table|nil value, string|nil err
function json.decode(text)
  local value, err = textutils.unserialiseJSON(text)
  if value == nil then
    return nil, "invalid JSON: " .. tostring(err)
  end
  return value
end

---@param value table
---@return string
function json.encode(value)
  return textutils.serialiseJSON(value)
end

return json
