-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Crafter.kt", {["1-8"]=1,["9"]=42,["10"]=43,["11-12"]=44,["13"]=46,["14"]=48,["15"]=49,["16"]=50,["17"]=51,["18-19"]=52,["20"]=55,["21"]=56,["22-27"]=57,["28"]=65,["29"]=66,["30-31"]=67,["32"]=69,["33"]=70,["34"]=71,["35-36"]=72,["37"]=79,["38"]=80,["39"]=81,["40"]=82,["41-42"]=83,["43"]=84,["44"]=85,["45"]=103,["46"]=104,["47"]=105,["48-55"]=106,["56"]=112,["57"]=113,["58"]=114,["59-60"]=115,["61-62"]=117,["63-66"]=119,["67"]=129,["68"]=130,["69"]=131,["70"]=132,["71-72"]=133,["73-76"]=135}, "programs")
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
    elseif protocol == VAULT_CRAFTER_SUCK_PROTOCOL then
        local parts = ktox_split(ktoxRednetLastMessage(), ",")
        local slot = ktox_toInt(ktox_toDouble(parts[1]))
        local count = ktox_toInt(ktox_toDouble(parts[2]))
        turtle.select(slot)
        turtle.suckUp(count)
    else
        if protocol == VAULT_CRAFTER_CMD_PROTOCOL then
            local quantity = ktox_toInt(ktox_toDouble(ktoxRednetLastMessage()))
            dumpAllForward()
            if isInventoryEmpty() then
                turtle.craft(quantity)
                dumpAllForward()
            end
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
