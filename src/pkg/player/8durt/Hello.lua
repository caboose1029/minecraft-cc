-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Hello.kt", {["1-6"]=1,["7-12"]=13}, "programs")

local function main()
    println("Hello from ktox!")
end


-- Auto-generated call to main function
main()
