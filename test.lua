local path = "./dist/manifest.json"

local file = fs.open(path, "r")
if file == nil then
  printError("open file")
end

body, err = file.readAll()
if body == nil {
  printError("read file")
}
