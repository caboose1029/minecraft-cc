-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Terminal.kt", {["1-7"]=1,["8"]=17,["9"]=18,["10"]=19,["11"]=20,["12-18"]=21}, "programs")
ktox_require("lib/Cli")

local function main()
    println("Vault terminal ready. Commands: list, pull, craft.")
    while true do
        term.write("> ")
        local commandLine = read()
        println(runCliCommand(commandLine))
    end
end


-- Auto-generated call to main function
main()
