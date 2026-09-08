-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/DepositChest.kt", {["1-7"]=1,["8"]=22,["9"]=23,["10-11"]=24,["12"]=26,["13"]=27,["14"]=28,["15"]=29,["16-19"]=30}, "lib")
ktox_require("lib/Inventory")

function drainDepositChests()
    local raw = ktoxConfigDepositVaults()
    if raw == "" then
        return
    end
    local names = ktox_split(raw, ",")
    local i = 1
    while i <= #(names) do
        drainVaultInto(names[i], leastFullStorageVaultName())
        i = ktox_plusAssign(i, 1)
    end
end

