-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Farm.kt", {["1-43"]=1,["44-50"]=21,["51-57"]=26,["58-64"]=30,["65-68"]=34,["69"]=53,["70"]=54,["71-72"]=55,["73"]=57,["74"]=58,["75"]=59,["76"]=60,["77"]=61,["78"]=62,["79"]=64,["80"]=65,["81"]=66,["82"]=67,["83"]=68,["84"]=69,["85"]=70,["86"]=71,["87"]=72,["88-89"]=73,["90"]=75,["91-92"]=76,["93-94"]=78,["95"]=81,["96-97"]=82,["98-99"]=84,["100-103"]=86}, "lib")
ktox_require("lib/Redstone")
ktox_require("lib/Inventory")

---@class Farm
---@field jobType string
---@field watermarksRaw string
Farm = {}
Farm.__index = Farm

function Farm:new(jobType, watermarksRaw)
    local self = setmetatable({}, Farm)
    self.jobType = jobType
    self.watermarksRaw = watermarksRaw
    return self
end

function Farm:equals(other)
    return self.jobType == other.jobType and self.watermarksRaw == other.watermarksRaw
end
Farm.__eq = function(a, b) return a:equals(b) end
function Farm:toString()
    return "Farm(" .. "jobType=" .. tostring(self.jobType) .. ", " .. "watermarksRaw=" .. tostring(self.watermarksRaw) .. ")"
end
Farm.__tostring = function(a) return a:toString() end
function Farm:copy(jobType, watermarksRaw)
    if jobType == nil then jobType = self.jobType end
    if watermarksRaw == nil then watermarksRaw = self.watermarksRaw end
    return Farm:new(jobType, watermarksRaw)
end
function Farm:component1()
    return self.jobType
end
function Farm:component2()
    return self.watermarksRaw
end

---@param farm Farm
---@return number
function farmWatermarkCount(farm)
    return #(ktox_split(farm.watermarksRaw, ";"))
end

---@param farm Farm
---@param index number
---@return string
function farmWatermarkItem(farm, index)
    return ktox_split(ktox_split(farm.watermarksRaw, ";")[index], ",")[1]
end

---@param farm Farm
---@param index number
---@return number
function farmWatermarkLow(farm, index)
    return ktox_toInt(ktox_toDouble(ktox_split(ktox_split(farm.watermarksRaw, ";")[index], ",")[2]))
end

---@param farm Farm
---@param index number
---@return number
function farmWatermarkHigh(farm, index)
    return ktox_toInt(ktox_toDouble(ktox_split(ktox_split(farm.watermarksRaw, ";")[index], ",")[3]))
end

function manageFarms()
    local raw = ktoxConfigAllFarms()
    if raw == "" then
        return
    end
    local rows = ktox_split(raw, "\n")
    local i = 1
    while i <= #(rows) do
        local parts = ktox_split(rows[i], "|")
        local farm = Farm:new(parts[1], parts[2])
        local watermarkCount = farmWatermarkCount(farm)
        local anyBelowLow = false
        local allAboveHigh = true
        local j = 1
        while j <= watermarkCount do
            local item = farmWatermarkItem(farm, j)
            local low = farmWatermarkLow(farm, j)
            local high = farmWatermarkHigh(farm, j)
            local current = storagePoolCount(item)
            if current < low then
                anyBelowLow = true
            end
            if current <= high then
                allAboveHigh = false
            end
            j = ktox_plusAssign(j, 1)
        end
        if anyBelowLow then
            setJobPower(farm.jobType, true)
        elseif allAboveHigh then
            setJobPower(farm.jobType, false)
        end
        i = ktox_plusAssign(i, 1)
    end
end

