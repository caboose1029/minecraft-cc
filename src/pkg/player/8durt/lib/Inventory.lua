-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=18,["10"]=19,["11-12"]=20,["13-20"]=22,["21"]=30,["22"]=31,["23-24"]=32,["25-32"]=34,["33"]=55,["34"]=56,["35-36"]=57,["37-41"]=59,["42"]=75,["43-47"]=76,["48"]=86,["49"]=87,["50-51"]=88,["52-90"]=90,["91"]=101,["92"]=102,["93-94"]=103,["95"]=105,["96-102"]=106,["103-105"]=115}, "lib")

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

---@return string
function firstStorageVaultName()
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return "MISSING"
    end
    return ktox_split(vaultNames, ",")[1]
end

---@class CrafterChests
---@field above string
---@field below string
CrafterChests = {}
CrafterChests.__index = CrafterChests

function CrafterChests:new(above, below)
    local self = setmetatable({}, CrafterChests)
    self.above = above
    self.below = below
    return self
end

function CrafterChests:equals(other)
    return self.above == other.above and self.below == other.below
end
CrafterChests.__eq = function(a, b) return a:equals(b) end
function CrafterChests:toString()
    return "CrafterChests(" .. "above=" .. tostring(self.above) .. ", " .. "below=" .. tostring(self.below) .. ")"
end
CrafterChests.__tostring = function(a) return a:toString() end
function CrafterChests:copy(above, below)
    if above == nil then above = self.above end
    if below == nil then below = self.below end
    return CrafterChests:new(above, below)
end
function CrafterChests:component1()
    return self.above
end
function CrafterChests:component2()
    return self.below
end

---@param crafterName string
---@return CrafterChests?
function crafterChestsFor(crafterName)
    local raw = ktoxConfigCrafterChests(crafterName)
    if raw == "MISSING" then
        return nil
    end
    local parts = ktox_split(raw, ",")
    return CrafterChests:new(parts[1], parts[2])
end

---@param fromName string
---@param toName string
---@return number
function drainVaultInto(fromName, toName)
    return ktoxInventoryDrainAll(fromName, toName)
end

