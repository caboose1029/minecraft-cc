-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "HeadTerminal.kt", {["1-12"]=1,["13"]=36,["14"]=37,["15"]=38,["16"]=39,["17-18"]=40,["19"]=43,["20"]=44,["21"]=45,["22-23"]=46,["24"]=49,["25"]=50,["26-30"]=51,["31"]=57,["32"]=58,["33-37"]=59,["38"]=64,["39"]=69,["40"]=70,["41"]=71,["42-45"]=72,["46"]=80,["47"]=81,["48-49"]=82,["50"]=84,["51"]=85,["52"]=86,["53-54"]=87,["55"]=89,["56"]=90,["57-63"]=91}, "programs")
ktox_require("lib/RoleCheck")
ktox_require("lib/DepositChest")
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
        drainDepositChests()
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
