-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Dashboard.kt", {["1-135"]=1,["136-140"]=74,["141"]=85,["142"]=86,["143"]=87,["144"]=88,["145"]=89,["146-147"]=90,["148"]=92,["149"]=93,["150"]=94,["151-153"]=95,["154-159"]=98,["160"]=106,["161"]=107,["162"]=108,["163"]=109,["164"]=110,["165"]=111,["166-167"]=112,["168"]=114,["169"]=115,["170-171"]=116,["172-176"]=118,["177"]=128,["178"]=129,["179"]=130,["180"]=131,["181-189"]=132,["190"]=139,["191"]=140,["192"]=141,["193"]=142,["194-195"]=143,["196"]=145,["197-198"]=146,["199-205"]=148,["206-211"]=152,["212"]=156,["213-214"]=157,["215"]=159,["216-217"]=160,["218-223"]=162,["224"]=166,["225-226"]=167,["227"]=169,["228-229"]=170,["230-235"]=172,["236"]=176,["237-238"]=177,["239"]=179,["240-241"]=180,["242-247"]=182,["248"]=186,["249"]=187,["250"]=188,["251-252"]=189,["253-259"]=191,["260-265"]=195,["266-272"]=199,["273"]=203,["274-275"]=204,["276"]=206,["277"]=207,["278"]=208,["279-280"]=209,["281-286"]=211,["287"]=218,["288"]=219,["289-290"]=220,["291-298"]=222,["299"]=234,["300"]=235,["301"]=236,["302"]=237,["303-304"]=238,["305"]=240,["306"]=241,["307-308"]=242,["309-313"]=244,["314"]=248,["315"]=249,["316-317"]=250,["318-323"]=252,["324"]=256,["325-326"]=257,["327"]=259,["328"]=260,["329-330"]=261,["331-336"]=263,["337"]=267,["338-339"]=268,["340"]=270,["341"]=271,["342-343"]=272,["344-349"]=274,["350"]=278,["351"]=279,["352-353"]=280,["354"]=282,["355-356"]=283,["357"]=285,["358-359"]=286,["360-364"]=288,["365-372"]=295,["373-378"]=303,["379-384"]=307,["385-390"]=311,["391-396"]=315,["397-402"]=319,["403-408"]=323,["409"]=327,["410-415"]=328,["416"]=334,["417"]=335,["418-419"]=336,["420-425"]=338,["426"]=342,["427"]=344,["428"]=345,["429"]=346,["430"]=347,["431"]=348,["432-433"]=349,["434"]=351,["435-436"]=352,["437"]=355,["438"]=356,["439"]=357,["440"]=358,["441"]=360,["442"]=361,["443"]=362,["444"]=363,["445"]=364,["446"]=365,["447"]=366,["448"]=367,["449"]=368,["450"]=369,["451"]=370,["452-453"]=371,["454-455"]=373,["456"]=375,["457-458"]=376,["459-460"]=378,["461"]=381,["462"]=382,["463"]=383,["464-465"]=384,["466"]=386,["467-468"]=387,["469-474"]=389,["475"]=393,["476"]=395,["477"]=396,["478"]=397,["479"]=403,["480"]=404,["481"]=405,["482"]=406,["483"]=407,["484"]=408,["485"]=410,["486"]=411,["487"]=413,["488"]=417,["489"]=418,["490-491"]=419,["492"]=421,["493"]=423,["494"]=424,["495-496"]=425,["497"]=427,["498-505"]=428,["506"]=439,["507-508"]=440,["509-516"]=442,["517"]=446,["518"]=447,["519"]=448,["520"]=449,["521-522"]=450,["523-524"]=452,["525"]=455,["526"]=456,["527"]=457,["528"]=458,["529"]=459,["530"]=461,["531-532"]=462,["533"]=464,["534-535"]=465,["536"]=468,["537"]=469,["538"]=470,["539"]=471,["540"]=472,["541"]=473,["542"]=474,["543"]=475,["544"]=476,["545"]=477,["546"]=478,["547"]=479,["548"]=480,["549-550"]=481,["551-552"]=483,["553-555"]=485,["556-557"]=488,["558-565"]=491,["566"]=495,["567"]=496,["568-569"]=497,["570"]=500,["571"]=501,["572-573"]=502,["574"]=505,["575"]=506,["576"]=507,["577-578"]=508,["579"]=511,["580"]=512,["581"]=513,["582-583"]=514,["584"]=517,["585"]=518,["586"]=519,["587-588"]=520,["589"]=523,["590"]=524,["591-592"]=525,["593"]=528,["594"]=529,["595"]=530,["596"]=531,["597"]=532,["598"]=533,["599-601"]=534,["602"]=537,["603"]=538,["604"]=539,["605"]=540,["606-607"]=541,["608"]=543,["609-611"]=544,["612-614"]=548}, "lib")
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
        if state.mode == "qtyentry" then
            local newQty = promptForQuantity(state.qtyText)
            state = DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "")
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
        return DashboardState:new("qtyentry", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, "")
    end
    local qtyDownRect = detailQtyDownRect(size)
    if touchInRect(touch, qtyDownRect.x, qtyDownRect.y, qtyDownRect.w, qtyDownRect.h) then
        local newQty = adjustQtyByStack(state.qtyText, state.selectedItem, -1)
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "")
    end
    local qtyUpRect = detailQtyUpRect(size)
    if touchInRect(touch, qtyUpRect.x, qtyUpRect.y, qtyUpRect.w, qtyUpRect.h) then
        local newQty = adjustQtyByStack(state.qtyText, state.selectedItem, 1)
        return DashboardState:new("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "")
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

