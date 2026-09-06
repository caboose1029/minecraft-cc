-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestConfig.kt", {["1-9"]=1,["10"]=18,["11"]=20,["12"]=21,["13-14"]=22,["15-16"]=24,["17"]=27,["18"]=28,["19-20"]=29,["21-22"]=31,["23"]=34,["24"]=35,["25-26"]=36,["27-28"]=38,["29"]=41,["30"]=43,["31-36"]=44}, "programs")
ktox_require("lib/Config")
ktox_require("lib/Redstone")
ktox_require("lib/Inventory")

local function main()
    println("Storage vault names: " .. tostring(ktoxConfigStorageVaultNames()))
    local feeder = ktoxConfigFeederForJob("mechanical_press_depot")
    if feeder == "MISSING" then
        println("Feeder for mechanical_press_depot: none configured")
    else
        println("Feeder for mechanical_press_depot: " .. tostring(feeder))
    end
    local relay = ktoxConfigRelayForJob("smelter")
    if relay == "MISSING" then
        println("Relay for smelter: none configured")
    else
        println("Relay for smelter: " .. tostring(relay))
    end
    local conversion = findDirectConversion("create:copper_sheet")
    if conversion == nil then
        println("Direct conversion for create:copper_sheet: none configured")
    else
        println("Direct conversion for create:copper_sheet: " .. tostring(conversion.inputCount) .. "x " .. tostring(conversion.inputName) .. " via " .. tostring(conversion.jobType) .. " -> " .. tostring(conversion.outputCount) .. "x output")
    end
    println("Storage pool count of minecraft:copper_ingot: " .. tostring(storagePoolCount("minecraft:copper_ingot")))
    local powered = setJobPower("smelter", true)
    println("setJobPower(smelter, true) reached a relay: " .. tostring(powered))
end


-- Auto-generated call to main function
main()
