-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestConfig.kt", {["1-10"]=1,["11"]=19,["12"]=21,["13"]=22,["14-15"]=23,["16-17"]=25,["18"]=28,["19"]=29,["20-21"]=30,["22-23"]=32,["24"]=35,["25"]=36,["26-27"]=37,["28-29"]=39,["30"]=42,["31"]=44,["32"]=45,["33"]=47,["34"]=48,["35"]=49,["36"]=50,["37"]=51,["38"]=52,["39"]=53,["40-45"]=54}, "programs")
ktox_require("lib/Config")
ktox_require("lib/Cli")
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
    println("--- list ---")
    println(runCliCommand("list"))
    println("--- list --unavailable ---")
    println(runCliCommand("list --unavailable"))
    println("--- pull with no pickup vault configured ---")
    println(runCliCommand("pull minecraft:copper_ingot 5"))
    println("--- craft (no stock, no input available - should not hang) ---")
    println(runCliCommand("craft create:copper_sheet 5"))
end


-- Auto-generated call to main function
main()
