--- Off-device test suite for moonman.
---
--- Runs the real domain and application code against fake ports: an in-memory
--- filesystem and an HTTP port that serves files straight out of the working
--- tree. That is the payoff of the ports layer -- everything except the CC
--- adapters is verifiable with plain Lua, no emulator required.
---
--- Usage (from the repository root):
---     lua tools/test_moonman.lua
---
--- On-device behaviour that this cannot cover -- require() resolution and the
--- fs/http adapters -- is exercised by "mise run verify".

package.path = "./?.lua;./?/init.lua;" .. package.path

-- --------------------------------------------------------------- JSON decode
-- Just enough JSON for the manifest; the real runtime uses textutils.
local function decodeJson(text)
  local pos = 1

  local function skipSpace()
    pos = text:find("[^ \t\r\n]", pos) or #text + 1
  end

  local parseValue

  local function parseString()
    pos = pos + 1
    local buf = {}
    while true do
      local char = text:sub(pos, pos)
      if char == "" then
        error("unterminated string at " .. pos)
      elseif char == '"' then
        pos = pos + 1
        break
      elseif char == "\\" then
        local escapes = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
        local escape = text:sub(pos + 1, pos + 1)
        if escapes[escape] then
          buf[#buf + 1] = escapes[escape]
          pos = pos + 2
        elseif escape == "u" then
          buf[#buf + 1] = "?"
          pos = pos + 6
        else
          error("bad escape \\" .. escape)
        end
      else
        buf[#buf + 1] = char
        pos = pos + 1
      end
    end
    return table.concat(buf)
  end

  local function parseObject()
    pos = pos + 1
    local result = {}
    skipSpace()
    if text:sub(pos, pos) == "}" then
      pos = pos + 1
      return result
    end
    while true do
      skipSpace()
      local key = parseString()
      skipSpace()
      pos = pos + 1 -- ':'
      result[key] = parseValue()
      skipSpace()
      local char = text:sub(pos, pos)
      pos = pos + 1
      if char == "}" then
        return result
      end
    end
  end

  local function parseArray()
    pos = pos + 1
    local result = {}
    skipSpace()
    if text:sub(pos, pos) == "]" then
      pos = pos + 1
      return result
    end
    while true do
      result[#result + 1] = parseValue()
      skipSpace()
      local char = text:sub(pos, pos)
      pos = pos + 1
      if char == "]" then
        return result
      end
    end
  end

  parseValue = function()
    skipSpace()
    local char = text:sub(pos, pos)
    if char == "{" then
      return parseObject()
    elseif char == "[" then
      return parseArray()
    elseif char == '"' then
      return parseString()
    elseif text:sub(pos, pos + 3) == "true" then
      pos = pos + 4
      return true
    elseif text:sub(pos, pos + 4) == "false" then
      pos = pos + 5
      return false
    elseif text:sub(pos, pos + 3) == "null" then
      pos = pos + 4
      return nil
    end
    local number = text:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
    if number == nil then
      error("unexpected character '" .. char .. "' at " .. pos)
    end
    pos = pos + #number
    return tonumber(number)
  end

  return parseValue()
end

local function readFile(path)
  local handle = assert(io.open(path, "r"), "cannot open " .. path .. " (run from the repository root)")
  local contents = handle:read("a")
  handle:close()
  return contents
end

local MANIFEST = decodeJson(readFile("dist/manifest.json"))

-- ------------------------------------------------------- CC globals the app uses
_G.os.epoch = function()
  return 1700000000000
end
_G.printError = function(message)
  print("!! " .. tostring(message))
end
_G.write = io.write

-- ----------------------------------------------------------------- fake ports
local disk, dirs = {}, { ["/"] = true }

local function markParents(target)
  local segments, accumulated = {}, ""
  for segment in target:gmatch("[^/]+") do
    segments[#segments + 1] = segment
  end
  for index = 1, #segments - 1 do
    accumulated = accumulated .. "/" .. segments[index]
    dirs[accumulated] = true
  end
end

local function beneath(candidate, root)
  return candidate == root or candidate:sub(1, #root + 1) == root .. "/"
end

local fakeFs = {
  exists = function(target)
    return disk[target] ~= nil or dirs[target] == true
  end,
  isDir = function(target)
    return dirs[target] == true
  end,
  read = function(target)
    if disk[target] then
      return disk[target]
    end
    return nil, "not a file: " .. target
  end,
  write = function(target, contents)
    markParents(target)
    disk[target] = contents
    return true
  end,
  delete = function(target)
    for key in pairs(disk) do
      if beneath(key, target) then
        disk[key] = nil
      end
    end
    for key in pairs(dirs) do
      if beneath(key, target) then
        dirs[key] = nil
      end
    end
    return true
  end,
  pruneEmptyParents = function() end,
}

-- Tables are stashed by token, giving config and state an exact round-trip.
local stash, tokens = {}, 0
local fakeJson = {
  encode = function(value)
    tokens = tokens + 1
    local token = "@" .. tokens
    stash[token] = value
    return token
  end,
  decode = function(text)
    if text == "MANIFEST" then
      return MANIFEST
    end
    if stash[text] then
      return stash[text]
    end
    return nil, "unrecognised payload"
  end,
}

local fakeHttp = {
  get = function(url)
    if url:find("manifest%.json$") then
      return "MANIFEST"
    end
    local sourcePath = url:match("^https://raw%.githubusercontent%.com/[^/]+/[^/]+/[^/]+/(.+)$")
    local handle = sourcePath and io.open(sourcePath, "r")
    if handle == nil then
      return nil, "404 " .. url
    end
    local body = handle:read("a")
    handle:close()
    return body
  end,
}

local quiet = os.getenv("MOONMAN_TEST_VERBOSE") == nil
local function sink(prefix)
  return function(message)
    if not quiet then
      print(prefix .. tostring(message))
    end
  end
end
local fakeLog = {
  info = sink(""),
  detail = sink("  "),
  ok = sink("OK "),
  warn = sink("WARN "),
  error = sink("ERR "),
  field = function(key, value)
    sink("")(key .. ": " .. tostring(value))
  end,
}

local ports = { fs = fakeFs, http = fakeHttp, log = fakeLog, json = fakeJson }

-- ---------------------------------------------------------------- assertions
local checks, failures = 0, 0
local function check(name, condition, detail)
  checks = checks + 1
  if condition then
    print("  pass  " .. name)
  else
    failures = failures + 1
    print("  FAIL  " .. name .. (detail and ("  -- " .. tostring(detail)) or ""))
  end
end
local function section(title)
  print("\n" .. title)
end

local context = require("moonman.app.context")
local configModule = require("moonman.app.config")
local packages = require("moonman.app.packages")
local sync = require("moonman.app.sync")
local selfupdate = require("moonman.app.selfupdate")
local cliArgs = require("moonman.cli.args")
local cli = require("moonman.cli")
local manifestModule = require("moonman.domain.manifest")
local path = require("moonman.domain.path")

section("domain/path")
check("normalise collapses separators", path.normalise("/a//b/./c") == "/a/b/c")
check("normalise resolves ..", path.normalise("/a/b/../c") == "/a/c")
check("join builds absolute paths", path.join("/", "multi_test", "main.lua") == "/multi_test/main.lua")
check("dirname", path.dirname("/a/b/c.lua") == "/a/b")
check("dirname of a top-level file is /", path.dirname("/a.lua") == "/")
check("basename of a namespaced package", path.basename("caboose/test") == "test")
check("moduleToPath", path.moduleToPath("share.test.sharetest") == "share/test/sharetest.lua")
check("pathToModule folds init.lua", path.pathToModule("share/test/init.lua") == "share.test")
check("hasPrefix matches whole segments", path.hasPrefix("share/test/x.lua", "share/test"))
check("hasPrefix rejects partial segments", not path.hasPrefix("share/testing/x.lua", "share/test"))

section("domain/manifest")
local mf, parseErr = manifestModule.parse(MANIFEST)
check("manifest parses", mf ~= nil, parseErr)
check("schema guard rejects old manifests", select(2, manifestModule.parse({ schema = 1 })) ~= nil)
check("missing repo rejected", select(2, manifestModule.parse({ schema = 2 })) ~= nil)
check("leaf-name lookup resolves", (mf:findPackage("multi_test") or {}).name == "caboose/multi_test")
check("unknown package reports clearly", select(2, mf:findPackage("nope")) == "no such package: nope")
check("search finds by substring", #mf:search("multi") > 0)

section("cli/args")
local positional, flags = cliArgs.parse({ "a", "--as", "b", "--dry-run" }, { as = "string", ["dry-run"] = "boolean" })
check("positional arguments collected", positional and positional[1] == "a")
check("string flag with separate value", flags and flags.as == "b")
check("boolean flag", flags and flags["dry-run"] == true)
check("inline --flag=value", (select(2, cliArgs.parse({ "--into=/work" }, { into = "string" }))).into == "/work")
check("unknown flag rejected", select(2, cliArgs.parse({ "--nope" }, {})) == "unknown flag: --nope")
check("missing value rejected", select(2, cliArgs.parse({ "--as" }, { as = "string" })) ~= nil)

section("cli/registry")
check("every registered command loads", (function()
  local ok, err = pcall(cli.all)
  return ok, err
end)())
check("all commands expose run and usage", (function()
  for _, command in ipairs(cli.all()) do
    if type(command.run) ~= "function" or type(command.usage) ~= "table" or type(command.summary) ~= "string" then
      return false
    end
  end
  return true
end)())
check("aliases resolve", (cli.resolve("rm") or {}).name == "remove")

local ctx = context.new(ports)

section("install: multi-file package with a vendored dependency")
local ok, err = packages.install(ctx, { "caboose/multi_test" }, {})
check("install succeeds", ok, err)
check("entry point written", disk["/multi_test/main.lua"] ~= nil)
check("sibling file written", disk["/multi_test/test2.lua"] ~= nil)
check("dependency vendored into the package", disk["/multi_test/share/test/sharetest.lua"] ~= nil)
check("launcher stub written", disk["/multi_test.lua"] ~= nil)
check(
  "launcher runs the entry point",
  disk["/multi_test.lua"]:find('shell.run("/multi_test/main.lua"', 1, true) ~= nil,
  disk["/multi_test.lua"]
)
check("install recorded", stash[disk["/.moonman/installed.json"]]["caboose/multi_test"] ~= nil)

section("install: single file with no dependencies stays flat")
ok, err = packages.install(ctx, { "caboose/test" }, {})
check("install succeeds", ok, err)
check("written directly to /", disk["/test.lua"] ~= nil)
check("no package directory created", not dirs["/test"])
check("no launcher needed", disk["/test.lua"]:find("shell.run", 1, true) == nil)

section("install: --as and --dry-run")
ok, err = packages.install(ctx, { "test_package" }, { as = "renamed" })
check("--as controls the install name", ok and disk["/renamed.lua"] ~= nil, err)
local before = disk["/multi_test/main.lua"]
ok, err = packages.install(ctx, { "caboose/multi_test" }, { dryRun = true })
check("--dry-run changes nothing", ok and disk["/multi_test/main.lua"] == before, err)
ok, err = packages.install(ctx, { "caboose/test", "test_package" }, { as = "x" })
check("--as rejected for multiple packages", not ok, err)

section("remove")
ok, err = packages.remove(ctx, { "caboose/multi_test" })
check("remove succeeds", ok, err)
check("entry point deleted", disk["/multi_test/main.lua"] == nil)
check("vendored dependency deleted", disk["/multi_test/share/test/sharetest.lua"] == nil)
check("launcher deleted", disk["/multi_test.lua"] == nil)
check("other packages untouched", disk["/test.lua"] ~= nil)
check("record pruned", stash[disk["/.moonman/installed.json"]]["caboose/multi_test"] == nil)
check("removing something absent reports clearly", select(2, packages.remove(ctx, { "nope" })):find("not installed") ~= nil)
-- test_package was installed as "renamed"; removal should accept either name.
check("remove accepts the install name", packages.remove(ctx, { "renamed" }))
check("renamed package deleted", disk["/renamed.lua"] == nil)
check("record keyed by package name pruned", stash[disk["/.moonman/installed.json"]]["test_package"] == nil)
ok, err = packages.install(ctx, { "test_package" }, { as = "renamed" })
check("reinstalled for later sections", ok, err)

section("update")
ok, err = packages.update(ctx, {}, {})
check("update all succeeds", ok, err)
check("install name preserved across update", disk["/renamed.lua"] ~= nil)

section("sync")
ok, err = sync.run(ctx, "share/test", {})
check("device-relative prefix matches", ok, err)
check("directory structure preserved", disk["/share/test/sharetest.lua"] ~= nil)
check("full src/ prefix also matches", sync.run(ctx, "src/share/test", {}))
ok, err = sync.run(ctx, "share/test", { into = "/work" })
check("--into relocates the tree", ok and disk["/work/share/test/sharetest.lua"] ~= nil, err)
check("unmatched prefix reports clearly", not sync.run(ctx, "no/such/prefix", {}))
check("partial segment does not match", not sync.run(ctx, "share/te", {}))

section("self-update")
configModule.save(ports, ctx.config)
ok, err = selfupdate.run(ctx, {})
check("self-update succeeds", ok, err)
check("entry installed at /moonman.lua", disk["/moonman.lua"] ~= nil)
check("library tree installed at /moonman/", disk["/moonman/domain/plan.lua"] ~= nil)
check("config outside /moonman survives", disk["/.moonman/config.json"] ~= nil)
check("install records outside /moonman survive", disk["/.moonman/installed.json"] ~= nil)

section("errors")
check("unknown package", select(2, packages.install(ctx, { "does-not-exist" }, {})):find("no such package") ~= nil)
check("empty install list", not packages.install(ctx, {}, {}))
check("sync without a prefix", not sync.run(ctx, nil, {}))

print(("\n%d checks, %d failure%s"):format(checks, failures, failures == 1 and "" or "s"))
os.exit(failures == 0 and 0 or 1)
