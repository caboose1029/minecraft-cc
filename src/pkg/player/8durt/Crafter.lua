-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Crafter.kt", {["1-8"]=1,["9"]=32,["10"]=33,["11-12"]=34,["13"]=36,["14"]=38,["15"]=39,["16"]=40,["17"]=41,["18-19"]=42,["20"]=45,["21"]=46,["22-27"]=47,["28"]=55,["29"]=56,["30-31"]=57,["32"]=59,["33"]=60,["34"]=61,["35-36"]=62,["37"]=64,["38"]=82,["39"]=83,["40"]=84,["41-47"]=85,["48"]=91,["49"]=92,["50"]=93,["51-52"]=94,["53-54"]=96,["55-58"]=98,["59"]=108,["60"]=109,["61"]=110,["62"]=111,["63-64"]=112,["65-68"]=114}, "programs")
ktox_require("lib/RoleCheck")

---@param args table
function main(args)
    if #(args) < 1 then
        println("Usage: crafter <jobType>")
        return
    end
    local jobType = args[1]
    println("Crafter starting (job: " .. tostring(jobType) .. ")...")
    local hasModem = ktoxRednetOpenAny()
    if not hasModem then
        println("No modem found - attach one and reboot.")
        return
    end
    println("Crafter ready, waiting for commands.")
    while true do
        handleOneMessage(jobType)
    end
end

---@param jobType string
function handleOneMessage(jobType)
    local got = ktoxRednetReceiveAny(3600.0)
    if not got then
        return
    end
    local senderId = ktoxRednetLastSenderId()
    local protocol = ktoxRednetLastProtocol()
    if protocol == VAULT_CRAFTER_QUERY_PROTOCOL and ktoxRednetLastMessage() == jobType then
        rednet.send(senderId, jobType, VAULT_CRAFTER_REPLY_PROTOCOL)
    elseif protocol == VAULT_CRAFTER_CMD_PROTOCOL then
        local quantity = ktox_toInt(ktox_toDouble(ktoxRednetLastMessage()))
        dumpAllForward()
        if isInventoryEmpty() then
            turtle.craft(quantity)
            dumpAllForward()
        end
    end
end

---@return boolean
function isInventoryEmpty()
    local slot = 1
    while slot <= 16 do
        if turtle.getItemCount(slot) > 0 then
            return false
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return true
end

function dumpAllForward()
    local slot = 1
    while slot <= 16 do
        turtle.select(slot)
        if turtle.getItemCount(slot) > 0 then
            turtle.drop(64)
        end
        slot = ktox_plusAssign(slot, 1)
    end
end


main({...})
