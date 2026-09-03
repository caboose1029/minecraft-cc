--- Shared test module.
---
--- Shared code returns a table rather than defining globals. moonman vendors
--- this file to <program>/share/test/sharetest.lua at install time, so the
--- require path below is identical in the repo and on the computer.
local sharetest = {}

function sharetest.dependencyTest()
  return "dep test"
end

return sharetest
