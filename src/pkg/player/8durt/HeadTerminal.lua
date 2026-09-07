-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "HeadTerminal.kt", {["1-11"]=1,["12"]=34,["13"]=35,["14"]=36,["15"]=37,["16-17"]=38,["18"]=41,["19"]=42,["20"]=43,["21-22"]=44,["23"]=47,["24"]=48,["25-29"]=49,["30"]=55,["31-35"]=56,["36"]=61,["37"]=62,["38"]=63,["39-42"]=64,["43"]=72,["44"]=73,["45-46"]=74,["47"]=76,["48"]=77,["49"]=78,["50-51"]=79,["52"]=81,["53"]=82,["54-60"]=83}, "programs")
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
