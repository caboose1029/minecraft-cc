-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestDashboard.kt", {["1-8"]=1,["9"]=33,["10"]=34,["11"]=36,["12"]=37,["13"]=43,["14"]=44,["15"]=45,["16"]=46,["17-18"]=47,["19"]=50,["20"]=51,["21"]=52,["22"]=53,["23-24"]=54,["25"]=56,["26-27"]=57,["28"]=60,["29"]=61,["30"]=62,["31"]=63,["32"]=64,["33-34"]=65,["35"]=68,["36"]=69,["37"]=70,["38"]=71,["39-40"]=72,["41"]=79,["42"]=80,["43"]=81,["44"]=82,["45-46"]=83,["47"]=91,["48"]=92,["49"]=93,["50"]=94,["51"]=95,["52-53"]=96,["54"]=101,["55"]=102,["56"]=103,["57"]=104,["58-59"]=105,["60"]=107,["61"]=108,["62"]=109,["63"]=110,["64-65"]=111,["66"]=119,["67"]=120,["68"]=121,["69"]=122,["70-71"]=123,["72"]=125,["73"]=126,["74"]=127,["75"]=128,["76-77"]=129,["78"]=134,["79"]=135,["80-81"]=136,["82-87"]=139}, "programs")
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
    if afterQtyTap.mode ~= "qtyentry" then
        println("FAIL: qty field touch should enter qtyentry mode, got \'" .. tostring(afterQtyTap.mode) .. "\'")
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
    if afterLocation1.locationIndex < 1 then
        println("FAIL: expected locationIndex to advance to a real location, stayed at " .. tostring(afterLocation1.locationIndex))
    end
    local afterFetchWithLocation = handleDetailTouch(afterLocation1, Touch:new(fetchRect.x, fetchRect.y), size)
    println("after fetch touch (location set): readyCommand=(" .. tostring(afterFetchWithLocation.readyCommand) .. ")")
    local locationParts = ktox_split(afterFetchWithLocation.readyCommand, "--location=")
    if #(locationParts) < 2 or locationParts[2] == "" then
        println("FAIL: expected \'--location=<name>\' appended, got \'" .. tostring(afterFetchWithLocation.readyCommand) .. "\'")
    end
    local afterMiss = handleBrowseTouch(state, Touch:new(999, 999), size)
    if afterMiss.mode ~= state.mode or afterMiss.tab ~= state.tab then
        println("FAIL: an out-of-bounds touch mutated state unexpectedly")
    end
    println("TestDashboard done.")
end


-- Auto-generated call to main function
main()
