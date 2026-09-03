--- moonman entry point.
---
--- Installed to /moonman.lua so that CC's require() resolves this program's
--- directory to /, which makes require("moonman.<module>") find the library
--- tree at /moonman/. The same string resolves in the repository, where this
--- file lives at moonman/main.lua alongside moonman/<module>.lua.
local ok, cli = pcall(require, "moonman.cli")
if not ok then
  printError("moonman: the library tree at /moonman is missing or broken.")
  printError(tostring(cli))
  printError("Re-run the bootstrap script to reinstall it.")
  return
end

return cli.main({ ... })
