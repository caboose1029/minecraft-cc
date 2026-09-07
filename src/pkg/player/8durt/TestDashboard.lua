-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestDashboard.kt", {["1-8"]=1,["9"]=32,["10"]=33,["11"]=35,["12"]=36,["13"]=42,["14"]=43,["15"]=44,["16"]=45,["17-18"]=46,["19"]=49,["20"]=50,["21"]=51,["22"]=52,["23-24"]=53,["25"]=55,["26-27"]=56,["28"]=59,["29"]=60,["30"]=61,["31"]=62,["32"]=63,["33-34"]=64,["35"]=67,["36"]=68,["37"]=69,["38"]=70,["39-40"]=71,["41"]=75,["42"]=76,["43"]=77,["44"]=78,["45-46"]=79,["47"]=82,["48"]=83,["49"]=84,["50"]=85,["51-52"]=86,["53"]=89,["54"]=90,["55"]=91,["56"]=92,["57-58"]=93,["59"]=101,["60"]=102,["61"]=103,["62"]=104,["63"]=105,["64-65"]=106,["66"]=111,["67"]=112,["68"]=113,["69"]=114,["70-71"]=115,["72"]=117,["73"]=118,["74"]=119,["75"]=120,["76-77"]=121,["78"]=126,["79"]=127,["80"]=128,["81"]=129,["82"]=130,["83"]=131,["84-85"]=132,["86"]=137,["87"]=138,["88-89"]=139,["90-95"]=142}, "programs")
ktox_require("lib/Dashboard")
ktox_require("lib/Display")

local function main()
    local size = DisplaySize:new(30, 13)
    println("size=" .. tostring(size.width) .. "x" .. tostring(size.height))
    local state = freshDashboardState()
    println("initial: mode=" .. tostring(state.mode) .. " tab=" .. tostring(state.tab) .. " page=" .. tostring(state.page))
    local tab3Rect = tabRect(size, 3)
    local afterTab = handleBrowseTouch(state, Touch:new(tab3Rect.x, tab3Rect.y), size)
    println("after tab3 touch: mode=" .. tostring(afterTab.mode) .. " tab=" .. tostring(afterTab.tab) .. " page=" .. tostring(afterTab.page))
    if afterTab.tab ~= "unavailable" then
        println("FAIL: tab3 touch should select \'unavailable\', got \'" .. tostring(afterTab.tab) .. "\'")
    end
    local row1Rect = itemRowRect(size, 1)
    local afterRow = handleBrowseTouch(afterTab, Touch:new(row1Rect.x, row1Rect.y), size)
    println("after row1 touch: mode=" .. tostring(afterRow.mode) .. " item=" .. tostring(afterRow.selectedItem) .. " status=" .. tostring(afterRow.selectedStatus) .. " qty=" .. tostring(afterRow.qtyText))
    if afterRow.mode ~= "detail" then
        println("FAIL: row1 touch should enter detail mode, got \'" .. tostring(afterRow.mode) .. "\'")
    end
    if afterRow.selectedItem == "" then
        println("FAIL: row1 touch should select an item, got empty string")
    end
    local craftRect = detailCraftButtonRect(size)
    local afterCraft = handleDetailTouch(afterRow, Touch:new(craftRect.x, craftRect.y), size)
    println("after craft touch: readyCommand=(" .. tostring(afterCraft.readyCommand) .. ")")
    local expectedCraftPrefix = "craft " .. tostring(afterRow.selectedItem) .. " 1"
    if afterCraft.readyCommand ~= expectedCraftPrefix then
        println("FAIL: expected readyCommand \'" .. tostring(expectedCraftPrefix) .. "\', got \'" .. tostring(afterCraft.readyCommand) .. "\'")
    end
    local backRect = detailBackRect()
    local afterBack = handleDetailTouch(afterRow, Touch:new(backRect.x, backRect.y), size)
    println("after back touch: mode=" .. tostring(afterBack.mode) .. " tab=" .. tostring(afterBack.tab))
    if afterBack.mode ~= "browse" then
        println("FAIL: back touch should return to browse mode, got \'" .. tostring(afterBack.mode) .. "\'")
    end
    local qtyFieldRect = detailQtyRect(size)
    local afterQtyTap = handleDetailTouch(afterRow, Touch:new(qtyFieldRect.x, qtyFieldRect.y), size)
    println("after qty field touch: mode=" .. tostring(afterQtyTap.mode))
    if afterQtyTap.mode ~= "keypad" then
        println("FAIL: qty field touch should enter keypad mode, got \'" .. tostring(afterQtyTap.mode) .. "\'")
    end
    local digitRect = keypadKeyRect(size, 3, 2)
    local afterDigit = handleKeypadTouch(afterQtyTap, Touch:new(digitRect.x, digitRect.y), size)
    println("after digit \'2\' touch: qtyText=" .. tostring(afterDigit.qtyText))
    if afterDigit.qtyText ~= "12" then
        println("FAIL: expected qtyText \'12\' (default \'1\' + tapped \'2\'), got \'" .. tostring(afterDigit.qtyText) .. "\'")
    end
    local okRect = keypadKeyRect(size, 4, 3)
    local afterOk = handleKeypadTouch(afterDigit, Touch:new(okRect.x, okRect.y), size)
    println("after OK touch: mode=" .. tostring(afterOk.mode) .. " qtyText=" .. tostring(afterOk.qtyText))
    if afterOk.mode ~= "detail" then
        println("FAIL: OK touch should return to detail mode, got \'" .. tostring(afterOk.mode) .. "\'")
    end
    local stockedDetail = DashboardState:new("detail", "stocked", 1, "minecraft:iron_ingot", "stocked", "64", "3", true, -1, "")
    local fetchRect = detailFetchButtonRect(size)
    local afterFetch = handleDetailTouch(stockedDetail, Touch:new(fetchRect.x, fetchRect.y), size)
    println("after fetch touch: readyCommand=(" .. tostring(afterFetch.readyCommand) .. ")")
    if afterFetch.readyCommand ~= "pull minecraft:iron_ingot 3" then
        println("FAIL: expected readyCommand \'pull minecraft:iron_ingot 3\', got \'" .. tostring(afterFetch.readyCommand) .. "\'")
    end
    local checkboxRect = detailFetchCheckboxRect(size)
    local afterUncheck = handleDetailTouch(stockedDetail, Touch:new(checkboxRect.x, checkboxRect.y), size)
    println("after checkbox touch: fetchChecked=" .. tostring(afterUncheck.fetchChecked))
    if afterUncheck.fetchChecked then
        println("FAIL: checkbox touch should have unchecked fetchChecked")
    end
    local craftRect2 = detailCraftButtonRect(size)
    local afterCraftUnchecked = handleDetailTouch(afterUncheck, Touch:new(craftRect2.x, craftRect2.y), size)
    println("after craft touch (fetch unchecked): readyCommand=(" .. tostring(afterCraftUnchecked.readyCommand) .. ")")
    if afterCraftUnchecked.readyCommand ~= "craft minecraft:iron_ingot 3 --fetch=false" then
        println("FAIL: expected \'--fetch=false\' appended, got \'" .. tostring(afterCraftUnchecked.readyCommand) .. "\'")
    end
    local locationRect = detailLocationRect(size)
    local afterLocation1 = handleDetailTouch(stockedDetail, Touch:new(locationRect.x, locationRect.y), size)
    println("after 1st location touch: locationIndex=" .. tostring(afterLocation1.locationIndex))
    local afterFetchWithLocation = handleDetailTouch(afterLocation1, Touch:new(fetchRect.x, fetchRect.y), size)
    println("after fetch touch (location set): readyCommand=(" .. tostring(afterFetchWithLocation.readyCommand) .. ")")
    if afterFetchWithLocation.readyCommand ~= "pull minecraft:iron_ingot 3 --location=main" then
        println("FAIL: expected \'--location=main\' appended, got \'" .. tostring(afterFetchWithLocation.readyCommand) .. "\'")
    end
    local afterMiss = handleBrowseTouch(state, Touch:new(999, 999), size)
    if afterMiss.mode ~= state.mode or afterMiss.tab ~= state.tab then
        println("FAIL: an out-of-bounds touch mutated state unexpectedly")
    end
    println("TestDashboard done.")
end


-- Auto-generated call to main function
main()
