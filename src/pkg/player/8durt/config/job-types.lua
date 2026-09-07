-- Job type definitions: execution kind, timeout overrides, and farm
-- watermarks. See PLAN.md/AGENTS.md for the comprehensive-recipe-pass
-- writeup that added cutting/cutting_board/stonecutting and retired the
-- old "slicer" type (it had incorrectly conflated two different real
-- machines - Create's Mechanical Saw and Farmer's Delight's Cutting
-- Board - into one job; verified via jar extraction and split back out).
-- No "produces" list here (unlike the old job-types.json) - it was never
-- actually read by any loader, and keeping it in sync with hundreds of
-- resource-tree.lua entries would be pure maintenance burden for zero
-- runtime benefit.
return {
  crushing = { kind = "machine" },
  milling = { kind = "machine" },
  smelter = { kind = "machine" },
  smoker = { kind = "machine" },
  pressing = { kind = "machine" },
  cutting = { kind = "machine" },
  cutting_board = { kind = "machine" },
  stonecutting = { kind = "machine" },
  mixing_unheated = { kind = "machine" },
  mixing_heated = { kind = "machine", timeoutSeconds = 45 },
  compacting = { kind = "machine" },
  deploying = { kind = "machine" },
  splashing = { kind = "machine" },
  filling = { kind = "machine" },
  cooking_pot = { kind = "machine" },
  crafter = { kind = "crafter" },
  wood_farm = {
    kind = "farm",
    watermarks = {
      { item = "minecraft:oak_log", lowWatermark = 64, highWatermark = 256 },
    },
  },
  kelp_farm = {
    kind = "farm",
    watermarks = {
      { item = "minecraft:kelp", lowWatermark = 128, highWatermark = 512 },
    },
  },
  iron_andesite_farm = {
    kind = "farm",
    watermarks = {
      { item = "minecraft:iron_ingot", lowWatermark = 64, highWatermark = 256 },
      { item = "minecraft:andesite", lowWatermark = 64, highWatermark = 256 },
    },
  },
  copper_farm = {
    kind = "farm",
    watermarks = {
      { item = "minecraft:copper_ingot", lowWatermark = 64, highWatermark = 256 },
    },
  },
}
