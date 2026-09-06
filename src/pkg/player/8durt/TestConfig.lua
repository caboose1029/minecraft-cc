-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestConfig.kt", {["1-12"]=1,["13"]=26,["14"]=28,["15"]=29,["16-17"]=30,["18-19"]=32,["20"]=35,["21"]=36,["22-23"]=37,["24-25"]=39,["26"]=42,["27"]=43,["28-29"]=44,["30"]=46,["31"]=47,["32"]=48,["33"]=49,["34"]=50,["35-37"]=51,["38"]=55,["39"]=56,["40-41"]=57,["42"]=59,["43"]=60,["44"]=61,["45"]=62,["46"]=63,["47-49"]=64,["50"]=68,["51"]=70,["52"]=71,["53"]=73,["54"]=74,["55"]=75,["56"]=76,["57"]=77,["58"]=78,["59"]=79,["60"]=80,["61"]=81,["62"]=82,["63"]=83,["64"]=84,["65"]=86,["66"]=87,["67-68"]=88,["69"]=90,["70"]=91,["71"]=92,["72"]=93,["73"]=94,["74-76"]=95,["77"]=98,["78"]=99,["79"]=100,["80"]=101,["81"]=103,["82"]=104,["83"]=105,["84"]=107,["85"]=108,["86-91"]=109}, "programs")
ktox_require("lib/Config")
ktox_require("lib/Farm")
ktox_require("lib/PassiveFeeder")
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
    println("--- trash ---")
    println(runCliCommand("trash minecraft:cobblestone 64"))
    local chestRecipe = findRecipe("minecraft:chest")
    if chestRecipe == nil then
        println("Recipe for minecraft:chest: none configured")
    else
        local count = recipeInputCount(chestRecipe)
        println("Recipe for minecraft:chest: " .. tostring(count) .. " input(s) via " .. tostring(chestRecipe.jobType))
        local i = 1
        while i <= count do
            println("  input " .. tostring(i) .. ": " .. tostring(recipeInputCountAt(chestRecipe, i)) .. "x " .. tostring(recipeInputItem(chestRecipe, i)) .. " -> slot " .. tostring(recipeInputSlot(chestRecipe, i)))
            i = ktox_plusAssign(i, 1)
        end
    end
    println("Job kind for chest_crafter: " .. tostring(jobKind("chest_crafter")))
    println("Job kind for smelter: " .. tostring(jobKind("smelter")))
    println("--- craft chest (crafter-kind job, no modem - should not hang) ---")
    println(runCliCommand("craft minecraft:chest 1"))
    println("--- topUpPassiveFeeders (no real peripherals - should not crash) ---")
    topUpPassiveFeeders()
    println("done")
    println("--- manageFarms (no real peripherals - should not crash) ---")
    manageFarms()
    println("done")
end


-- Auto-generated call to main function
main()
