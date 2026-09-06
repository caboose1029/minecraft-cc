-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/PassiveFeeder.kt", {["1-7"]=1,["8"]=21,["9"]=22,["10-11"]=23,["12"]=25,["13"]=26,["14"]=27,["15"]=28,["16"]=29,["17"]=30,["18"]=31,["19"]=32,["20"]=33,["21"]=34,["22-23"]=35,["24-27"]=37}, "lib")
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
            pullFromStoragePool(vaultName, itemName, high - current)
        end
        i = ktox_plusAssign(i, 1)
    end
end

