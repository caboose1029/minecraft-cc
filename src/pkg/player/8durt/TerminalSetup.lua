-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TerminalSetup.kt", {["1-8"]=1,["9"]=15,["10"]=16,["11-12"]=17,["13"]=19,["14"]=20,["15"]=21,["16-17"]=22,["18"]=25,["19"]=26,["20"]=27,["21"]=28,["22"]=29,["23-25"]=30,["26"]=34,["27"]=35,["28"]=36,["29-30"]=37,["31-33"]=40}, "programs")
ktox_require("lib/RoleCheck")

---@param args table
function main(args)
    if #(args) < 1 then
        println("Usage: terminalsetup <head|secondary>")
        return
    end
    local role = args[1]
    if role ~= "head" and role ~= "secondary" then
        println("Unknown role " .. "\"" .. tostring(role) .. "\"" .. " - expected " .. "\"" .. "head" .. "\"" .. " or " .. "\"" .. "secondary" .. "\"" .. ".")
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
    local wrote = ktoxWriteRoleFile(role)
    if not wrote then
        println("Failed to write role.txt.")
        return
    end
    println("Configured as " .. tostring(role) .. ". Reboot to start automatically, or run the " .. tostring(role) .. " program directly now.")
end


main({...})
