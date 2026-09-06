-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TerminalSetup.kt", {["1-8"]=1,["9"]=18,["10"]=19,["11-12"]=20,["13"]=22,["14"]=23,["15"]=24,["16-17"]=25,["18"]=28,["19"]=29,["20"]=30,["21"]=31,["22"]=32,["23-25"]=33,["26"]=37,["27"]=38,["28"]=39,["29-30"]=40,["31"]=42,["32"]=43,["33"]=44,["34"]=45,["35-36"]=46,["37"]=48,["38-39"]=49,["40"]=52,["41"]=53,["42"]=54,["43-44"]=55,["45-47"]=58}, "programs")
ktox_require("lib/RoleCheck")

---@param args table
function main(args)
    if #(args) < 1 then
        println("Usage: terminalsetup <head|secondary|crafter> (jobType)")
        return
    end
    local role = args[1]
    if role ~= "head" and role ~= "secondary" and role ~= "crafter" then
        println("Unknown role " .. "\"" .. tostring(role) .. "\"" .. " - expected " .. "\"" .. "head" .. "\"" .. ", " .. "\"" .. "secondary" .. "\"" .. ", or " .. "\"" .. "crafter" .. "\"" .. ".")
        return
    end
    if role == "head" then
        println("Checking for an existing head on the network...")
        local existingHead = queryForHead(2.0)
        if existingHead ~= -1 then
            println("Another head is already running (id " .. tostring(existingHead) .. ") - refusing to configure this machine as a second head. Only one head terminal is allowed on the network.")
            return
        end
    end
    if role == "crafter" then
        if #(args) < 2 then
            println("Usage: terminalsetup crafter <jobType>")
            return
        end
        local jobType = args[2]
        local wrote = ktoxWriteRoleFile("crafter:" .. tostring(jobType))
        if not wrote then
            println("Failed to write role.txt.")
            return
        end
        println("Configured as crafter for job " .. "\"" .. tostring(jobType) .. "\"" .. ". Reboot to start automatically, or run \'crafter " .. tostring(jobType) .. "\' directly now.")
        return
    end
    local wrote = ktoxWriteRoleFile(role)
    if not wrote then
        println("Failed to write role.txt.")
        return
    end
    println("Configured as " .. tostring(role) .. ". Reboot to start automatically, or run the " .. tostring(role) .. " program directly now.")
end


main({...})
