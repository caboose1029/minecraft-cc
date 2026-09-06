-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "TestMonitor.kt", {["1-10"]=1,["11"]=22,["12"]=23,["13"]=24,["14-15"]=25,["16"]=28,["17"]=29,["18"]=30,["19-20"]=31,["21"]=36,["22"]=37,["23"]=38,["24"]=40,["25"]=41,["26"]=46,["27"]=47,["28"]=48,["29"]=49,["30"]=51,["31"]=52,["32"]=54,["33"]=55,["34"]=56,["35"]=57,["36"]=58,["37"]=59,["38"]=60,["39"]=61,["40"]=62,["41-48"]=63}, "programs")

TEST_MONITOR_LIME = 32

TEST_MONITOR_GREEN = 8192

local function main()
    local cleared = ktoxMonitorClear()
    if not cleared then
        println("No monitor peripheral found - attach one and try again.")
        return
    end
    local sizeRaw = ktoxMonitorGetSize()
    if sizeRaw == nil then
        println("Monitor disappeared before size could be read.")
        return
    end
    local sizeParts = ktox_split(sizeRaw, ",")
    local monitorW = ktox_toInt(ktox_toDouble(sizeParts[1]))
    local monitorH = ktox_toInt(ktox_toDouble(sizeParts[2]))
    local buttonW = 11
    local buttonH = 3
    local diffX = monitorW - buttonW
    local diffY = monitorH - buttonH
    local buttonX = 1 + (diffX - diffX % 2) / 2
    local buttonY = 1 + (diffY - diffY % 2) / 2
    ktoxMonitorDrawButton(buttonX, buttonY, buttonW, buttonH, "PRESS ME", TEST_MONITOR_LIME)
    println("Button drawn. Waiting for a monitor touch...")
    local pressed = false
    while not pressed do
        local touchRaw = ktoxWaitMonitorTouch()
        local touchParts = ktox_split(touchRaw, ",")
        local touchX = ktox_toInt(ktox_toDouble(touchParts[1]))
        local touchY = ktox_toInt(ktox_toDouble(touchParts[2]))
        if touchX >= buttonX and touchX < buttonX + buttonW and touchY >= buttonY and touchY < buttonY + buttonH then
            ktoxMonitorDrawButton(buttonX, buttonY, buttonW, buttonH, "PRESSED!", TEST_MONITOR_GREEN)
            println("Button pressed at (" .. tostring(touchX) .. ", " .. tostring(touchY) .. ").")
            pressed = true
        end
    end
end


-- Auto-generated call to main function
main()
