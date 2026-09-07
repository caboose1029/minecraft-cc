-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "SecondaryTerminal.kt", {["1-8"]=1,["9"]=25,["10"]=26,["11"]=27,["12"]=28,["13-14"]=29,["15"]=32,["16"]=33,["17"]=34,["18"]=35,["19"]=36,["20"]=37,["21"]=38,["22-23"]=39,["24"]=41,["25"]=42,["26"]=43,["27"]=44,["28-29"]=45,["30"]=47,["31"]=48,["32-40"]=49}, "programs")
ktox_require("lib/RoleCheck")
ktox_require("lib/Dashboard")

local function main()
    println("Secondary terminal starting...")
    local headId = queryForHead(2.0)
    if headId == -1 then
        println("No head terminal found on the network. Make sure exactly one head is running, then reboot this secondary.")
        return
    end
    println("Secondary terminal ready (head id " .. tostring(headId) .. "). Use the touch dashboard.")
    while true do
        local commandLine = runDashboardLoop()
        local sent = rednet.send(headId, commandLine, VAULT_CMD_PROTOCOL)
        if not sent then
            local message = "Failed to reach the head terminal."
            println(message)
            showDashboardResult(message)
        else
            local got = ktoxRednetReceiveProtocol(VAULT_RESULT_PROTOCOL, 30.0)
            if got then
                local message = ktoxRednetLastMessage()
                println(message)
                showDashboardResult(message)
            else
                local message = "No response from the head terminal (timed out)."
                println(message)
                showDashboardResult(message)
            end
        end
    end
end


-- Auto-generated call to main function
main()
