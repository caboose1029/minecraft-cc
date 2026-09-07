-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestConfig.kt", {["1-12"]=1,["13"]=26,["14"]=28,["15"]=29,["16-17"]=30,["18-19"]=32,["20"]=35,["21"]=36,["22-23"]=37,["24-25"]=39,["26"]=42,["27"]=43,["28-29"]=44,["30"]=46,["31"]=47,["32"]=48,["33"]=49,["34"]=50,["35-37"]=51,["38"]=55,["39"]=56,["40-41"]=57,["42"]=59,["43"]=60,["44"]=61,["45"]=62,["46"]=63,["47-49"]=64,["50"]=72,["51"]=73,["52-53"]=74,["54"]=76,["55"]=77,["56-58"]=78,["59"]=86,["60"]=87,["61-62"]=88,["63"]=90,["64"]=91,["65-67"]=92,["68"]=96,["69"]=98,["70"]=99,["71"]=101,["72"]=102,["73"]=103,["74"]=104,["75"]=105,["76"]=106,["77"]=107,["78"]=108,["79"]=109,["80"]=110,["81"]=111,["82"]=112,["83"]=114,["84"]=115,["85-86"]=116,["87"]=118,["88"]=119,["89"]=120,["90-91"]=121,["92"]=123,["93"]=124,["94"]=125,["95-97"]=126,["98"]=129,["99"]=130,["100"]=131,["101"]=132,["102"]=134,["103"]=135,["104"]=136,["105"]=138,["106"]=139,["107"]=140,["108"]=142,["109"]=143,["110"]=144,["111-116"]=145}, "programs")
ktox_require("lib/Config")
ktox_require("lib/Farm")
ktox_require("lib/PassiveFeeder")
ktox_require("lib/Cli")
ktox_require("lib/Redstone")
ktox_require("lib/Inventory")

local function main()
    println("Storage vault names: " .. tostring(ktoxConfigStorageVaultNames()))
    local feeder = ktoxConfigFeederForJob("pressing")
    if feeder == "MISSING" then
        println("Feeder for pressing: none configured")
    else
        println("Feeder for pressing: " .. tostring(feeder))
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
    local andesite = findRecipe("create:andesite_alloy")
    if andesite == nil then
        println("Recipe for create:andesite_alloy: none configured")
    else
        println("Recipe for create:andesite_alloy: via " .. tostring(andesite.jobType) .. ", input 2 = " .. tostring(recipeInputItem(andesite, 2)))
        if recipeInputItem(andesite, 2) ~= "minecraft:iron_nugget" then
            println("MISMATCH: expected the priority-1 (iron nugget) recipe to win, got " .. tostring(recipeInputItem(andesite, 2)))
        end
    end
    local strippedLog = findRecipe("minecraft:stripped_oak_log")
    if strippedLog == nil then
        println("Recipe for minecraft:stripped_oak_log: none configured")
    else
        println("Recipe for minecraft:stripped_oak_log: via " .. tostring(strippedLog.jobType))
        if strippedLog.jobType ~= "cutting" then
            println("MISMATCH: expected the priority-1 (Mechanical Saw / " .. "\"" .. "cutting" .. "\"" .. ") recipe to win, got " .. "\"" .. tostring(strippedLog.jobType) .. "\"")
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
        if chestRecipe.jobType ~= "crafter" then
            println("MISMATCH: expected job " .. "\"" .. "crafter" .. "\"" .. ", got " .. "\"" .. tostring(chestRecipe.jobType) .. "\"" .. " - this recipe won\'t find its crafter turtle!")
        end
        local i = 1
        while i <= count do
            println("  input " .. tostring(i) .. ": " .. tostring(recipeInputCountAt(chestRecipe, i)) .. "x " .. tostring(recipeInputItem(chestRecipe, i)) .. " -> slot " .. tostring(recipeInputSlot(chestRecipe, i)))
            i = ktox_plusAssign(i, 1)
        end
    end
    println("Job kind for crafter: " .. tostring(jobKind("crafter")))
    println("Job kind for smelter: " .. tostring(jobKind("smelter")))
    println("--- craft chest (crafter-kind job, no modem - should not hang) ---")
    println(runCliCommand("craft minecraft:chest 1"))
    println("--- topUpPassiveFeeders (no real peripherals - should not crash) ---")
    topUpPassiveFeeders()
    println("done")
    println("--- manageFarms (no real peripherals - should not crash) ---")
    manageFarms()
    println("done")
    println("--- craft dried kelp block (9:1 compacting chain, no stock - should not hang) ---")
    println(runCliCommand("craft minecraft:dried_kelp_block 1"))
    println("--- craft lava bucket (fluid-adjacent, no stock - should not hang) ---")
    println(runCliCommand("craft minecraft:lava_bucket 1"))
end


-- Auto-generated call to main function
main()
