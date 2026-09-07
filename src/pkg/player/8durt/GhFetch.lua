-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "GhFetch.kt", {["1-11"]=1,["12"]=32,["13"]=33,["14"]=34,["15"]=36,["16"]=37,["17"]=38,["18"]=39,["19-20"]=40,["21"]=46,["22"]=50,["23"]=52,["24"]=53,["25"]=54,["26"]=55,["27"]=56,["28"]=57,["29"]=62,["30"]=63,["31-32"]=64,["33"]=66,["34"]=67,["35"]=68,["36"]=69,["37"]=70,["38-39"]=71,["40"]=73,["41-43"]=74,["44-45"]=77,["46"]=80,["47-48"]=81,["49-52"]=83}, "programs")

DEFAULT_BRANCH = "feat/ktox-lua-storage"

FILES_MANIFEST = "files.manifest"

---@param args table
function main(args)
    local branch = (#(args) >= 1 and args[1] or DEFAULT_BRANCH)
    local repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/" .. tostring(branch) .. "/src/pkg/player/8durt"
    println("Fetching from branch: " .. tostring(branch))
    local manifestUrl = tostring(repoBase) .. "/" .. tostring(FILES_MANIFEST)
    local manifestText = ktoxDownloadFileText(manifestUrl)
    if manifestText == "MISSING" then
        println("Could not fetch the file manifest (" .. tostring(FILES_MANIFEST) .. ") - aborting.")
        return
    end
    ktoxDownloadFile(manifestUrl, FILES_MANIFEST)
    local files = ktox_split(manifestText, "\n")
    local i = 1
    local failures = 0
    local fetched = 0
    while i <= #(files) do
        local path = files[i]
        if path ~= "" then
            local pathParts = ktox_split(path, "/")
            if #(pathParts) >= 2 then
                fs.makeDir(pathParts[1])
            end
            local url = tostring(repoBase) .. "/" .. tostring(path)
            println("Fetching " .. tostring(path) .. "...")
            local ok = ktoxDownloadFile(url, path)
            if ok then
                println("  ok")
                fetched = ktox_plusAssign(fetched, 1)
            else
                println("  FAILED: " .. tostring(path))
                failures = ktox_plusAssign(failures, 1)
            end
        end
        i = ktox_plusAssign(i, 1)
    end
    if failures > 0 then
        println(tostring(failures) .. " file(s) failed.")
    else
        println("Fetched " .. tostring(fetched) .. " file(s).")
    end
end


main({...})
