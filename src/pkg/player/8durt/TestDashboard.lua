-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestDashboard.kt", {["1-8"]=1,["9"]=35,["10"]=36,["11"]=38,["12"]=39,["13"]=45,["14"]=46,["15"]=47,["16"]=48,["17-18"]=49,["19"]=52,["20"]=53,["21"]=54,["22"]=55,["23-24"]=56,["25"]=58,["26-27"]=59,["28"]=62,["29"]=63,["30"]=64,["31"]=65,["32"]=66,["33-34"]=67,["35"]=70,["36"]=71,["37"]=72,["38"]=73,["39-40"]=74,["41"]=81,["42"]=82,["43"]=83,["44"]=84,["45-46"]=85,["47"]=93,["48"]=94,["49"]=95,["50"]=96,["51"]=97,["52-53"]=98,["54"]=103,["55"]=104,["56"]=105,["57"]=106,["58-59"]=107,["60"]=109,["61"]=110,["62"]=111,["63"]=112,["64-65"]=113,["66"]=119,["67"]=120,["68"]=121,["69"]=122,["70-71"]=123,["72"]=125,["73"]=126,["74"]=127,["75"]=128,["76-77"]=129,["78"]=131,["79"]=132,["80"]=133,["81"]=134,["82-83"]=135,["84"]=137,["85"]=138,["86"]=139,["87-88"]=140,["89"]=148,["90"]=149,["91"]=150,["92"]=151,["93-94"]=152,["95"]=154,["96"]=155,["97"]=156,["98"]=157,["99-100"]=158,["101"]=163,["102"]=164,["103-104"]=165,["105-110"]=168}, "programs")
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
    local qtyUpRect = detailQtyUpRect(size)
    local afterStackUp = handleDetailTouch(stockedDetail, Touch:new(qtyUpRect.x, qtyUpRect.y), size)
    println("after stack-up touch (default 64): qtyText=" .. tostring(afterStackUp.qtyText))
    if afterStackUp.qtyText ~= "67" then
        println("FAIL: expected qtyText \'67\' (starting qty 3 + 64), got \'" .. tostring(afterStackUp.qtyText) .. "\'")
    end
    local qtyDownRect = detailQtyDownRect(size)
    local afterStackDown = handleDetailTouch(afterStackUp, Touch:new(qtyDownRect.x, qtyDownRect.y), size)
    println("after stack-down touch: qtyText=" .. tostring(afterStackDown.qtyText))
    if afterStackDown.qtyText ~= "3" then
        println("FAIL: expected qtyText \'3\' (back down one stack), got \'" .. tostring(afterStackDown.qtyText) .. "\'")
    end
    local pearlDetail = DashboardState:new("detail", "stocked", 1, "minecraft:ender_pearl", "stocked", "5", "1", true, -1, "")
    local afterPearlUp = handleDetailTouch(pearlDetail, Touch:new(qtyUpRect.x, qtyUpRect.y), size)
    println("after stack-up touch (ender_pearl, stack 16): qtyText=" .. tostring(afterPearlUp.qtyText))
    if afterPearlUp.qtyText ~= "17" then
        println("FAIL: expected qtyText \'17\' (starting qty 1 + 16), got \'" .. tostring(afterPearlUp.qtyText) .. "\'")
    end
    local afterPearlDownBelowZero = handleDetailTouch(pearlDetail, Touch:new(qtyDownRect.x, qtyDownRect.y), size)
    println("after stack-down touch clamping at 0: qtyText=" .. tostring(afterPearlDownBelowZero.qtyText))
    if afterPearlDownBelowZero.qtyText ~= "0" then
        println("FAIL: expected qtyText \'0\' (clamped, not negative), got \'" .. tostring(afterPearlDownBelowZero.qtyText) .. "\'")
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
