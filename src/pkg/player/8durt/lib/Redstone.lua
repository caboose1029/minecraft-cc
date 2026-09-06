-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Redstone.kt", {["1-9"]=1,["10"]=12,["11"]=13,["12-13"]=14,["14"]=19,["15"]=20,["16"]=21,["17"]=22,["18-20"]=23}, "lib")

---@param jobType string
---@param on boolean
---@return boolean
function setJobPower(jobType, on)
    local relaySide = ktoxConfigRelayForJob(jobType)
    if relaySide == "MISSING" then
        return false
    end
    local parts = ktox_split(relaySide, ",")
    local relayName = parts[1]
    local side = parts[2]
    local result = ktoxPeripheralCall(relayName, "setOutput", "S:" .. tostring(side) .. "|B:" .. tostring(on))
    return result ~= "MISSING"
end

