-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Dashboard.kt", {["1-141"]=1,["142-146"]=76,["147"]=88,["148"]=89,["149"]=90,["150"]=91,["151"]=92,["152-153"]=93,["154"]=95,["155-156"]=96,["157"]=98,["158"]=99,["159"]=100,["160-162"]=101,["163-168"]=104,["169"]=112,["170"]=113,["171"]=114,["172"]=115,["173"]=116,["174"]=117,["175-176"]=118,["177"]=120,["178"]=121,["179-180"]=122,["181-186"]=124,["187"]=132,["188"]=133,["189"]=134,["190"]=135,["191-195"]=136,["196"]=146,["197"]=147,["198"]=148,["199"]=149,["200-208"]=150,["209"]=157,["210"]=158,["211"]=159,["212"]=160,["213-214"]=161,["215"]=163,["216-217"]=164,["218-224"]=166,["225"]=171,["226"]=172,["227"]=173,["228"]=174,["229-230"]=175,["231"]=177,["232-233"]=178,["234"]=180,["235-236"]=181,["237-243"]=183,["244-249"]=187,["250-255"]=191,["256"]=195,["257-258"]=196,["259"]=198,["260-261"]=199,["262-267"]=201,["268"]=205,["269-270"]=206,["271"]=208,["272-273"]=209,["274-279"]=211,["280"]=215,["281-282"]=216,["283"]=218,["284-285"]=219,["286-291"]=221,["292"]=225,["293"]=226,["294"]=227,["295-296"]=228,["297-303"]=230,["304-309"]=234,["310-316"]=238,["317"]=242,["318-319"]=243,["320"]=245,["321"]=246,["322"]=247,["323-324"]=248,["325-330"]=250,["331"]=257,["332"]=258,["333-334"]=259,["335-342"]=261,["343"]=273,["344"]=274,["345"]=275,["346"]=276,["347-348"]=277,["349"]=279,["350"]=280,["351-352"]=281,["353-357"]=283,["358"]=287,["359"]=288,["360-361"]=289,["362-367"]=291,["368"]=295,["369-370"]=296,["371"]=298,["372"]=299,["373-374"]=300,["375-380"]=302,["381"]=306,["382-383"]=307,["384"]=309,["385"]=310,["386-387"]=311,["388-393"]=313,["394"]=317,["395"]=318,["396-397"]=319,["398"]=321,["399-400"]=322,["401"]=324,["402-403"]=325,["404-408"]=327,["409-416"]=334,["417-422"]=342,["423-428"]=346,["429-434"]=350,["435-440"]=354,["441-446"]=358,["447-452"]=362,["453"]=366,["454-459"]=367,["460"]=373,["461"]=374,["462-463"]=375,["464-469"]=377,["470"]=381,["471"]=383,["472"]=384,["473"]=385,["474"]=386,["475"]=387,["476-477"]=388,["478"]=390,["479-480"]=391,["481"]=394,["482"]=395,["483"]=396,["484-485"]=397,["486"]=399,["487"]=401,["488"]=402,["489"]=403,["490"]=404,["491"]=406,["492"]=407,["493"]=408,["494"]=409,["495"]=410,["496"]=411,["497"]=412,["498"]=413,["499"]=414,["500"]=415,["501"]=416,["502-503"]=417,["504-505"]=419,["506"]=421,["507-508"]=422,["509-510"]=424,["511"]=427,["512"]=428,["513"]=429,["514-515"]=430,["516"]=432,["517-518"]=433,["519-524"]=435,["525"]=439,["526"]=441,["527"]=442,["528"]=443,["529"]=449,["530"]=450,["531"]=451,["532"]=452,["533"]=453,["534"]=454,["535"]=456,["536"]=457,["537"]=459,["538"]=463,["539"]=464,["540-541"]=465,["542"]=467,["543"]=469,["544"]=470,["545-546"]=471,["547"]=473,["548-555"]=474,["556"]=486,["557-558"]=487,["559-566"]=489,["567"]=493,["568"]=494,["569"]=495,["570"]=496,["571-572"]=497,["573-574"]=499,["575"]=502,["576"]=503,["577-578"]=504,["579"]=507,["580"]=508,["581"]=509,["582"]=510,["583"]=511,["584"]=513,["585-586"]=514,["587"]=516,["588-589"]=517,["590"]=520,["591"]=521,["592"]=522,["593"]=523,["594"]=524,["595"]=525,["596"]=526,["597"]=527,["598"]=528,["599"]=529,["600"]=530,["601"]=531,["602"]=532,["603-604"]=533,["605-606"]=535,["607-609"]=537,["610-611"]=540,["612-619"]=543,["620"]=547,["621"]=548,["622-623"]=549,["624"]=552,["625"]=553,["626-627"]=554,["628"]=557,["629"]=558,["630"]=559,["631-632"]=560,["633"]=563,["634"]=564,["635"]=565,["636-637"]=566,["638"]=569,["639"]=570,["640"]=571,["641-642"]=572,["643"]=575,["644"]=576,["645-646"]=577,["647"]=580,["648"]=581,["649"]=582,["650"]=583,["651"]=584,["652"]=585,["653-655"]=586,["656"]=589,["657"]=590,["658"]=591,["659"]=592,["660-661"]=593,["662"]=595,["663-665"]=596,["666-668"]=600}, "lib")
ktox_require("lib/Colors")
ktox_require("lib/Display")

---@class Rect
---@field x number
---@field y number
---@field w number
---@field h number
Rect = {}
Rect.__index = Rect

function Rect:new(x, y, w, h)
    local self = setmetatable({}, Rect)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    return self
end

function Rect:equals(other)
    return self.x == other.x and self.y == other.y and self.w == other.w and self.h == other.h
end
Rect.__eq = function(a, b) return a:equals(b) end
function Rect:toString()
    return "Rect(" .. "x=" .. tostring(self.x) .. ", " .. "y=" .. tostring(self.y) .. ", " .. "w=" .. tostring(self.w) .. ", " .. "h=" .. tostring(self.h) .. ")"
end
Rect.__tostring = function(a) return a:toString() end
function Rect:copy(x, y, w, h)
    if x == nil then x = self.x end
    if y == nil then y = self.y end
    if w == nil then w = self.w end
    if h == nil then h = self.h end
    return Rect:new(x, y, w, h)
end
function Rect:component1()
    return self.x
end
function Rect:component2()
    return self.y
end
function Rect:component3()
    return self.w
end
function Rect:component4()
    return self.h
end

---@class DashboardState
---@field mode string
---@field tab string
---@field page number
---@field selectedItem string
---@field selectedStatus string
---@field selectedCount string
---@field qtyText string
---@field fetchChecked boolean
---@field locationIndex number
---@field readyCommand string
---@field searchText string
DashboardState = {}
DashboardState.__index = DashboardState

function DashboardState:new(mode, tab, page, selectedItem, selectedStatus, selectedCount, qtyText, fetchChecked, locationIndex, readyCommand, searchText)
    local self = setmetatable({}, DashboardState)
    self.mode = mode
    self.tab = tab
    self.page = page
    self.selectedItem = selectedItem
    self.selectedStatus = selectedStatus
    self.selectedCount = selectedCount
    self.qtyText = qtyText
    self.fetchChecked = fetchChecked
    self.locationIndex = locationIndex
    self.readyCommand = readyCommand
    self.searchText = searchText
    return self
end

function DashboardState:equals(other)
    return self.mode == other.mode and self.tab == other.tab and self.page == other.page and self.selectedItem == other.selectedItem and self.selectedStatus == other.selectedStatus and self.selectedCount == other.selectedCount and self.qtyText == other.qtyText and self.fetchChecked == other.fetchChecked and self.locationIndex == other.locationIndex and self.readyCommand == other.readyCommand and self.searchText == other.searchText
end
DashboardState.__eq = function(a, b) return a:equals(b) end
function DashboardState:toString()
    return "DashboardState(" .. "mode=" .. tostring(self.mode) .. ", " .. "tab=" .. tostring(self.tab) .. ", " .. "page=" .. tostring(self.page) .. ", " .. "selectedItem=" .. tostring(self.selectedItem) .. ", " .. "selectedStatus=" .. tostring(self.selectedStatus) .. ", " .. "selectedCount=" .. tostring(self.selectedCount) .. ", " .. "qtyText=" .. tostring(self.qtyText) .. ", " .. "fetchChecked=" .. tostring(self.fetchChecked) .. ", " .. "locationIndex=" .. tostring(self.locationIndex) .. ", " .. "readyCommand=" .. tostring(self.readyCommand) .. ", " .. "searchText=" .. tostring(self.searchText) .. ")"
end
DashboardState.__tostring = function(a) return a:toString() end
function DashboardState:copy(mode, tab, page, selectedItem, selectedStatus, selectedCount, qtyText, fetchChecked, locationIndex, readyCommand, searchText)
    if mode == nil then mode = self.mode end
    if tab == nil then tab = self.tab end
    if page == nil then page = self.page end
    if selectedItem == nil then selectedItem = self.selectedItem end
    if selectedStatus == nil then selectedStatus = self.selectedStatus end
    if selectedCount == nil then selectedCount = self.selectedCount end
    if qtyText == nil then qtyText = self.qtyText end
    if fetchChecked == nil then fetchChecked = self.fetchChecked end
    if locationIndex == nil then locationIndex = self.locationIndex end
    if readyCommand == nil then readyCommand = self.readyCommand end
    if searchText == nil then searchText = self.searchText end
    return DashboardState:new(mode, tab, page, selectedItem, selectedStatus, selectedCount, qtyText, fetchChecked, locationIndex, readyCommand, searchText)
end
function DashboardState:component1()
    return self.mode
end
function DashboardState:component2()
    return self.tab
end
function DashboardState:component3()
    return self.page
end
function DashboardState:component4()
    return self.selectedItem
end
function DashboardState:component5()
    return self.selectedStatus
end
function DashboardState:component6()
    return self.selectedCount
end
function DashboardState:component7()
    return self.qtyText
end
function DashboardState:component8()
    return self.fetchChecked
end
function DashboardState:component9()
    return self.locationIndex
end
function DashboardState:component10()
    return self.readyCommand
end
function DashboardState:component11()
    return self.searchText
end

---@return DashboardState
function freshDashboardState()
    return DashboardState:new("browse", "stocked", 1, "", "", "", "1", true, -1, "", "")
end

---@return string
function runDashboardLoop()
    local state = freshDashboardState()
    displayInit()
    while state.readyCommand == "" do
        if state.mode == "qtyentry" then
            local newQty = promptForQuantity(state.qtyText)
            state = DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "", state.searchText)
        elseif state.mode == "searchentry" then
            local newSearch = promptForSearch(state.searchText)
            state = DashboardState:new("browse", state.tab, 1, "", "", "", "1", true, -1, "", newSearch)
        else
            local size = displaySize()
            renderDashboard(state, size)
            local touch = displayWaitTouch()
            state = handleDashboardTouch(state, touch, size)
        end
    end
    return state.readyCommand
end

---@param current string
---@return string
function promptForQuantity(current)
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Enter quantity (currently " .. tostring(current) .. "):")
    term.setCursorPos(1, 2)
    local typed = read()
    if typed == "" then
        return current
    end
    local parsed = ktox_toDoubleOrNull(typed)
    if parsed == nil or parsed <= 0.0 then
        return current
    end
    return typed
end

---@param current string
---@return string
function promptForSearch(current)
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Search item names (blank clears, currently " .. "\"" .. tostring(current) .. "\"" .. "):")
    term.setCursorPos(1, 2)
    return read()
end

---@param message string
function showDashboardResult(message)
    displayClear()
    local size = displaySize()
    displayFillRect(1, 1, size.width, 1, COLOR_BLACK, COLOR_WHITE, message)
    displayFillRect(1, size.height, size.width, 1, COLOR_GRAY, COLOR_WHITE, "(tap to continue)")
    displayWaitTouch()
end

---@param size DisplaySize
---@param columnIndex number
---@param y number
---@param h number
---@return Rect
function threeColumnRect(size, columnIndex, y, h)
    local totalW = size.width
    local remainder = totalW % 3
    local base = (totalW - remainder) / 3
    if columnIndex == 1 then
        return Rect:new(1, y, base, h)
    end
    if columnIndex == 2 then
        return Rect:new(1 + base, y, base, h)
    end
    return Rect:new(1 + base + base, y, totalW - base - base, h)
end

---@param size DisplaySize
---@param columnIndex number
---@return Rect
function topBarRect(size, columnIndex)
    local totalW = size.width
    local remainder = totalW % 4
    local base = (totalW - remainder) / 4
    if columnIndex == 1 then
        return Rect:new(1, 1, base, 1)
    end
    if columnIndex == 2 then
        return Rect:new(1 + base, 1, base, 1)
    end
    if columnIndex == 3 then
        return Rect:new(1 + base + base, 1, base, 1)
    end
    return Rect:new(1 + base + base + base, 1, totalW - base - base - base, 1)
end

---@param size DisplaySize
---@param index number
---@return Rect
function tabRect(size, index)
    return topBarRect(size, index)
end

---@param size DisplaySize
---@return Rect
function searchButtonRect(size)
    return topBarRect(size, 4)
end

---@param index number
---@return string
function tabLabel(index)
    if index == 1 then
        return "Stocked"
    end
    if index == 2 then
        return "Craftable"
    end
    return "Uncraftable"
end

---@param index number
---@return string
function tabStatus(index)
    if index == 1 then
        return "stocked"
    end
    if index == 2 then
        return "craftable"
    end
    return "unavailable"
end

---@param status string
---@return number
function tabIndexForStatus(status)
    if status == "stocked" then
        return 1
    end
    if status == "craftable" then
        return 2
    end
    return 3
end

---@param size DisplaySize
---@return number
function rowsPerPage(size)
    local reserved = 2
    local available = size.height - reserved
    if available < 1 then
        return 1
    end
    return available
end

---@param size DisplaySize
---@param rowSlot number
---@return Rect
function itemRowRect(size, rowSlot)
    return Rect:new(1, 1 + rowSlot, size.width, 1)
end

---@param size DisplaySize
---@return number
function paginationFooterY(size)
    return size.height
end

---@param count number
---@param perPage number
---@return number
function totalPagesFor(count, perPage)
    if count == 0 then
        return 1
    end
    local remainder = count % perPage
    local pages = (count - remainder) / perPage
    if remainder > 0 then
        pages = ktox_plusAssign(pages, 1)
    end
    return pages
end

---@param fullName string
---@return string
function displayItemName(fullName)
    local parts = ktox_split(fullName, ":")
    if #(parts) < 2 then
        return fullName
    end
    return parts[2]
end

---@param qtyText string
---@param itemName string
---@param direction number
---@return string
function adjustQtyByStack(qtyText, itemName, direction)
    local stackSize = ktoxItemStackSize(itemName)
    local parsed = ktox_toDoubleOrNull(qtyText)
    local current = 0
    if parsed ~= nil then
        current = ktox_toInt(parsed)
    end
    local newQty = current + (stackSize * direction)
    if newQty < 0 then
        newQty = 0
    end
    return tostring(newQty)
end

---@return table
function pickupLocationNames()
    local raw = ktoxConfigPickupVaultNames()
    if raw == "" then
        return {}
    end
    return ktox_split(raw, ",")
end

---@param locationIndex number
---@return string
function locationLabel(locationIndex)
    if locationIndex == -1 then
        return "(auto)"
    end
    local names = pickupLocationNames()
    if locationIndex < 1 or locationIndex > #(names) then
        return "(auto)"
    end
    return names[locationIndex]
end

---@param locationIndex number
---@return string
function locationFlag(locationIndex)
    if locationIndex == -1 then
        return ""
    end
    local names = pickupLocationNames()
    if locationIndex < 1 or locationIndex > #(names) then
        return ""
    end
    return " --location=" .. tostring(names[locationIndex])
end

---@param locationIndex number
---@return number
function nextLocationIndex(locationIndex)
    local names = pickupLocationNames()
    if #(names) == 0 then
        return -1
    end
    if locationIndex < 1 then
        return 1
    end
    if locationIndex >= #(names) then
        return -1
    end
    return locationIndex + 1
end

---@return Rect
function detailBackRect()
    return Rect:new(1, 1, 8, 1)
end

STACK_BUTTON_W = 3

---@param size DisplaySize
---@return Rect
function detailQtyRect(size)
    return Rect:new(1, 2, size.width - (STACK_BUTTON_W * 2), 1)
end

---@param size DisplaySize
---@return Rect
function detailQtyDownRect(size)
    return Rect:new(size.width - (STACK_BUTTON_W * 2) + 1, 2, STACK_BUTTON_W, 1)
end

---@param size DisplaySize
---@return Rect
function detailQtyUpRect(size)
    return Rect:new(size.width - STACK_BUTTON_W + 1, 2, STACK_BUTTON_W, 1)
end

---@param size DisplaySize
---@return Rect
function detailLocationRect(size)
    return Rect:new(1, 3, size.width, 1)
end

---@param size DisplaySize
---@return Rect
function detailFetchCheckboxRect(size)
    return Rect:new(1, 4, size.width, 1)
end

---@param size DisplaySize
---@return Rect
function detailFetchButtonRect(size)
    return threeColumnRect(size, 1, 6, 2)
end

---@param size DisplaySize
---@return Rect
function detailCraftButtonRect(size)
    local fetchRect = detailFetchButtonRect(size)
    return Rect:new(fetchRect.x + fetchRect.w, 6, size.width - fetchRect.w, 2)
end

---@param state DashboardState
---@param size DisplaySize
function renderDashboard(state, size)
    if state.mode == "browse" then
        renderBrowse(state, size)
        return
    end
    renderDetail(state, size)
end

---@param state DashboardState
---@param size DisplaySize
function renderBrowse(state, size)
    displayClear()
    local i = 1
    while i <= 3 do
        local rect = tabRect(size, i)
        local bg = COLOR_GRAY
        if tabStatus(i) == state.tab then
            bg = COLOR_BLUE
        end
        displayFillRect(rect.x, rect.y, rect.w, rect.h, bg, COLOR_WHITE, tabLabel(i))
        i = ktox_plusAssign(i, 1)
    end
    local searchRect = searchButtonRect(size)
    local searchLabel = "Search"
    if state.searchText ~= "" then
        searchLabel = "\"" .. tostring(state.searchText) .. "\""
    end
    displayFillRect(searchRect.x, searchRect.y, searchRect.w, searchRect.h, COLOR_GRAY, COLOR_WHITE, searchLabel)
    local raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), state.tab, state.searchText)
    local rows = (raw == "" and {} or ktox_split(raw, "\n"))
    local perPage = rowsPerPage(size)
    local startIndex = 1 + (state.page - 1) * perPage
    local rowSlot = 1
    while rowSlot <= perPage do
        local dataIndex = startIndex + rowSlot - 1
        local rect = itemRowRect(size, rowSlot)
        if dataIndex <= #(rows) then
            local cols = ktox_split(rows[dataIndex], ",")
            local status = cols[1]
            local name = cols[2]
            local count = cols[3]
            local countText = count
            if status == "craftable" then
                countText = "craftable"
            elseif status == "unavailable" then
                countText = "-"
            end
            local label = tostring(displayItemName(name)) .. "  " .. tostring(countText)
            displayFillRect(rect.x, rect.y, rect.w, rect.h, COLOR_BLACK, COLOR_WHITE, label)
        end
        rowSlot = ktox_plusAssign(rowSlot, 1)
    end
    local totalPages = totalPagesFor(#(rows), perPage)
    local footerY = paginationFooterY(size)
    if state.page > 1 then
        displayFillRect(1, footerY, 6, 1, COLOR_GRAY, COLOR_WHITE, "<Prev")
    end
    if state.page < totalPages then
        displayFillRect(size.width - 5, footerY, 6, 1, COLOR_GRAY, COLOR_WHITE, "Next>")
    end
    displayFillRect(7, footerY, size.width - 12, 1, COLOR_BLACK, COLOR_GRAY, "Page " .. tostring(state.page) .. "/" .. tostring(totalPages))
end

---@param state DashboardState
---@param size DisplaySize
function renderDetail(state, size)
    displayClear()
    local backRect = detailBackRect()
    displayFillRect(backRect.x, backRect.y, backRect.w, backRect.h, COLOR_GRAY, COLOR_WHITE, "<Back")
    displayFillRect(backRect.x + backRect.w + 1, 1, size.width - backRect.w - 1, 1, COLOR_BLACK, COLOR_WHITE, tostring(displayItemName(state.selectedItem)) .. " (" .. tostring(state.selectedCount) .. ")")
    local qtyRect = detailQtyRect(size)
    displayFillRect(qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h, COLOR_BLACK, COLOR_WHITE, "Qty: " .. tostring(state.qtyText) .. " (tap to type)")
    local qtyDownRect = detailQtyDownRect(size)
    displayFillRect(qtyDownRect.x, qtyDownRect.y, qtyDownRect.w, qtyDownRect.h, COLOR_GRAY, COLOR_WHITE, "v")
    local qtyUpRect = detailQtyUpRect(size)
    displayFillRect(qtyUpRect.x, qtyUpRect.y, qtyUpRect.w, qtyUpRect.h, COLOR_GRAY, COLOR_WHITE, "^")
    local locationRect = detailLocationRect(size)
    displayFillRect(locationRect.x, locationRect.y, locationRect.w, locationRect.h, COLOR_BLACK, COLOR_WHITE, "Location: " .. tostring(locationLabel(state.locationIndex)) .. " (tap to cycle)")
    local checkboxRect = detailFetchCheckboxRect(size)
    local checkboxLabel = "(off) Fetch after craft"
    if state.fetchChecked then
        checkboxLabel = "(ON) Fetch after craft"
    end
    displayFillRect(checkboxRect.x, checkboxRect.y, checkboxRect.w, checkboxRect.h, COLOR_BLACK, COLOR_WHITE, checkboxLabel)
    if state.selectedStatus == "stocked" then
        local fetchRect = detailFetchButtonRect(size)
        displayFillRect(fetchRect.x, fetchRect.y, fetchRect.w, fetchRect.h, COLOR_LIME, COLOR_BLACK, "FETCH")
    end
    local craftRect = detailCraftButtonRect(size)
    displayFillRect(craftRect.x, craftRect.y, craftRect.w, craftRect.h, COLOR_BLUE, COLOR_WHITE, "CRAFT")
end

---@param state DashboardState
---@param touch Touch
---@param size DisplaySize
---@return DashboardState
function handleDashboardTouch(state, touch, size)
    if state.mode == "browse" then
        return handleBrowseTouch(state, touch, size)
    end
    return handleDetailTouch(state, touch, size)
end

---@param state DashboardState
---@param touch Touch
---@param size DisplaySize
---@return DashboardState
function handleBrowseTouch(state, touch, size)
    local i = 1
    while i <= 3 do
        local rect = tabRect(size, i)
        if touchInRect(touch, rect.x, rect.y, rect.w, rect.h) then
            return DashboardState:new("browse", tabStatus(i), 1, "", "", "", "1", true, -1, "", state.searchText)
        end
        i = ktox_plusAssign(i, 1)
    end
    local searchRect = searchButtonRect(size)
    if touchInRect(touch, searchRect.x, searchRect.y, searchRect.w, searchRect.h) then
        return DashboardState:new("searchentry", state.tab, state.page, "", "", "", "1", true, -1, "", state.searchText)
    end
    local raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), state.tab, state.searchText)
    local rows = (raw == "" and {} or ktox_split(raw, "\n"))
    local perPage = rowsPerPage(size)
    local totalPages = totalPagesFor(#(rows), perPage)
    local footerY = paginationFooterY(size)
    if state.page > 1 and touchInRect(touch, 1, footerY, 6, 1) then
        return DashboardState:new("browse", state.tab, state.page - 1, "", "", "", "1", true, -1, "", state.searchText)
    end
    if state.page < totalPages and touchInRect(touch, size.width - 5, footerY, 6, 1) then
        return DashboardState:new("browse", state.tab, state.page + 1, "", "", "", "1", true, -1, "", state.searchText)
    end
    local startIndex = 1 + (state.page - 1) * perPage
    local rowSlot = 1
    while rowSlot <= perPage do
        local rect = itemRowRect(size, rowSlot)
        if touchInRect(touch, rect.x, rect.y, rect.w, rect.h) then
            local dataIndex = startIndex + rowSlot - 1
            if dataIndex <= #(rows) then
                local cols = ktox_split(rows[dataIndex], ",")
                local status = cols[1]
                local name = cols[2]
                local count = cols[3]
                local countText = count
                if status == "craftable" then
                    countText = "craftable"
                elseif status == "unavailable" then
                    countText = "-"
                end
                return DashboardState:new("detail", state.tab, state.page, name, status, countText, "1", true, -1, "", state.searchText)
            end
        end
        rowSlot = ktox_plusAssign(rowSlot, 1)
    end
    return state
end

---@param state DashboardState
---@param touch Touch
---@param size DisplaySize
---@return DashboardState
function handleDetailTouch(state, touch, size)
    local backRect = detailBackRect()
    if touchInRect(touch, backRect.x, backRect.y, backRect.w, backRect.h) then
        return DashboardState:new("browse", state.tab, state.page, "", "", "", "1", true, -1, "", state.searchText)
    end
    local qtyRect = detailQtyRect(size)
    if touchInRect(touch, qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h) then
        return DashboardState:new("qtyentry", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, "", state.searchText)
    end
    local qtyDownRect = detailQtyDownRect(size)
    if touchInRect(touch, qtyDownRect.x, qtyDownRect.y, qtyDownRect.w, qtyDownRect.h) then
        local newQty = adjustQtyByStack(state.qtyText, state.selectedItem, -1)
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "", state.searchText)
    end
    local qtyUpRect = detailQtyUpRect(size)
    if touchInRect(touch, qtyUpRect.x, qtyUpRect.y, qtyUpRect.w, qtyUpRect.h) then
        local newQty = adjustQtyByStack(state.qtyText, state.selectedItem, 1)
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "", state.searchText)
    end
    local locationRect = detailLocationRect(size)
    if touchInRect(touch, locationRect.x, locationRect.y, locationRect.w, locationRect.h) then
        local newIndex = nextLocationIndex(state.locationIndex)
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, newIndex, "", state.searchText)
    end
    local checkboxRect = detailFetchCheckboxRect(size)
    if touchInRect(touch, checkboxRect.x, checkboxRect.y, checkboxRect.w, checkboxRect.h) then
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, not state.fetchChecked, state.locationIndex, "", state.searchText)
    end
    local qty = ktox_toDoubleOrNull(state.qtyText)
    if qty ~= nil and qty > 0.0 then
        if state.selectedStatus == "stocked" then
            local fetchRect = detailFetchButtonRect(size)
            if touchInRect(touch, fetchRect.x, fetchRect.y, fetchRect.w, fetchRect.h) then
                local command = "pull " .. tostring(state.selectedItem) .. " " .. tostring(state.qtyText) .. tostring(locationFlag(state.locationIndex))
                return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, command, state.searchText)
            end
        end
        local craftRect = detailCraftButtonRect(size)
        if touchInRect(touch, craftRect.x, craftRect.y, craftRect.w, craftRect.h) then
            local fetchFlag = ""
            if not state.fetchChecked then
                fetchFlag = " --fetch=false"
            end
            local command = "craft " .. tostring(state.selectedItem) .. " " .. tostring(state.qtyText) .. tostring(locationFlag(state.locationIndex)) .. tostring(fetchFlag)
            return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, command, state.searchText)
        end
    end
    return state
end

