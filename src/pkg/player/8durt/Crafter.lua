-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Crafter.kt", {["1-10"]=1,["11"]=61,["12-13"]=62,["14"]=64,["15-16"]=65,["17"]=67,["18-19"]=68,["20"]=70,["21-22"]=71,["23"]=73,["24-25"]=74,["26"]=76,["27-28"]=77,["29-33"]=79,["34"]=83,["35"]=84,["36-37"]=85,["38"]=87,["39"]=89,["40"]=90,["41"]=91,["42"]=92,["43-44"]=93,["45"]=96,["46"]=97,["47-52"]=98,["53"]=106,["54"]=107,["55-56"]=108,["57"]=110,["58"]=111,["59"]=112,["60-61"]=113,["62"]=115,["63"]=116,["64"]=117,["65-71"]=118,["72"]=127,["73-79"]=128,["80"]=132,["81"]=133,["82"]=134,["83-84"]=135,["85"]=138,["86"]=139,["87"]=140,["88-89"]=141,["90"]=144,["91"]=145,["92"]=146,["93"]=147,["94"]=148,["95"]=149,["96"]=150,["97"]=151,["98"]=152,["99"]=153,["100"]=154,["101-103"]=155,["104-105"]=158,["106"]=161,["107"]=162,["108"]=163,["109"]=164,["110-111"]=165,["112-122"]=168,["123"]=178,["124"]=179,["125"]=180,["126"]=181,["127"]=182,["128"]=183,["129"]=184,["130"]=185,["131-132"]=186,["133"]=188,["134"]=189,["135"]=190,["136"]=191,["137-139"]=192,["140-141"]=195,["142-148"]=197,["149"]=205,["150"]=206,["151"]=207,["152"]=208,["153"]=209,["154"]=210,["155"]=211,["156-158"]=212,["159-163"]=215,["164"]=219,["165"]=220,["166"]=221,["167-168"]=222,["169-170"]=224,["171-174"]=226,["175"]=233,["176"]=234,["177"]=235,["178"]=236,["179-180"]=237,["181-184"]=239}, "programs")
ktox_require("lib/Config")
ktox_require("lib/RoleCheck")

---@param index number
---@return number
function stagingSlotAt(index)
    if index == 1 then
        return 4
    end
    if index == 2 then
        return 8
    end
    if index == 3 then
        return 12
    end
    if index == 4 then
        return 13
    end
    if index == 5 then
        return 14
    end
    if index == 6 then
        return 15
    end
    return 16
end

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
        local parts = ktox_split(ktoxRednetLastMessage(), ",")
        local outputItemName = parts[1]
        local batches = ktox_toInt(ktox_toDouble(parts[2]))
        runCraftTask(senderId, outputItemName, batches)
    end
end

---@param headId number
---@param reason string
function reportFailure(headId, reason)
    println("FAILURE: " .. tostring(reason))
    rednet.send(headId, reason, VAULT_CRAFTER_FAILURE_PROTOCOL)
end

---@param headId number
---@param outputItemName string
---@param batches number
function runCraftTask(headId, outputItemName, batches)
    dumpAllDown()
    if not isInventoryEmpty() then
        reportFailure(headId, "Crafter\'s inventory wasn\'t empty at the start of a job (dropDown didn\'t clear it) - check the chest below isn\'t full or missing.")
        return
    end
    local recipe = findRecipe(outputItemName)
    if recipe == nil then
        reportFailure(headId, "Crafter has no known recipe for " .. tostring(outputItemName) .. ".")
        return
    end
    local inputCount = recipeInputCount(recipe)
    local stagingIndex = 0
    local i = 1
    while i <= inputCount do
        if isFirstInputOccurrence(recipe, i) then
            stagingIndex = ktox_plusAssign(stagingIndex, 1)
            local itemName = recipeInputItem(recipe, i)
            local stagingSlot = stagingSlotAt(stagingIndex)
            local ok = stageAndDistribute(headId, recipe, itemName, stagingSlot, batches, inputCount)
            if not ok then
                dumpAllDown()
                return
            end
        end
        i = ktox_plusAssign(i, 1)
    end
    local crafted = turtle.craft(batches)
    if not crafted then
        reportFailure(headId, "turtle.craft() failed for " .. tostring(outputItemName) .. " - ingredients may not have matched the expected shape.")
        dumpAllDown()
        return
    end
    dumpAllDown()
end

---@param headId number
---@param recipe Recipe
---@param itemName string
---@param stagingSlot number
---@param batches number
---@param inputCount number
---@return boolean
function stageAndDistribute(headId, recipe, itemName, stagingSlot, batches, inputCount)
    local j = 1
    while j <= inputCount do
        if recipeInputItem(recipe, j) == itemName then
            local targetSlot = recipeInputSlot(recipe, j)
            local needed = recipeInputCountAt(recipe, j) * batches
            local gathered = gatherInto(stagingSlot, needed)
            if gathered < needed then
                reportFailure(headId, "suckUp only retrieved " .. tostring(gathered) .. " of " .. tostring(needed) .. " needed " .. tostring(itemName) .. " from the chest above.")
                return false
            end
            turtle.select(stagingSlot)
            local moved = turtle.transferTo(targetSlot, needed)
            if not moved then
                reportFailure(headId, "Couldn\'t move " .. tostring(itemName) .. " from the staging slot into crafting-grid slot " .. tostring(targetSlot) .. ".")
                return false
            end
        end
        j = ktox_plusAssign(j, 1)
    end
    return true
end

---@param stagingSlot number
---@param needed number
---@return number
function gatherInto(stagingSlot, needed)
    turtle.select(stagingSlot)
    local gathered = turtle.getItemCount(stagingSlot)
    while gathered < needed do
        local before = gathered
        turtle.suckUp(needed - gathered)
        gathered = turtle.getItemCount(stagingSlot)
        if gathered <= before then
            return gathered
        end
    end
    return gathered
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

function dumpAllDown()
    local slot = 1
    while slot <= 16 do
        turtle.select(slot)
        if turtle.getItemCount(slot) > 0 then
            turtle.dropDown(64)
        end
        slot = ktox_plusAssign(slot, 1)
    end
end


main({...})
