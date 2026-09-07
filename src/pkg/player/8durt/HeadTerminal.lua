-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "HeadTerminal.kt", {["1-11"]=1,["12"]=35,["13"]=36,["14"]=37,["15"]=38,["16-17"]=39,["18"]=42,["19"]=43,["20"]=44,["21-22"]=45,["23"]=48,["24"]=49,["25-29"]=50,["30"]=56,["31-35"]=57,["36"]=62,["37"]=67,["38"]=68,["39"]=69,["40-43"]=70,["44"]=78,["45"]=79,["46-47"]=80,["48"]=82,["49"]=83,["50"]=84,["51-52"]=85,["53"]=87,["54"]=88,["55-61"]=89}, "programs")
ktox_require("lib/RoleCheck")
ktox_require("lib/Farm")
ktox_require("lib/Cli")
ktox_require("lib/Dashboard")
ktox_require("lib/PassiveFeeder")

local function main()
    println("Head terminal starting...")
    local hasModem = ktoxRednetOpenAny()
    if not hasModem then
        println("No modem found - attach one and reboot. A head terminal needs one to detect other heads and talk to secondaries.")
        return
    end
    local existingHead = queryForHead(2.0)
    if existingHead ~= -1 then
        println("Another head is already running (id " .. tostring(existingHead) .. ") - refusing to start. Only one head terminal is allowed on the network.")
        return
    end
    println("Head terminal ready. Use the touch dashboard (monitor if attached, otherwise this screen).")
    while true do
        parallel.waitForAny(function()
            return handleLocalInput()
        end, function()
            return handleRemoteMessage()
        end)
        topUpPassiveFeeders()
        manageFarms()
    end
end

function handleLocalInput()
    local commandLine = runDashboardLoop()
    showDashboardBusy("Working...")
    local result = runCliCommand(commandLine)
    println(result)
    showDashboardResult(result)
end

function handleRemoteMessage()
    local got = ktoxRednetReceiveAny(3600.0)
    if not got then
        return
    end
    local senderId = ktoxRednetLastSenderId()
    local protocol = ktoxRednetLastProtocol()
    if protocol == VAULT_ROLE_QUERY_PROTOCOL then
        rednet.send(senderId, "head", VAULT_ROLE_REPLY_PROTOCOL)
    elseif protocol == VAULT_CMD_PROTOCOL then
        local commandLine = ktoxRednetLastMessage()
        local result = runCliCommand(commandLine)
        rednet.send(senderId, result, VAULT_RESULT_PROTOCOL)
    end
end


-- Auto-generated call to main function
main()
