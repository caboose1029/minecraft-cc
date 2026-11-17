local disk = {}

function writeFile(path, contents)
  local file = fs.open(path, "w")
  if file == nil then
    return false, "open file: " .. path
  end
  file.write(contents)
  file.close()
  return true
end

return disk
