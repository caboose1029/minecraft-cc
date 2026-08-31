-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "GhFetch.kt", {["1-8"]=1,["9"]=22,["10"]=23,["11"]=24,["12"]=25,["13-14"]=26,["15"]=29,["16"]=38,["17"]=39,["18"]=40,["19"]=41,["20"]=42,["21"]=43,["22"]=44,["23"]=45,["24-25"]=46,["26"]=48,["27-28"]=49,["29-30"]=51,["31"]=54,["32-33"]=55,["34-40"]=57}, "programs")

REPO_BASE = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/feat/add-ktox-lua-cc/src/pkg/player/8durt"

local function main()
    local dirs = {"lib"}
    local d = 1
    while d <= #(dirs) do
        fs.makeDir(dirs[d])
        d = ktox_plusAssign(d, 1)
    end
    local files = {"ktox-lib.lua", "ktox-cc-shim.lua", "startup.lua", "lib/Movement.lua", "lib/Position.lua", "Digsite.lua"}
    local i = 1
    local failures = 0
    while i <= #(files) do
        local path = files[i]
        local url = tostring(REPO_BASE) .. "/" .. tostring(path)
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


-- Auto-generated call to main function
main()
