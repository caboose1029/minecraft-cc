-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "GhFetch.kt", {["1-8"]=1,["9"]=22,["10"]=23,["11"]=24,["12"]=25,["13-14"]=26,["15"]=29,["16"]=41,["17"]=42,["18"]=43,["19"]=44,["20"]=45,["21"]=46,["22"]=47,["23"]=48,["24-25"]=49,["26"]=51,["27-28"]=52,["29-30"]=54,["31"]=57,["32-33"]=58,["34-40"]=60}, "programs")

REPO_BASE = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/feat/add-ktox-lua-cc/src/pkg/player/8durt"

local function main()
    local dirs = {"lib"}
    local d = 1
    while d <= #(dirs) do
        fs.makeDir(dirs[d])
        d = ktox_plusAssign(d, 1)
    end
    local files = {"ktox-lib.lua", "ktox-cc-shim.lua", "startup.lua", "lib/Movement.lua", "lib/Position.lua", "lib/Span.lua", "Digsite.lua", "ExcavatePro.lua", "GhFetch.lua"}
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
