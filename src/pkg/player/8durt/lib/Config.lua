-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Config.kt", {["1-59"]=1,["60"]=18,["61"]=19,["62-63"]=20,["64"]=25,["65-67"]=26}, "lib")

---@class DirectConversion
---@field inputName string
---@field outputName string
---@field jobType string
---@field inputCount number
---@field outputCount number
DirectConversion = {}
DirectConversion.__index = DirectConversion

function DirectConversion:new(inputName, outputName, jobType, inputCount, outputCount)
    local self = setmetatable({}, DirectConversion)
    self.inputName = inputName
    self.outputName = outputName
    self.jobType = jobType
    self.inputCount = inputCount
    self.outputCount = outputCount
    return self
end

function DirectConversion:equals(other)
    return self.inputName == other.inputName and self.outputName == other.outputName and self.jobType == other.jobType and self.inputCount == other.inputCount and self.outputCount == other.outputCount
end
DirectConversion.__eq = function(a, b) return a:equals(b) end
function DirectConversion:toString()
    return "DirectConversion(" .. "inputName=" .. tostring(self.inputName) .. ", " .. "outputName=" .. tostring(self.outputName) .. ", " .. "jobType=" .. tostring(self.jobType) .. ", " .. "inputCount=" .. tostring(self.inputCount) .. ", " .. "outputCount=" .. tostring(self.outputCount) .. ")"
end
DirectConversion.__tostring = function(a) return a:toString() end
function DirectConversion:copy(inputName, outputName, jobType, inputCount, outputCount)
    if inputName == nil then inputName = self.inputName end
    if outputName == nil then outputName = self.outputName end
    if jobType == nil then jobType = self.jobType end
    if inputCount == nil then inputCount = self.inputCount end
    if outputCount == nil then outputCount = self.outputCount end
    return DirectConversion:new(inputName, outputName, jobType, inputCount, outputCount)
end
function DirectConversion:component1()
    return self.inputName
end
function DirectConversion:component2()
    return self.outputName
end
function DirectConversion:component3()
    return self.jobType
end
function DirectConversion:component4()
    return self.inputCount
end
function DirectConversion:component5()
    return self.outputCount
end

---@param outputName string
---@return DirectConversion?
function findDirectConversion(outputName)
    local raw = ktoxConfigProducesLookup(outputName)
    if raw == "MISSING" then
        return nil
    end
    local parts = ktox_split(raw, ",")
    return DirectConversion:new(parts[1], outputName, parts[2], ktox_toInt(ktox_toDouble(parts[3])), ktox_toInt(ktox_toDouble(parts[4])))
end

