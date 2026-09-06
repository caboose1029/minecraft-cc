plugins {
    kotlin("jvm") version "2.3.10"
    id("com.isycat.ktox.lua") version "0.2.4b"
}

repositories {
    mavenCentral()
}

dependencies {
    compileOnly("com.isycat:ktox-lua:0.2.4b")
    // @NativeName / externalSource() — resolved transitively via ktox-lua,
    // but declared explicitly since Turtle.kt imports it directly.
    compileOnly("com.isycat:ktox-annotations:0.2.4b")
}

// Writes straight into the monorepo's shared src/ tree (moonman's manifest
// source.base_url is ".../src") rather than a local outputDir — this way
// moonman can serve the generated Lua with zero changes to moonman.lua.
// player/8durt is a per-player namespace under pkg/, mirroring the
// src/player/<name>/ convention used elsewhere in this repo, since our
// output is package-shaped (entry point + files + deps) rather than a
// single standalone script.
val luaOutputDir = layout.projectDirectory.dir("../src/pkg/player/8durt")

kotlinToLua {
    // Generated Lua output, committed to source control — this is what gets
    // deployed to turtles/computers.
    outputDirectory = luaOutputDir

    // Strip this prefix from output paths / require() calls.
    rootNamespace = "programs"

    // Entry point executed by `./gradlew runLua` (a plain LuaJ interpreter —
    // not CC/turtle-aware; real validation happens via CraftOS-PC instead).
    luaEntryPoint = "Hello.lua"

    // `common.*` binds to CC/turtle globals that already exist at runtime
    // (turtle, os, term, fs, ...) — must not be wrapped in require().
    skipRequirePackages = setOf("common")
}

// Hand-written (not ktox-generated) Lua support files: the multi-return
// native-binding shim and the startup script that loads it. See AGENTS.md.
val copyLuaRuntime =
    tasks.register<Copy>("copyLuaRuntime") {
        from("src/main/lua")
        into(luaOutputDir)
    }

// ktox only auto-invokes `fun main()` (the zero-arg case, transpiled as a
// local function with a generated call appended). `fun main(args:
// Array<String>)` transpiles to a global `function main(args)` with NO
// invocation — CC's shell args arrive via `...` at the top of the file, so
// each such entry point needs `main({...})` appended after transpilation.
val wireProgramEntryPoints =
    tasks.register("wireProgramEntryPoints") {
        dependsOn("transpileKotlinToLua")
        doLast {
            luaOutputDir.asFile.listFiles { f -> f.isFile && f.extension == "lua" }
                ?.forEach { file ->
                    val text = file.readText()
                    val hasArgsMain = Regex("""(?m)^function main\(args\)""").containsMatchIn(text)
                    val alreadyWired = text.trimEnd().endsWith("main({...})")
                    if (hasArgsMain && !alreadyWired) {
                        file.appendText("\nmain({...})\n")
                    }
                }
        }
    }

tasks.named("assemble") {
    dependsOn(copyLuaRuntime, wireProgramEntryPoints)
}
