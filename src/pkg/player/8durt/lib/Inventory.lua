-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=17,["10"]=18,["11-12"]=19,["13-20"]=21,["21"]=29,["22"]=30,["23-24"]=31,["25-33"]=33,["34"]=40,["35"]=41,["36-37"]=42,["38-45"]=44,["46"]=65,["47"]=66,["48-49"]=67,["50-54"]=69,["55"]=85,["56-58"]=86}, "lib")

---@param itemName string
---@return number
function storagePoolCount(itemName)
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return 0
    end
    return ktoxInventoryCountNamed(vaultNames, itemName)
end

---@param toName string
---@param itemName string
---@param desired number
---@return number
function pullFromStoragePool(toName, itemName, desired)
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return 0
    end
    return ktoxInventoryPullNamedFromPool(toName, vaultNames, itemName, desired)
end

---@param toName string
---@param toSlot number
---@param itemName string
---@param desired number
---@return number
function pullFromStoragePoolToSlot(toName, toSlot, itemName, desired)
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return 0
    end
    return ktoxInventoryPullNamedToSlotFromPool(toName, toSlot, vaultNames, itemName, desired)
end

---@param toName string
---@param itemName string
---@param desired number
---@return number
function pushToStoragePoolTarget(toName, itemName, desired)
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return 0
    end
    return ktoxInventoryPushNamedFromPool(vaultNames, toName, itemName, desired)
end

---@return table
function listStoragePoolLines()
    local raw = ktoxInventoryListPooled(ktoxConfigStorageVaultNames())
    return ktox_split(raw, "\n")
end

