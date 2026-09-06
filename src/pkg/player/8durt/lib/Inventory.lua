-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=16,["10"]=17,["11-12"]=18,["13-20"]=20,["21"]=28,["22"]=29,["23-24"]=30,["25-33"]=32,["34"]=39,["35"]=40,["36-37"]=41,["38-42"]=43,["43"]=59,["44-46"]=60}, "lib")

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

---@return table
function listStoragePoolLines()
    local raw = ktoxInventoryListPooled(ktoxConfigStorageVaultNames())
    return ktox_split(raw, "\n")
end

