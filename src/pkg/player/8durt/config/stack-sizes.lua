-- Per-item max-stack-size overrides, keyed by item ID. Absent = 64 (the
-- default for most items) - only list items that genuinely deviate.
-- These are objective vanilla-game facts (not per-world config), same
-- reasoning as job-types.lua/resource-tree.lua - centrally maintained
-- here, fetched fresh every ghfetch run, not player-owned.
--
-- Deliberately a SMALL, high-confidence starting set, not an exhaustive
-- vanilla item list - AGENTS.md's own account of resource-tree.lua's
-- early mistakes (wrong IDs, wrong mechanics) is exactly why this
-- avoids guessing at anything not well-established. Add more here as
-- they're actually hit in-game (a bucket-like item, a tool, an unstable
-- item silently defaulting to 64) rather than trying to front-load
-- every vanilla exception now.
return {
  ["minecraft:ender_pearl"] = 16,
  ["minecraft:egg"] = 16,
  ["minecraft:snowball"] = 16,
  ["minecraft:bucket"] = 16,
  ["minecraft:water_bucket"] = 1,
  ["minecraft:lava_bucket"] = 1,
  ["minecraft:milk_bucket"] = 1,
  ["minecraft:powder_snow_bucket"] = 1,
}
