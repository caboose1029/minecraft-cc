-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Dashboard.kt", {["1-135"]=1,["136-140"]=62,["141"]=70,["142"]=71,["143"]=72,["144"]=73,["145"]=74,["146"]=75,["147-148"]=76,["149-157"]=78,["158"]=85,["159"]=86,["160"]=87,["161"]=88,["162-163"]=89,["164"]=91,["165-166"]=92,["167-173"]=94,["174-179"]=98,["180"]=102,["181-182"]=103,["183"]=105,["184-185"]=106,["186-191"]=108,["192"]=112,["193-194"]=113,["195"]=115,["196-197"]=116,["198-203"]=118,["204"]=122,["205-206"]=123,["207"]=125,["208-209"]=126,["210-215"]=128,["216"]=132,["217"]=133,["218"]=134,["219-220"]=135,["221-227"]=137,["228-233"]=141,["234-240"]=145,["241"]=149,["242-243"]=150,["244"]=152,["245"]=153,["246"]=154,["247-248"]=155,["249-254"]=157,["255"]=164,["256"]=165,["257-258"]=166,["259-263"]=168,["264"]=172,["265"]=173,["266-267"]=174,["268-273"]=176,["274"]=180,["275-276"]=181,["277"]=183,["278"]=184,["279-280"]=185,["281-286"]=187,["287"]=191,["288-289"]=192,["290"]=194,["291"]=195,["292-293"]=196,["294-299"]=198,["300"]=202,["301"]=203,["302-303"]=204,["304"]=206,["305-306"]=207,["307"]=209,["308-309"]=210,["310-314"]=212,["315-320"]=219,["321-326"]=223,["327-332"]=227,["333-338"]=231,["339-344"]=235,["345"]=239,["346-351"]=240,["352-359"]=246,["360-366"]=250,["367"]=254,["368"]=255,["369-370"]=256,["371"]=258,["372-373"]=259,["374-375"]=261,["376"]=263,["377"]=264,["378-379"]=265,["380"]=267,["381-382"]=268,["383-384"]=270,["385"]=272,["386"]=273,["387-388"]=274,["389"]=276,["390-391"]=277,["392-393"]=279,["394"]=281,["395-396"]=282,["397"]=284,["398-399"]=285,["400-405"]=287,["406"]=293,["407"]=294,["408-409"]=295,["410"]=297,["411"]=298,["412-413"]=299,["414-419"]=301,["420"]=305,["421"]=307,["422"]=308,["423"]=309,["424"]=310,["425"]=311,["426-427"]=312,["428"]=314,["429-430"]=315,["431"]=318,["432"]=319,["433"]=320,["434"]=321,["435"]=323,["436"]=324,["437"]=325,["438"]=326,["439"]=327,["440"]=328,["441"]=329,["442"]=330,["443"]=331,["444"]=332,["445"]=333,["446-447"]=334,["448-449"]=336,["450"]=338,["451-452"]=339,["453-454"]=341,["455"]=344,["456"]=345,["457"]=346,["458-459"]=347,["460"]=349,["461-462"]=350,["463-468"]=352,["469"]=356,["470"]=358,["471"]=359,["472"]=360,["473"]=366,["474"]=367,["475"]=369,["476"]=370,["477"]=372,["478"]=376,["479"]=377,["480-481"]=378,["482"]=380,["483"]=382,["484"]=383,["485-486"]=384,["487"]=386,["488-493"]=387,["494"]=391,["495"]=392,["496"]=394,["497"]=395,["498"]=396,["499"]=397,["500"]=398,["501"]=399,["502"]=400,["503"]=401,["504"]=402,["505"]=403,["506-507"]=404,["508"]=406,["509-510"]=407,["511"]=409,["512-513"]=410,["514-522"]=412,["523"]=419,["524-525"]=420,["526"]=422,["527-528"]=423,["529-536"]=425,["537"]=429,["538"]=430,["539"]=431,["540"]=432,["541-542"]=433,["543-544"]=435,["545"]=438,["546"]=439,["547"]=440,["548"]=441,["549"]=442,["550"]=444,["551-552"]=445,["553"]=447,["554-555"]=448,["556"]=451,["557"]=452,["558"]=453,["559"]=454,["560"]=455,["561"]=456,["562"]=457,["563"]=458,["564"]=459,["565"]=460,["566"]=461,["567"]=462,["568"]=463,["569-570"]=464,["571-572"]=466,["573-575"]=468,["576-577"]=471,["578-585"]=474,["586"]=478,["587"]=479,["588-589"]=480,["590"]=483,["591"]=484,["592-593"]=485,["594"]=488,["595"]=489,["596"]=490,["597-598"]=491,["599"]=494,["600"]=495,["601-602"]=496,["603"]=499,["604"]=500,["605"]=501,["606"]=502,["607"]=503,["608"]=504,["609-611"]=505,["612"]=508,["613"]=509,["614"]=510,["615"]=511,["616-617"]=512,["618"]=514,["619-621"]=515,["622-629"]=519,["630"]=523,["631"]=524,["632"]=525,["633"]=526,["634"]=527,["635"]=528,["636"]=529,["637"]=530,["638"]=531,["639"]=532,["640-641"]=533,["642-643"]=535,["644"]=537,["645"]=538,["646"]=539,["647-648"]=540,["649"]=542,["650-651"]=543,["652-653"]=545,["654"]=547,["655"]=548,["656-657"]=549,["658-659"]=551,["660-661"]=553,["662-663"]=555,["664-665"]=557,["666-668"]=559}, "lib")
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

