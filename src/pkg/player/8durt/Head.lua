-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Head.kt", {["1-8"]=1,["9"]=30,["10"]=31,["11"]=32,["12"]=33,["13-14"]=34,["15"]=37,["16"]=38,["17"]=39,["18-19"]=40,["20"]=43,["21"]=44,["22-30"]=45,["31"]=53,["32"]=54,["33-36"]=55,["37"]=63,["38"]=64,["39-40"]=65,["41"]=67,["42"]=68,["43"]=69,["44-45"]=70,["46"]=72,["47"]=73,["48-54"]=74}, "programs")
ktox_require("lib/RoleCheck")
ktox_require("lib/Cli")

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
