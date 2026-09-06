-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Hello.kt", {["1-6"]=1,["7"]=10,["8"]=11,["9"]=12,["10"]=13,["11-16"]=14}, "programs")

local function main()
    println("Hello from ktox!")
    term.write("Computer #" .. tostring(os.getComputerID()))
    turtle.select(1)
    turtle.forward()
    println("Fuel: " .. tostring(turtle.getFuelLevel()))
end


-- Auto-generated call to main function
main()
