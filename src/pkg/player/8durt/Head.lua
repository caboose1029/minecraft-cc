-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Head.kt", {["1-9"]=1,["10"]=31,["11"]=32,["12"]=33,["13"]=34,["14-15"]=35,["16"]=38,["17"]=39,["18"]=40,["19-20"]=41,["21"]=44,["22"]=45,["23-27"]=46,["28-32"]=52,["33"]=57,["34"]=58,["35-38"]=59,["39"]=67,["40"]=68,["41-42"]=69,["43"]=71,["44"]=72,["45"]=73,["46-47"]=74,["48"]=76,["49"]=77,["50-56"]=78}, "programs")
ktox_require("lib/RoleCheck")
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
