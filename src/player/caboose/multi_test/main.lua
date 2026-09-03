-- Entry point for the "multi_test" package.
--
-- Two kinds of require, both resolved against this program's directory:
--   "share.test.sharetest" -- vendored here by moonman from src/share/
--   "test2"                -- a sibling file shipped inside this package
local sharetest = require("share.test.sharetest")
local test2 = require("test2")

print(sharetest.dependencyTest())
print(test2.greet())
