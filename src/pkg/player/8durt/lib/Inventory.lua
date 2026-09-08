-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Inventory.kt", {["1-8"]=1,["9"]=21,["10"]=22,["11-12"]=23,["13-20"]=25,["21"]=33,["22"]=34,["23-24"]=35,["25-29"]=37,["30"]=53,["31-35"]=54,["36"]=64,["37"]=65,["38-39"]=66,["40-78"]=68,["79"]=81,["80"]=82,["81-82"]=83,["83"]=85,["84-90"]=86,["91-98"]=95,["99"]=114,["100"]=115,["101-102"]=116,["103"]=118,["104"]=119,["105"]=120,["106"]=121,["107"]=122,["108"]=123,["109"]=124,["110"]=125,["111"]=126,["112-114"]=127,["115-116"]=130,["117-122"]=132,["123"]=146,["124"]=147,["125"]=148,["126"]=149,["127-128"]=150,["129-130"]=152,["131"]=154,["132"]=155,["133-134"]=156,["135-137"]=158}, "lib")

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
    local storageVault = firstStorageVaultName()
    if storageVault == "MISSING" then
        return 0
    end
    return drainVaultInto(belowChest, storageVault)
end

