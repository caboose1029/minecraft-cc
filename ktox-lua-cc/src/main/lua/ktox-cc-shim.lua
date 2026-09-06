-- Hand-written, not ktox-generated. Small purpose-built wrappers around
-- CC:Tweaked native functions that return multiple Lua values — Kotlin
-- functions can only return one value, so these narrow each call down to
-- exactly what's needed, as a single Kotlin-representable value (a scalar,
-- or a comma-joined string for gpsLocate). See AGENTS.md and Gps.kt/
-- Turtle.kt for the Kotlin side of this binding.
--
-- Loaded once at boot by startup.lua, so these are plain globals by the
-- time any program runs.

function ktoxGpsLocate(timeout)
    local x, y, z = gps.locate(timeout)
    if x == nil then
        return nil
    end
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

function ktoxInspectName()
    local ok, data = turtle.inspect()
    if not ok then
        return nil
    end
    return data.name
end

function ktoxInspectUpName()
    local ok, data = turtle.inspectUp()
    if not ok then
        return nil
    end
    return data.name
end

function ktoxInspectDownName()
    local ok, data = turtle.inspectDown()
    if not ok then
        return nil
    end
    return data.name
end

-- turtle.getItemDetail() returns a whole table; narrow to just the name.
-- See common/Turtle.kt.
function ktoxGetItemName(slot)
    local detail = turtle.getItemDetail(slot)
    if detail == nil then
        return nil
    end
    return detail.name
end

-- Wraps http.get()'s response handle and fs.open()'s write handle, neither
-- of which Kotlin can model directly. See common/Http.kt.
function ktoxDownloadFile(url, path)
    local response = http.get(url, nil, true)
    if response == nil then
        return false
    end
    local data = response.readAll()
    response.close()
    if data == nil then
        return false
    end
    local file = fs.open(path, "wb")
    if file == nil then
        return false
    end
    file.write(data)
    file.close()
    return true
end

-- Monitor test-GUI helpers. Assumes exactly one monitor peripheral on the
-- network (peripheral.find("monitor") returns the first match) — fine for
-- a single-monitor test rig, not meant to generalize to multiple monitors.
-- See common/Monitor.kt for the Kotlin side of this binding.

function ktoxMonitorClear()
    local m = peripheral.find("monitor")
    if m == nil then
        return false
    end
    m.setTextScale(1)
    m.setBackgroundColor(colors.black)
    m.clear()
    return true
end

-- monitor.getSize() returns 2 values in Lua; packed as a comma-joined
-- string, same idiom as ktoxGpsLocate. See lib/Position.kt for the parsed
-- gps equivalent this mirrors.
function ktoxMonitorGetSize()
    local m = peripheral.find("monitor")
    if m == nil then
        return nil
    end
    local w, h = m.getSize()
    return tostring(w) .. "," .. tostring(h)
end

-- Draws a solid, centered-label rectangle "button" at (x, y), size (w, h),
-- filled with the given CC:Tweaked color constant.
function ktoxMonitorDrawButton(x, y, w, h, text, bgColor)
    local m = peripheral.find("monitor")
    if m == nil then
        return false
    end
    m.setBackgroundColor(bgColor)
    m.setTextColor(colors.white)
    local row = 0
    while row < h do
        m.setCursorPos(x, y + row)
        m.write(string.rep(" ", w))
        row = row + 1
    end
    local labelX = x + math.floor((w - #text) / 2)
    local labelY = y + math.floor(h / 2)
    m.setCursorPos(labelX, labelY)
    m.write(text)
    return true
end

-- Blocks until the monitor is touched; returns the touch coords packed as
-- a comma-joined "x,y" string (side is discarded — single-monitor rig).
function ktoxWaitMonitorTouch()
    local _, _, x, y = os.pullEvent("monitor_touch")
    return tostring(x) .. "," .. tostring(y)
end
