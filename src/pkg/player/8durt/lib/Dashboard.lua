-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Dashboard.kt", {["1-141"]=1,["142-146"]=76,["147"]=88,["148"]=89,["149"]=90,["150"]=91,["151"]=92,["152-153"]=93,["154"]=95,["155-156"]=96,["157"]=98,["158"]=99,["159"]=100,["160-162"]=101,["163-168"]=104,["169"]=112,["170"]=113,["171"]=114,["172"]=115,["173"]=116,["174"]=117,["175-176"]=118,["177"]=120,["178"]=121,["179-180"]=122,["181-186"]=124,["187"]=132,["188"]=133,["189"]=134,["190"]=135,["191-195"]=136,["196"]=147,["197"]=148,["198-202"]=149,["203"]=159,["204"]=160,["205"]=161,["206"]=162,["207-215"]=163,["216"]=170,["217"]=171,["218"]=172,["219"]=173,["220-221"]=174,["222"]=176,["223-224"]=177,["225-231"]=179,["232"]=184,["233"]=185,["234"]=186,["235"]=187,["236-237"]=188,["238"]=190,["239-240"]=191,["241"]=193,["242-243"]=194,["244-250"]=196,["251-256"]=200,["257-262"]=204,["263"]=208,["264-265"]=209,["266"]=211,["267-268"]=212,["269-274"]=214,["275"]=218,["276-277"]=219,["278"]=221,["279-280"]=222,["281-286"]=224,["287"]=228,["288-289"]=229,["290"]=231,["291-292"]=232,["293-298"]=234,["299"]=238,["300"]=239,["301"]=240,["302-303"]=241,["304-310"]=243,["311-316"]=247,["317-323"]=251,["324"]=255,["325-326"]=256,["327"]=258,["328"]=259,["329"]=260,["330-331"]=261,["332-337"]=263,["338"]=270,["339"]=271,["340-341"]=272,["342-349"]=274,["350"]=286,["351"]=287,["352"]=288,["353"]=289,["354-355"]=290,["356"]=292,["357"]=293,["358-359"]=294,["360-364"]=296,["365"]=300,["366"]=301,["367-368"]=302,["369-374"]=304,["375"]=308,["376-377"]=309,["378"]=311,["379"]=312,["380-381"]=313,["382-387"]=315,["388"]=319,["389-390"]=320,["391"]=322,["392"]=323,["393-394"]=324,["395-400"]=326,["401"]=330,["402"]=331,["403-404"]=332,["405"]=334,["406-407"]=335,["408"]=337,["409-410"]=338,["411-415"]=340,["416-423"]=347,["424-429"]=355,["430-435"]=359,["436-441"]=363,["442-447"]=367,["448-453"]=371,["454-459"]=375,["460"]=379,["461-466"]=380,["467"]=386,["468"]=387,["469-470"]=388,["471-476"]=390,["477"]=394,["478"]=396,["479"]=397,["480"]=398,["481"]=399,["482"]=400,["483-484"]=401,["485"]=403,["486-487"]=404,["488"]=407,["489"]=408,["490"]=409,["491-492"]=410,["493"]=412,["494"]=414,["495"]=415,["496"]=416,["497"]=417,["498"]=419,["499"]=420,["500"]=421,["501"]=422,["502"]=423,["503"]=424,["504"]=425,["505"]=426,["506"]=427,["507"]=428,["508"]=429,["509-510"]=430,["511-512"]=432,["513"]=434,["514-515"]=435,["516-517"]=437,["518"]=440,["519"]=441,["520"]=442,["521-522"]=443,["523"]=445,["524-525"]=446,["526-531"]=448,["532"]=452,["533"]=454,["534"]=455,["535"]=456,["536"]=462,["537"]=463,["538"]=464,["539"]=465,["540"]=466,["541"]=467,["542"]=469,["543"]=470,["544"]=472,["545"]=476,["546"]=477,["547-548"]=478,["549"]=480,["550"]=482,["551"]=483,["552-553"]=484,["554"]=486,["555-562"]=487,["563"]=499,["564-565"]=500,["566-573"]=502,["574"]=506,["575"]=507,["576"]=508,["577"]=509,["578-579"]=510,["580-581"]=512,["582"]=515,["583"]=516,["584-585"]=517,["586"]=520,["587"]=521,["588"]=522,["589"]=523,["590"]=524,["591"]=526,["592-593"]=527,["594"]=529,["595-596"]=530,["597"]=533,["598"]=534,["599"]=535,["600"]=536,["601"]=537,["602"]=538,["603"]=539,["604"]=540,["605"]=541,["606"]=542,["607"]=543,["608"]=544,["609"]=545,["610-611"]=546,["612-613"]=548,["614-616"]=550,["617-618"]=553,["619-626"]=556,["627"]=560,["628"]=561,["629-630"]=562,["631"]=565,["632"]=566,["633-634"]=567,["635"]=570,["636"]=571,["637"]=572,["638-639"]=573,["640"]=576,["641"]=577,["642"]=578,["643-644"]=579,["645"]=582,["646"]=583,["647"]=584,["648-649"]=585,["650"]=588,["651"]=589,["652-653"]=590,["654"]=593,["655"]=594,["656"]=595,["657"]=596,["658"]=597,["659"]=598,["660-662"]=599,["663"]=602,["664"]=603,["665"]=604,["666"]=605,["667-668"]=606,["669"]=608,["670-672"]=609,["673-675"]=613}, "lib")
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
function showDashboardBusy(message)
    displayClear()
    local size = displaySize()
    displayFillRect(1, 1, size.width, 1, COLOR_BLACK, COLOR_WHITE, message)
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

