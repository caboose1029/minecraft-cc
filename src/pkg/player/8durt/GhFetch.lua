-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "GhFetch.kt", {["1-9"]=1,["10"]=24,["11"]=25,["12"]=26,["13"]=28,["14"]=29,["15"]=30,["16"]=31,["17-18"]=32,["19"]=40,["20"]=55,["21"]=56,["22"]=57,["23"]=58,["24"]=59,["25"]=60,["26"]=61,["27"]=62,["28-29"]=63,["30"]=65,["31-32"]=66,["33-34"]=68,["35"]=71,["36-37"]=72,["38-41"]=74}, "programs")

DEFAULT_BRANCH = "feat/add-ktox-lua-cc"

---@param args table
function main(args)
    local branch = (#(args) >= 1 and args[1] or DEFAULT_BRANCH)
    local repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/" .. tostring(branch) .. "/src/pkg/player/8durt"
    println("Fetching from branch: " .. tostring(branch))
    local dirs = {"lib"}
    local d = 1
    while d <= #(dirs) do
        fs.makeDir(dirs[d])
        d = ktox_plusAssign(d, 1)
    end
    local files = {"ktox-lib.lua", "ktox-cc-shim.lua", "startup.lua", "lib/Movement.lua", "lib/Position.lua", "lib/Span.lua", "lib/Chest.lua", "lib/Shape.lua", "Digsite.lua", "ExcavatePro.lua", "DiamondFinder.lua", "GhFetch.lua"}
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
