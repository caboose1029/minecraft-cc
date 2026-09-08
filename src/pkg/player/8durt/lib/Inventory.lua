-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=22,["10"]=23,["11-12"]=24,["13-20"]=26,["21"]=34,["22"]=35,["23-24"]=36,["25-29"]=38,["30"]=54,["31-35"]=55,["36"]=65,["37"]=66,["38-39"]=67,["40-44"]=69,["45"]=82,["46"]=83,["47-48"]=84,["49-87"]=86,["88"]=99,["89"]=100,["90-91"]=101,["92"]=103,["93-99"]=104,["100-107"]=113,["108"]=132,["109"]=133,["110-111"]=134,["112"]=136,["113"]=137,["114"]=138,["115"]=139,["116"]=140,["117"]=141,["118"]=142,["119"]=143,["120"]=144,["121-123"]=145,["124-125"]=148,["126-131"]=150,["132"]=164,["133"]=165,["134"]=166,["135"]=167,["136-137"]=168,["138-139"]=170,["140"]=172,["141"]=173,["142-143"]=174,["144-146"]=176}, "lib")

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

---@return string
function firstStorageVaultName()
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return "MISSING"
    end
    return ktox_split(vaultNames, ",")[1]
end

---@return string
function leastFullStorageVaultName()
    local vaultNames = ktoxConfigStorageVaultNames()
    if vaultNames == "" then
        return "MISSING"
    end
    return ktoxLeastFullStorageVault(vaultNames)
end

---@class Chests
---@field above string
---@field below string
Chests = {}
Chests.__index = Chests

function Chests:new(above, below)
    local self = setmetatable({}, Chests)
    self.above = above
    self.below = below
    return self
end

function Chests:equals(other)
    return self.above == other.above and self.below == other.below
end
Chests.__eq = function(a, b) return a:equals(b) end
function Chests:toString()
    return "Chests(" .. "above=" .. tostring(self.above) .. ", " .. "below=" .. tostring(self.below) .. ")"
end
Chests.__tostring = function(a) return a:toString() end
function Chests:copy(above, below)
    if above == nil then above = self.above end
    if below == nil then below = self.below end
    return Chests:new(above, below)
end
function Chests:component1()
    return self.above
end
function Chests:component2()
    return self.below
end

---@param peripheralName string
---@return Chests?
function chestsFor(peripheralName)
    local raw = ktoxConfigChestsFor(peripheralName)
    if raw == "MISSING" then
        return nil
    end
    local parts = ktox_split(raw, ",")
    return Chests:new(parts[1], parts[2])
end

---@param fromName string
---@param toName string
---@return number
function drainVaultInto(fromName, toName)
    return ktoxInventoryDrainAll(fromName, toName)
end

---@param aboveChest string
---@param itemName string
---@param desired number
---@return number
function deliverViaSelfSuckUp(aboveChest, itemName, desired)
    local staged = pullFromStoragePool(aboveChest, itemName, desired)
    if staged <= 0 then
        return 0
    end
    local remaining = staged
    local slot = 1
    while slot <= 16 and remaining > 0 do
        if turtle.getItemCount(slot) == 0 then
            turtle.select(slot)
            turtle.suckUp(remaining)
            local gathered = turtle.getItemCount(slot)
            remaining = ktox_minusAssign(remaining, gathered)
            if gathered == 0 then
                return staged - remaining
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return staged - remaining
end

---@param belowChest string
---@return number
function depositSelfInventory(belowChest)
    local slot = 1
    while slot <= 16 do
        turtle.select(slot)
        if turtle.getItemCount(slot) > 0 then
            turtle.dropDown(64)
        end
        slot = ktox_plusAssign(slot, 1)
    end
    local storageVault = leastFullStorageVaultName()
    if storageVault == "MISSING" then
        return 0
    end
    return drainVaultInto(belowChest, storageVault)
end

