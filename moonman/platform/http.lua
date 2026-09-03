--- HTTP adapter over CC's http API.
local http_port = {}

--- GET a URL and return its body.
--- Sends no-cache headers because raw.githubusercontent.com will otherwise
--- serve a stale manifest for several minutes after a push.
---@param url string
---@return string|nil body, string|nil err
function http_port.get(url)
  if http == nil then
    return nil, "the http API is disabled on this computer"
  end
  local response, err = http.get(url, { ["Cache-Control"] = "no-cache", ["Pragma"] = "no-cache" })
  if response == nil then
    return nil, (err or "request failed") .. " (" .. url .. ")"
  end
  local body = response.readAll()
  response.close()
  if body == nil then
    return nil, "empty response from " .. url
  end
  return body
end

return http_port
