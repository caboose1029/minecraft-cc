-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/PassiveFeeder.kt", {["1-8"]=1,["9"]=33,["10"]=34,["11-12"]=35,["13"]=37,["14"]=38,["15"]=39,["16"]=40,["17"]=41,["18"]=42,["19"]=43,["20"]=44,["21"]=45,["22"]=46,["23"]=47,["24-25"]=48,["26-29"]=50}, "lib")
ktox_require("lib/Planner")
ktox_require("lib/Inventory")

function topUpPassiveFeeders()
    local raw = ktoxConfigPassiveFeeders()
    if raw == "" then
        return
    end
    local rows = ktox_split(raw, "\n")
    local i = 1
    while i <= #(rows) do
        local cols = ktox_split(rows[i], ",")
        local vaultName = cols[1]
        local itemName = cols[2]
        local low = ktox_toInt(ktox_toDouble(cols[3]))
        local high = ktox_toInt(ktox_toDouble(cols[4]))
        local current = ktoxInventoryCountNamed(vaultName, itemName)
        if current < low then
            ensureStocked(itemName, high, 0)
            pullFromStoragePool(vaultName, itemName, high - current)
        end
        i = ktox_plusAssign(i, 1)
    end
end

