-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "HeadTerminal.kt", {["1-10"]=1,["11"]=32,["12"]=33,["13"]=34,["14"]=35,["15-16"]=36,["17"]=39,["18"]=40,["19"]=41,["20-21"]=42,["22"]=45,["23"]=46,["24-28"]=47,["29"]=53,["30-34"]=54,["35"]=59,["36"]=60,["37-40"]=61,["41"]=69,["42"]=70,["43-44"]=71,["45"]=73,["46"]=74,["47"]=75,["48-49"]=76,["50"]=78,["51"]=79,["52-58"]=80}, "programs")
ktox_require("lib/RoleCheck")
ktox_require("lib/Farm")
ktox_require("lib/Cli")
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
    println("Head terminal ready. Commands: list, pull, craft, trash.")
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
    term.write("> ")
    local commandLine = read()
    println(runCliCommand(commandLine))
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
