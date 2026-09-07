-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Dashboard.kt", {["1-135"]=1,["136-140"]=62,["141"]=70,["142"]=71,["143"]=72,["144"]=73,["145"]=74,["146"]=75,["147-148"]=76,["149-153"]=78,["154"]=91,["155"]=92,["156"]=93,["157"]=94,["158-166"]=95,["167"]=102,["168"]=103,["169"]=104,["170"]=105,["171-172"]=106,["173"]=108,["174-175"]=109,["176-182"]=111,["183-188"]=115,["189"]=119,["190-191"]=120,["192"]=122,["193-194"]=123,["195-200"]=125,["201"]=129,["202-203"]=130,["204"]=132,["205-206"]=133,["207-212"]=135,["213"]=139,["214-215"]=140,["216"]=142,["217-218"]=143,["219-224"]=145,["225"]=149,["226"]=150,["227"]=151,["228-229"]=152,["230-236"]=154,["237-242"]=158,["243-249"]=162,["250"]=166,["251-252"]=167,["253"]=169,["254"]=170,["255"]=171,["256-257"]=172,["258-263"]=174,["264"]=181,["265"]=182,["266-267"]=183,["268-272"]=185,["273"]=189,["274"]=190,["275-276"]=191,["277-282"]=193,["283"]=197,["284-285"]=198,["286"]=200,["287"]=201,["288-289"]=202,["290-295"]=204,["296"]=208,["297-298"]=209,["299"]=211,["300"]=212,["301-302"]=213,["303-308"]=215,["309"]=219,["310"]=220,["311-312"]=221,["313"]=223,["314-315"]=224,["316"]=226,["317-318"]=227,["319-323"]=229,["324-329"]=236,["330-335"]=240,["336-341"]=244,["342-347"]=248,["348-353"]=252,["354"]=256,["355-360"]=257,["361-368"]=263,["369-375"]=267,["376"]=271,["377"]=272,["378-379"]=273,["380"]=275,["381-382"]=276,["383-384"]=278,["385"]=280,["386"]=281,["387-388"]=282,["389"]=284,["390-391"]=285,["392-393"]=287,["394"]=289,["395"]=290,["396-397"]=291,["398"]=293,["399-400"]=294,["401-402"]=296,["403"]=298,["404-405"]=299,["406"]=301,["407-408"]=302,["409-414"]=304,["415"]=310,["416"]=311,["417-418"]=312,["419"]=314,["420"]=315,["421-422"]=316,["423-428"]=318,["429"]=322,["430"]=324,["431"]=325,["432"]=326,["433"]=327,["434"]=328,["435-436"]=329,["437"]=331,["438-439"]=332,["440"]=335,["441"]=336,["442"]=337,["443"]=338,["444"]=340,["445"]=341,["446"]=342,["447"]=343,["448"]=344,["449"]=345,["450"]=346,["451"]=347,["452"]=348,["453"]=349,["454"]=350,["455-456"]=351,["457-458"]=353,["459"]=355,["460-461"]=356,["462-463"]=358,["464"]=361,["465"]=362,["466"]=363,["467-468"]=364,["469"]=366,["470-471"]=367,["472-477"]=369,["478"]=373,["479"]=375,["480"]=376,["481"]=377,["482"]=383,["483"]=384,["484"]=386,["485"]=387,["486"]=389,["487"]=393,["488"]=394,["489-490"]=395,["491"]=397,["492"]=399,["493"]=400,["494-495"]=401,["496"]=403,["497-502"]=404,["503"]=408,["504"]=409,["505"]=411,["506"]=412,["507"]=413,["508"]=414,["509"]=415,["510"]=416,["511"]=417,["512"]=418,["513"]=419,["514"]=420,["515-516"]=421,["517"]=423,["518-519"]=424,["520"]=426,["521-522"]=427,["523-531"]=429,["532"]=436,["533-534"]=437,["535"]=439,["536-537"]=440,["538-545"]=442,["546"]=446,["547"]=447,["548"]=448,["549"]=449,["550-551"]=450,["552-553"]=452,["554"]=455,["555"]=456,["556"]=457,["557"]=458,["558"]=459,["559"]=461,["560-561"]=462,["562"]=464,["563-564"]=465,["565"]=468,["566"]=469,["567"]=470,["568"]=471,["569"]=472,["570"]=473,["571"]=474,["572"]=475,["573"]=476,["574"]=477,["575"]=478,["576"]=479,["577"]=480,["578-579"]=481,["580-581"]=483,["582-584"]=485,["585-586"]=488,["587-594"]=491,["595"]=495,["596"]=496,["597-598"]=497,["599"]=500,["600"]=501,["601-602"]=502,["603"]=505,["604"]=506,["605"]=507,["606-607"]=508,["608"]=511,["609"]=512,["610-611"]=513,["612"]=516,["613"]=517,["614"]=518,["615"]=519,["616"]=520,["617"]=521,["618-620"]=522,["621"]=525,["622"]=526,["623"]=527,["624"]=528,["625-626"]=529,["627"]=531,["628-630"]=532,["631-638"]=536,["639"]=540,["640"]=541,["641"]=542,["642"]=543,["643"]=544,["644"]=545,["645"]=546,["646"]=547,["647"]=548,["648"]=549,["649-650"]=550,["651-652"]=552,["653"]=554,["654"]=555,["655"]=556,["656-657"]=557,["658"]=559,["659-660"]=560,["661-662"]=562,["663"]=564,["664"]=565,["665-666"]=566,["667-668"]=568,["669-670"]=570,["671-672"]=572,["673-674"]=574,["675-677"]=576}, "lib")
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
DashboardState = {}
DashboardState.__index = DashboardState

function DashboardState:new(mode, tab, page, selectedItem, selectedStatus, selectedCount, qtyText, fetchChecked, locationIndex, readyCommand)
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
    return self
end

function DashboardState:equals(other)
    return self.mode == other.mode and self.tab == other.tab and self.page == other.page and self.selectedItem == other.selectedItem and self.selectedStatus == other.selectedStatus and self.selectedCount == other.selectedCount and self.qtyText == other.qtyText and self.fetchChecked == other.fetchChecked and self.locationIndex == other.locationIndex and self.readyCommand == other.readyCommand
end
DashboardState.__eq = function(a, b) return a:equals(b) end
function DashboardState:toString()
    return "DashboardState(" .. "mode=" .. tostring(self.mode) .. ", " .. "tab=" .. tostring(self.tab) .. ", " .. "page=" .. tostring(self.page) .. ", " .. "selectedItem=" .. tostring(self.selectedItem) .. ", " .. "selectedStatus=" .. tostring(self.selectedStatus) .. ", " .. "selectedCount=" .. tostring(self.selectedCount) .. ", " .. "qtyText=" .. tostring(self.qtyText) .. ", " .. "fetchChecked=" .. tostring(self.fetchChecked) .. ", " .. "locationIndex=" .. tostring(self.locationIndex) .. ", " .. "readyCommand=" .. tostring(self.readyCommand) .. ")"
end
DashboardState.__tostring = function(a) return a:toString() end
function DashboardState:copy(mode, tab, page, selectedItem, selectedStatus, selectedCount, qtyText, fetchChecked, locationIndex, readyCommand)
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
    return DashboardState:new(mode, tab, page, selectedItem, selectedStatus, selectedCount, qtyText, fetchChecked, locationIndex, readyCommand)
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

---@return DashboardState
function freshDashboardState()
    return DashboardState:new("browse", "stocked", 1, "", "", "", "1", true, -1, "")
end

---@return string
function runDashboardLoop()
    local state = freshDashboardState()
    displayInit()
    while state.readyCommand == "" do
        local size = displaySize()
        renderDashboard(state, size)
        local touch = displayWaitTouch()
        state = handleDashboardTouch(state, touch, size)
    end
    return state.readyCommand
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
---@param index number
---@return Rect
function tabRect(size, index)
    return threeColumnRect(size, index, 1, 1)
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

---@param size DisplaySize
---@return Rect
function detailQtyRect(size)
    return Rect:new(1, 2, size.width, 1)
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

---@param row number
---@return number
function keypadRowY(row)
    return 2 + row
end

---@param size DisplaySize
---@param row number
---@param col number
---@return Rect
function keypadKeyRect(size, row, col)
    return threeColumnRect(size, col, keypadRowY(row), 1)
end

---@param row number
---@param col number
---@return string
function keypadKeyLabel(row, col)
    if row == 1 then
        if col == 1 then
            return "7"
        end
        if col == 2 then
            return "8"
        end
        return "9"
    end
    if row == 2 then
        if col == 1 then
            return "4"
        end
        if col == 2 then
            return "5"
        end
        return "6"
    end
    if row == 3 then
        if col == 1 then
            return "1"
        end
        if col == 2 then
            return "2"
        end
        return "3"
    end
    if col == 1 then
        return "<-"
    end
    if col == 2 then
        return "0"
    end
    return "OK"
end

---@param state DashboardState
---@param size DisplaySize
function renderDashboard(state, size)
    if state.mode == "browse" then
        renderBrowse(state, size)
        return
    end
    if state.mode == "detail" then
        renderDetail(state, size)
        return
    end
    renderKeypad(state, size)
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
    local raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), state.tab, "")
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
    displayFillRect(7, footerY, size.width - 12, 1, COLOR_BLACK, COLOR_LIGHT_GRAY, "Page " .. tostring(state.page) .. "/" .. tostring(totalPages))
end

---@param state DashboardState
---@param size DisplaySize
function renderDetail(state, size)
    displayClear()
    local backRect = detailBackRect()
    displayFillRect(backRect.x, backRect.y, backRect.w, backRect.h, COLOR_GRAY, COLOR_WHITE, "<Back")
    displayFillRect(backRect.x + backRect.w + 1, 1, size.width - backRect.w - 1, 1, COLOR_BLACK, COLOR_WHITE, tostring(displayItemName(state.selectedItem)) .. " (" .. tostring(state.selectedCount) .. ")")
    local qtyRect = detailQtyRect(size)
    displayFillRect(qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h, COLOR_BLACK, COLOR_WHITE, "Qty: " .. tostring(state.qtyText) .. " (tap to edit)")
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
---@param size DisplaySize
function renderKeypad(state, size)
    displayClear()
    displayFillRect(1, 1, size.width, 1, COLOR_BLACK, COLOR_WHITE, "Enter quantity: " .. tostring(state.qtyText))
    local row = 1
    while row <= 4 do
        local col = 1
        while col <= 3 do
            local rect = keypadKeyRect(size, row, col)
            local bg = COLOR_LIGHT_GRAY
            local fg = COLOR_BLACK
            local label = keypadKeyLabel(row, col)
            if label == "OK" then
                bg = COLOR_GREEN
                fg = COLOR_BLACK
            elseif label == "<-" then
                bg = COLOR_RED
                fg = COLOR_WHITE
            end
            displayFillRect(rect.x, rect.y, rect.w, rect.h, bg, fg, label)
            col = ktox_plusAssign(col, 1)
        end
        row = ktox_plusAssign(row, 1)
    end
end

---@param state DashboardState
---@param touch Touch
---@param size DisplaySize
---@return DashboardState
function handleDashboardTouch(state, touch, size)
    if state.mode == "browse" then
        return handleBrowseTouch(state, touch, size)
    end
    if state.mode == "detail" then
        return handleDetailTouch(state, touch, size)
    end
    return handleKeypadTouch(state, touch, size)
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
            return DashboardState:new("browse", tabStatus(i), 1, "", "", "", "1", true, -1, "")
        end
        i = ktox_plusAssign(i, 1)
    end
    local raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), state.tab, "")
    local rows = (raw == "" and {} or ktox_split(raw, "\n"))
    local perPage = rowsPerPage(size)
    local totalPages = totalPagesFor(#(rows), perPage)
    local footerY = paginationFooterY(size)
    if state.page > 1 and touchInRect(touch, 1, footerY, 6, 1) then
        return DashboardState:new("browse", state.tab, state.page - 1, "", "", "", "1", true, -1, "")
    end
    if state.page < totalPages and touchInRect(touch, size.width - 5, footerY, 6, 1) then
        return DashboardState:new("browse", state.tab, state.page + 1, "", "", "", "1", true, -1, "")
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
                return DashboardState:new("detail", state.tab, state.page, name, status, countText, "1", true, -1, "")
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
        return DashboardState:new("browse", state.tab, state.page, "", "", "", "1", true, -1, "")
    end
    local qtyRect = detailQtyRect(size)
    if touchInRect(touch, qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h) then
        return DashboardState:new("keypad", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, "")
    end
    local locationRect = detailLocationRect(size)
    if touchInRect(touch, locationRect.x, locationRect.y, locationRect.w, locationRect.h) then
        local newIndex = nextLocationIndex(state.locationIndex)
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, newIndex, "")
    end
    local checkboxRect = detailFetchCheckboxRect(size)
    if touchInRect(touch, checkboxRect.x, checkboxRect.y, checkboxRect.w, checkboxRect.h) then
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, not state.fetchChecked, state.locationIndex, "")
    end
    local qty = ktox_toDoubleOrNull(state.qtyText)
    if qty ~= nil and qty > 0.0 then
        if state.selectedStatus == "stocked" then
            local fetchRect = detailFetchButtonRect(size)
            if touchInRect(touch, fetchRect.x, fetchRect.y, fetchRect.w, fetchRect.h) then
                local command = "pull " .. tostring(state.selectedItem) .. " " .. tostring(state.qtyText) .. tostring(locationFlag(state.locationIndex))
                return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, command)
            end
        end
        local craftRect = detailCraftButtonRect(size)
        if touchInRect(touch, craftRect.x, craftRect.y, craftRect.w, craftRect.h) then
            local fetchFlag = ""
            if not state.fetchChecked then
                fetchFlag = " --fetch=false"
            end
            local command = "craft " .. tostring(state.selectedItem) .. " " .. tostring(state.qtyText) .. tostring(locationFlag(state.locationIndex)) .. tostring(fetchFlag)
            return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, command)
        end
    end
    return state
end

---@param state DashboardState
---@param touch Touch
---@param size DisplaySize
---@return DashboardState
function handleKeypadTouch(state, touch, size)
    local row = 1
    while row <= 4 do
        local col = 1
        while col <= 3 do
            local rect = keypadKeyRect(size, row, col)
            if touchInRect(touch, rect.x, rect.y, rect.w, rect.h) then
                local label = keypadKeyLabel(row, col)
                if label == "OK" then
                    local qty = state.qtyText
                    if qty == "" then
                        qty = "1"
                    end
                    return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, qty, state.fetchChecked, state.locationIndex, "")
                end
                if label == "<-" then
                    local qty = state.qtyText
                    if qty ~= "" then
                        qty = ktoxDropLastChar(qty)
                    end
                    if qty == "" then
                        qty = "0"
                    end
                    return DashboardState:new("keypad", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, qty, state.fetchChecked, state.locationIndex, "")
                end
                local qty = state.qtyText
                if qty == "0" then
                    qty = label
                else
                    qty = tostring(qty) .. tostring(label)
                end
                return DashboardState:new("keypad", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, qty, state.fetchChecked, state.locationIndex, "")
            end
            col = ktox_plusAssign(col, 1)
        end
        row = ktox_plusAssign(row, 1)
    end
    return state
end

