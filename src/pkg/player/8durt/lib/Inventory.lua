-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=15,["10"]=16,["11-12"]=17,["13-20"]=19,["21"]=27,["22"]=28,["23-24"]=29,["25-29"]=31,["30"]=47,["31-33"]=48}, "lib")

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

---@return table
function listStoragePoolLines()
    local raw = ktoxInventoryListPooled(ktoxConfigStorageVaultNames())
    return ktox_split(raw, "\n")
end

