-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "GhFetch.kt", {["1-9"]=1,["10"]=25,["11"]=26,["12"]=27,["13"]=29,["14"]=30,["15"]=31,["16"]=32,["17-18"]=33,["19"]=41,["20"]=58,["21"]=59,["22"]=60,["23"]=61,["24"]=62,["25"]=63,["26"]=64,["27"]=65,["28-29"]=66,["30"]=68,["31-32"]=69,["33-34"]=71,["35"]=74,["36-37"]=75,["38-41"]=77}, "programs")

DEFAULT_BRANCH = "feat/ktox-lua-storage"

---@param args table
function main(args)
    local branch = (#(args) >= 1 and args[1] or DEFAULT_BRANCH)
    local repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/" .. tostring(branch) .. "/src/pkg/player/8durt"
    println("Fetching from branch: " .. tostring(branch))
    local dirs = {"lib", "common"}
    local d = 1
    while d <= #(dirs) do
        fs.makeDir(dirs[d])
        d = ktox_plusAssign(d, 1)
    end
    local files = {"ktox-lib.lua", "ktox-cc-shim.lua", "startup.lua", "lib/Movement.lua", "lib/Position.lua", "lib/Span.lua", "lib/Chest.lua", "lib/Shape.lua", "common/Monitor.lua", "Digsite.lua", "ExcavatePro.lua", "DiamondFinder.lua", "TestMonitor.lua", "GhFetch.lua"}
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
