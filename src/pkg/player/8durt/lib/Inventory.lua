-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=18,["10"]=19,["11-12"]=20,["13-20"]=22,["21"]=30,["22"]=31,["23-24"]=32,["25-33"]=34,["34"]=41,["35"]=42,["36-37"]=43,["38-45"]=45,["46"]=58,["47"]=59,["48-49"]=60,["50-58"]=62,["59"]=68,["60"]=69,["61-62"]=70,["63-67"]=72,["68"]=88,["69-71"]=89}, "lib")

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

---@param toName string
---@param toSlot number
---@param itemName string
---@param desired number
---@return number
function pushToStoragePoolTargetSlot(toName, toSlot, itemName, desired)
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return 0
    end
    return ktoxInventoryPushNamedToSlotFromPool(vaultNames, toName, toSlot, itemName, desired)
end

---@return table
function listStoragePoolLines()
    local raw = ktoxInventoryListPooled(ktoxConfigStorageVaultNames())
    return ktox_split(raw, "\n")
end

