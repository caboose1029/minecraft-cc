-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Config.kt", {["1-53"]=1,["54"]=27,["55"]=28,["56-57"]=29,["58"]=34,["59-64"]=35,["65-71"]=44,["72"]=49,["73-79"]=50,["80"]=54,["81-87"]=55,["88"]=62,["89"]=63,["90"]=64,["91-92"]=65,["93-98"]=67,["99-101"]=74}, "lib")

---@class Recipe
---@field outputName string
---@field outputCount number
---@field jobType string
---@field inputsRaw string
Recipe = {}
Recipe.__index = Recipe

function Recipe:new(outputName, outputCount, jobType, inputsRaw)
    local self = setmetatable({}, Recipe)
    self.outputName = outputName
    self.outputCount = outputCount
    self.jobType = jobType
    self.inputsRaw = inputsRaw
    return self
end

function Recipe:equals(other)
    return self.outputName == other.outputName and self.outputCount == other.outputCount and self.jobType == other.jobType and self.inputsRaw == other.inputsRaw
end
Recipe.__eq = function(a, b) return a:equals(b) end
function Recipe:toString()
    return "Recipe(" .. "outputName=" .. tostring(self.outputName) .. ", " .. "outputCount=" .. tostring(self.outputCount) .. ", " .. "jobType=" .. tostring(self.jobType) .. ", " .. "inputsRaw=" .. tostring(self.inputsRaw) .. ")"
end
Recipe.__tostring = function(a) return a:toString() end
function Recipe:copy(outputName, outputCount, jobType, inputsRaw)
    if outputName == nil then outputName = self.outputName end
    if outputCount == nil then outputCount = self.outputCount end
    if jobType == nil then jobType = self.jobType end
    if inputsRaw == nil then inputsRaw = self.inputsRaw end
    return Recipe:new(outputName, outputCount, jobType, inputsRaw)
end
function Recipe:component1()
    return self.outputName
end
function Recipe:component2()
    return self.outputCount
end
function Recipe:component3()
    return self.jobType
end
function Recipe:component4()
    return self.inputsRaw
end

---@param outputName string
---@return Recipe?
function findRecipe(outputName)
    local raw = ktoxConfigProducesLookup(outputName)
    if raw == "MISSING" then
        return nil
    end
    local parts = ktox_split(raw, "|")
    return Recipe:new(outputName, ktox_toInt(ktox_toDouble(parts[2])), parts[1], parts[3])
end

---@param recipe Recipe
---@return number
function recipeInputCount(recipe)
    return #(ktox_split(recipe.inputsRaw, ";"))
end

---@param recipe Recipe
---@param index number
---@return string
function recipeInputItem(recipe, index)
    local entry = ktox_split(recipe.inputsRaw, ";")[index]
    return ktox_split(entry, ",")[1]
end

---@param recipe Recipe
---@param index number
---@return number
function recipeInputCountAt(recipe, index)
    local entry = ktox_split(recipe.inputsRaw, ";")[index]
    return ktox_toInt(ktox_toDouble(ktox_split(entry, ",")[2]))
end

---@param recipe Recipe
---@param index number
---@return number
function recipeInputSlot(recipe, index)
    local entry = ktox_split(recipe.inputsRaw, ";")[index]
    local slotStr = ktox_split(entry, ",")[3]
    if slotStr == "" then
        return -1
    end
    return ktox_toInt(ktox_toDouble(slotStr))
end

---@param jobType string
---@return string
function jobKind(jobType)
    return ktoxConfigJobKind(jobType)
end

