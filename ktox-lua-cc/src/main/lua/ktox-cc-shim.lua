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
