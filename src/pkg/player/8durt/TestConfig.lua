-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestConfig.kt", {["1-10"]=1,["11"]=23,["12"]=25,["13"]=26,["14-15"]=27,["16-17"]=29,["18"]=32,["19"]=33,["20-21"]=34,["22-23"]=36,["24"]=39,["25"]=40,["26-27"]=41,["28"]=43,["29"]=44,["30"]=45,["31"]=46,["32"]=47,["33-35"]=48,["36"]=52,["37"]=53,["38-39"]=54,["40"]=56,["41"]=57,["42"]=58,["43"]=59,["44"]=60,["45-47"]=61,["48"]=65,["49"]=67,["50"]=68,["51"]=70,["52"]=71,["53"]=72,["54"]=73,["55"]=74,["56"]=75,["57"]=76,["58"]=77,["59"]=78,["60-65"]=79}, "programs")
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
    local recipe = findRecipe("create:copper_sheet")
    if recipe == nil then
        println("Recipe for create:copper_sheet: none configured")
    else
        local count = recipeInputCount(recipe)
        println("Recipe for create:copper_sheet: " .. tostring(count) .. " input(s) via " .. tostring(recipe.jobType) .. " -> " .. tostring(recipe.outputCount) .. "x output")
        local i = 1
        while i <= count do
            println("  input " .. tostring(i) .. ": " .. tostring(recipeInputCountAt(recipe, i)) .. "x " .. tostring(recipeInputItem(recipe, i)) .. " (slot " .. tostring(recipeInputSlot(recipe, i)) .. ")")
            i = ktox_plusAssign(i, 1)
        end
    end
    local brass = findRecipe("create:brass_ingot")
    if brass == nil then
        println("Recipe for create:brass_ingot: none configured")
    else
        local count = recipeInputCount(brass)
        println("Recipe for create:brass_ingot: " .. tostring(count) .. " input(s) via " .. tostring(brass.jobType) .. " -> " .. tostring(brass.outputCount) .. "x output")
        local i = 1
        while i <= count do
            println("  input " .. tostring(i) .. ": " .. tostring(recipeInputCountAt(brass, i)) .. "x " .. tostring(recipeInputItem(brass, i)))
            i = ktox_plusAssign(i, 1)
        end
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
    println("--- craft brass (2-ingredient recipe, no stock - should not hang) ---")
    println(runCliCommand("craft create:brass_ingot 5"))
end


-- Auto-generated call to main function
main()
