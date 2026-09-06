-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Secondary.kt", {["1-7"]=1,["8"]=22,["9"]=23,["10"]=24,["11"]=25,["12-13"]=26,["14"]=29,["15"]=30,["16"]=31,["17"]=32,["18"]=33,["19"]=34,["20-21"]=35,["22"]=37,["23"]=38,["24-25"]=39,["26-34"]=41}, "programs")
ktox_require("lib/RoleCheck")

local function main()
    println("Secondary terminal starting...")
    local headId = queryForHead(2.0)
    if headId == -1 then
        println("No head terminal found on the network. Make sure exactly one head is running, then reboot this secondary.")
        return
    end
    println("Secondary terminal ready (head id " .. tostring(headId) .. "). Commands: list, pull, craft, trash.")
    while true do
        term.write("> ")
        local commandLine = read()
        local sent = rednet.send(headId, commandLine, VAULT_CMD_PROTOCOL)
        if not sent then
            println("Failed to reach the head terminal.")
        else
            local got = ktoxRednetReceiveProtocol(VAULT_RESULT_PROTOCOL, 30.0)
            if got then
                println(ktoxRednetLastMessage())
            else
                println("No response from the head terminal (timed out).")
            end
        end
    end
end


-- Auto-generated call to main function
main()
