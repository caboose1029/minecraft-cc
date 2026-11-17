local web = {}

function web.download(url)
  local response, err = http.get(url)
  if response == nil then
    return nil, err
  end
  local body = response.readAll()
  response.close()
  if body == nil then
    return nil, "read response"
  end
  return body
end

return web
