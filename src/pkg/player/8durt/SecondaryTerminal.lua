-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "SecondaryTerminal.kt", {["1-10"]=1,["11"]=36,["12"]=37,["13"]=38,["14"]=39,["15-16"]=40,["17"]=43,["18"]=44,["19"]=45,["20"]=46,["21"]=47,["22"]=48,["23"]=49,["24-25"]=50,["26"]=52,["27"]=53,["28"]=54,["29"]=55,["30"]=56,["31-32"]=57,["33"]=59,["34"]=60,["35-43"]=61}, "programs")
ktox_require("lib/RoleCheck")
ktox_require("lib/Dashboard")

CRAFTER_RESULT_TIMEOUT_SECONDS = 300.0

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
            showDashboardBusy("Working...")
            local got = ktoxRednetReceiveProtocol(VAULT_RESULT_PROTOCOL, CRAFTER_RESULT_TIMEOUT_SECONDS)
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
