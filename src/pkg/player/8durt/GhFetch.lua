-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "GhFetch.kt", {["1-9"]=1,["10"]=25,["11"]=26,["12"]=27,["13"]=29,["14"]=30,["15"]=31,["16"]=32,["17-18"]=33,["19"]=41,["20"]=69,["21"]=70,["22"]=71,["23"]=72,["24"]=73,["25"]=74,["26"]=75,["27"]=76,["28-29"]=77,["30"]=79,["31-32"]=80,["33-34"]=82,["35"]=85,["36-37"]=86,["38-41"]=88}, "programs")

DEFAULT_BRANCH = "feat/ktox-lua-storage"

---@param args table
function main(args)
    local branch = (#(args) >= 1 and args[1] or DEFAULT_BRANCH)
    local repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/" .. tostring(branch) .. "/src/pkg/player/8durt"
    println("Fetching from branch: " .. tostring(branch))
    local dirs = {"lib", "common", "config"}
    local d = 1
    while d <= #(dirs) do
        fs.makeDir(dirs[d])
        d = ktox_plusAssign(d, 1)
    end
    local files = {"ktox-lib.lua", "ktox-cc-shim.lua", "startup.lua", "lib/Movement.lua", "lib/Position.lua", "lib/Span.lua", "lib/Chest.lua", "lib/Shape.lua", "lib/Redstone.lua", "lib/Inventory.lua", "lib/Config.lua", "lib/Executor.lua", "lib/Cli.lua", "common/Monitor.lua", "common/Peripheral.lua", "config/peripherals.example.json", "config/job-types.example.json", "config/resource-tree.example.json", "Digsite.lua", "ExcavatePro.lua", "DiamondFinder.lua", "TestMonitor.lua", "TestConfig.lua", "Terminal.lua", "GhFetch.lua"}
    local i = 1
    local failures = 0
    while i <= #(files) do
        local path = files[i]
        local url = tostring(repoBase) .. "/" .. tostring(path)
        println("Fetching " .. tostring(path) .. "...")
        local ok = ktoxDownloadFile(url, path)
        if ok then
            println("  ok")
        else
            println("  FAILED: " .. tostring(path))
            failures = ktox_plusAssign(failures, 1)
        end
        i = ktox_plusAssign(i, 1)
    end
    if failures > 0 then
        println(tostring(failures) .. " file(s) failed.")
    else
        println("Fetched " .. tostring(#(files)) .. " file(s).")
    end
end


main({...})
