package programs

// Minimal smoke-test entry point for `./gradlew runLua` (a plain LuaJ
// interpreter, not CC/turtle-aware - see build.gradle.kts' luaEntryPoint
// comment). Deliberately has zero CC-specific calls (no turtle/os/fs/term
// bindings) - the original Hello.kt used several (turtleForward,
// osGetComputerID, ...) and was removed as vestigial, which left
// luaEntryPoint pointing at a file that no longer existed. Real
// validation of actual programs happens via CraftOS-PC
// (scripts/validate.sh), not this - this only proves the ktox-lua
// toolchain itself (transpile + println's own runtime) is working.
fun main() {
    println("Hello from ktox!")
}
