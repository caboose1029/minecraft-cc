#!/usr/bin/env python3
"""Regenerates config/resource-tree.lua from the installed mods' own jar
files - see PLAN.md "Comprehensive extraction pass, v3" for the full
methodology writeup and known gaps this leaves. Mod jars are ZIP archives
containing every data-driven recipe as JSON (data/<namespace>/recipe/**/
*.json) and every item tag (data/<namespace>/tags/item/**/*.json) - this
walks all of it directly rather than relying on recalled/researched data,
which has repeatedly turned out to have real, confirmed error rates (see
PLAN.md "Methodology change, v2").

Usage:
    python3 scripts/extract_recipes.py /path/to/mods/dir

Re-run this whenever the mod list changes or more recipe types/exclusion
rules are needed, rather than hand-patching config/resource-tree.lua
entries - it is regenerated wholesale, not maintained by hand (except the
small vanilla supplement block at the bottom of this file, which nothing
here can derive since no installed mod ships the vanilla game's own
recipe data).
"""
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

# Mod jar basenames (without version/extension matching) mapped to the
# namespaces they contribute recipe/tag data under. Update this if the
# mod list changes - `unzip -l <jar> | grep -oE "data/[a-z0-9_]+/recipe/"`
# on each jar in the mods folder will show you the real namespace(s).
JAR_TO_NAMESPACES = {
    "create-": {"create"},
    "cc-tweaked-": {"computercraft"},
    "FarmersDelight-": {"farmersdelight", "minecraft"},
    "createfood-": {"createfood", "farmersdelight"},
    "bits_n_bobs-": {"bits_n_bobs", "create"},
    "sliceanddice-": {"create", "minecraft", "sliceanddice"},
    "create-enchantment-industry-": {"create_enchantment_industry"},
    "displaydelight-": {"displaydelight"},
    "CreateDragonsPlus-": {"create_dragons_plus"},
}
INSTALLED = {"minecraft"}
for namespaces in JAR_TO_NAMESPACES.values():
    INSTALLED |= namespaces

# --- decorative-family exclusion ----------------------------------------

DYE_COLORS = ["white", "orange", "magenta", "light_blue", "yellow", "lime",
              "pink", "gray", "light_gray", "cyan", "purple", "blue",
              "brown", "green", "red", "black"]
DECORATIVE_BASES = ["seat", "postbox", "table_cloth", "toolbox",
                     "valve_handle", "wool", "carpet", "bed", "banner",
                     "candle", "concrete", "terracotta", "shulker_box",
                     "stained_glass", "glazed_terracotta", "dye",
                     "firework", "flag", "skull_", "disk_", "bundle",
                     "chair", "stool", "drawer", "cushion", "rug", "lamp",
                     "lantern", "curtain", "sign", "plate_block",
                     "small_plate_block"]
NOVELTY_OUTPUT_IDS = {"minecraft:player_head"}
COPPER_PALETTE_RE = re.compile(
    r"(waxed_)?(weathered_|exposed_|oxidized_)?copper_(shingle|tile|block)"
)


def is_decorative(output_id):
    if output_id in NOVELTY_OUTPUT_IDS:
        return True
    name = output_id.split(":", 1)[1]
    for color in DYE_COLORS:
        if name.startswith(color + "_") or name == color:
            for base in DECORATIVE_BASES:
                if base.rstrip("_") in name:
                    return True
    for base in DECORATIVE_BASES:
        if base in name:
            return True
    if COPPER_PALETTE_RE.search(name):
        return True
    return False


MANUAL_TAG_OVERRIDES = {
    "c:barrels/wooden": "minecraft:barrel",
    "c:dusts/redstone": "minecraft:redstone",
    "c:glass_panes": "minecraft:glass_pane",
    "c:nuggets/iron": "minecraft:iron_nugget",
    "c:nuggets/gold": "minecraft:gold_nugget",
    "c:ingots/iron": "minecraft:iron_ingot",
    "c:ingots/gold": "minecraft:gold_ingot",
    "c:ingots/copper": "minecraft:copper_ingot",
    "c:ingots/netherite": "minecraft:netherite_ingot",
    "c:nuggets/netherite": "minecraft:netherite_nugget",
    "c:glass_blocks": "minecraft:glass",
    "c:glass_blocks/colorless": "minecraft:glass",
    "c:sand": "minecraft:sand",
    "c:string": "minecraft:string",
    "c:leathers": "minecraft:leather",
    "c:rods/wooden": "minecraft:stick",
    "c:chests/wooden": "minecraft:chest",
    "c:cobblestone": "minecraft:cobblestone",
    "c:stone": "minecraft:stone",
    "minecraft:planks": "minecraft:oak_planks",
    "minecraft:logs": "minecraft:oak_log",
    "minecraft:wool": "minecraft:white_wool",
    "minecraft:wooden_stairs": "minecraft:oak_stairs",
    "minecraft:wooden_buttons": "minecraft:oak_button",
    "minecraft:wooden_slabs": "minecraft:oak_slab",
    "minecraft:wooden_doors": "minecraft:oak_door",
    "minecraft:wooden_trapdoors": "minecraft:oak_trapdoor",
    "minecraft:wooden_fences": "minecraft:oak_fence",
    "c:ender_pearls": "minecraft:ender_pearl",
    "c:storage_blocks/copper": "minecraft:copper_block",
    "c:storage_blocks/iron": "minecraft:iron_block",
    "c:storage_blocks/gold": "minecraft:gold_block",
    "c:storage_blocks/raw_iron": "minecraft:raw_iron_block",
    "c:storage_blocks/raw_gold": "minecraft:raw_gold_block",
    "c:storage_blocks/raw_copper": "minecraft:raw_copper_block",
    "c:flours/wheat": "create:wheat_flour",
    "c:dyes": "minecraft:black_dye",
    "c:crops/wheat": "minecraft:wheat",
    "c:crops/carrot": "minecraft:carrot",
    "c:crops/potato": "minecraft:potato",
    "c:crops/beetroot": "minecraft:beetroot",
    "c:foods/bread": "minecraft:bread",
    "c:bones": "minecraft:bone",
    "c:buckets/water": "minecraft:water_bucket",
    "c:buckets/milk": "minecraft:milk_bucket",
    "c:strings": "minecraft:string",
    "c:eggs": "minecraft:egg",
    "c:seeds": "minecraft:wheat_seeds",
    "c:crops/sugar_cane": "minecraft:sugar_cane",
    "c:crops/nether_wart": "minecraft:nether_wart",
    "minecraft:buttons": "minecraft:oak_button",
    "c:netherracks": "minecraft:netherrack",
    "c:stones": "minecraft:stone",
    "c:gunpowders": "minecraft:gunpowder",
    "c:slimeballs": "minecraft:slime_ball",
    "minecraft:wooden_pressure_plates": "minecraft:oak_pressure_plate",
    "c:sands/red": "minecraft:red_sand",
    "c:gems/quartz": "minecraft:quartz",
    "c:sands/colorless": "minecraft:sand",
    "c:feathers": "minecraft:feather",
    "c:ropes": "minecraft:string",
    "c:seeds/wheat": "minecraft:wheat_seeds",
    "c:cobblestones": "minecraft:cobblestone",
    "c:stripped_logs": "minecraft:stripped_oak_log",
    "minecraft:stripped_logs": "minecraft:stripped_oak_log",
}
for _color in DYE_COLORS:
    MANUAL_TAG_OVERRIDES[f"c:dyes/{_color}"] = f"minecraft:{_color}_dye"

SKIP_TYPES = {
    "create:blasting", "minecraft:blasting", "minecraft:campfire_cooking",
    "create:emptying", "create:filling", "create:mechanical_crafting",
    "create:sequenced_assembly", "create:haunting",
    "create:item_copying", "create:toolbox_dyeing", "create:sandpaper_polishing",
    "computercraft:impostor_shaped", "computercraft:impostor_shapeless",
    "computercraft:transform_shaped", "computercraft:transform_shapeless",
    "computercraft:turtle_upgrade", "computercraft:pocket_computer_upgrade",
    "computercraft:clear_colour", "computercraft:colour",
    "computercraft:disk", "computercraft:printout",
    "minecraft:smithing_transform",
    "create_dragons_plus:ending", "create_dragons_plus:freezing",
    "ratatouille_fried_delights:frying", "ratatouille_fried_delights:coating",
    "hearthandharvest:stomping", "hearthandharvest:aging",
    "expandeddelight:juicing", "immersiveengineering:cloche",
    "immersiveengineering:metal_press", "ratatouille:squeezing",
    "ratatouille:threshing", "farmersdelight:food_serving",
    "farmersdelight:dough",
}

SEQ_SLOTS = [1, 2, 3, 5, 6, 7, 9, 10, 11]

# The generic type-based job mapping puts every create:deploying/
# item_application recipe under one "deploying" job type - fine when one
# physical Deployer handles everything, but ktoxConfigFeederForJob/
# ktoxConfigRelayForJob each return only the FIRST peripheral matching a
# job type name (pairs() iteration order is not guaranteed), so a build
# with several dedicated physical Deployers (one per casing, say) can't
# be told apart by job type alone - every casing would race for whichever
# single feeder/relay happened to be found first. Split per-output here
# so each gets its own job type name and can get its own dedicated
# feeder+relay in peripherals.json. Add more entries as new per-machine
# splits are needed; anything not listed keeps its generic type-based job.
JOB_OVERRIDES_BY_OUTPUT = {
    "create:andesite_casing": "deploying_andesite",
    "create:brass_casing": "deploying_brass",
    "create:copper_casing": "deploying_copper",
    "create:railway_casing": "deploying_railway",
}

# CreateFood's raw contribution is a huge per-fruit/topping combinatorial
# system (~3,280 entries) - scoped down to just these meal categories,
# plus each kept dish's full ingredient closure. See PLAN.md v3 writeup.
CREATEFOOD_KEEP_KEYWORDS = ("soup", "pie", "pizza", "skewer", "burger")

MANUAL_VANILLA_RECIPES = [
    # Confirmed in-game (2026-09-07): Create's Mechanical Saw strips logs
    # the same way an axe does. This is a hardcoded Java behavior, not a
    # data-driven recipe - no JSON for it exists anywhere in Create's own
    # jar (only its "cutting" recipes like andesite_alloy -> shaft are
    # data-driven), so no amount of jar extraction would ever find it.
    {"output": "minecraft:stripped_oak_log", "outputCount": 1, "job": "cutting",
     "inputs": [{"item": "minecraft:oak_log", "count": 1}]},
    {"output": "minecraft:charcoal", "outputCount": 1, "job": "smelter",
     "inputs": [{"item": "minecraft:oak_log", "count": 1}]},
    {"output": "minecraft:stone", "outputCount": 1, "job": "smelter",
     "inputs": [{"item": "minecraft:cobblestone", "count": 1}]},
    {"output": "minecraft:brick", "outputCount": 1, "job": "smelter",
     "inputs": [{"item": "minecraft:clay_ball", "count": 1}]},
    {"output": "minecraft:dried_kelp", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:kelp", "count": 1}]},
    {"output": "minecraft:cooked_beef", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:beef", "count": 1}]},
    {"output": "minecraft:cooked_chicken", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:chicken", "count": 1}]},
    {"output": "minecraft:cooked_porkchop", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:porkchop", "count": 1}]},
    {"output": "minecraft:cooked_mutton", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:mutton", "count": 1}]},
    {"output": "minecraft:cooked_rabbit", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:rabbit", "count": 1}]},
    {"output": "minecraft:cooked_cod", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:cod", "count": 1}]},
    {"output": "minecraft:cooked_salmon", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:salmon", "count": 1}]},
    {"output": "minecraft:baked_potato", "outputCount": 1, "job": "smoker",
     "inputs": [{"item": "minecraft:potato", "count": 1}]},
    {"output": "minecraft:water_bucket", "outputCount": 1, "job": "filling",
     "inputs": [{"item": "minecraft:bucket", "count": 1}]},
    {"output": "minecraft:lava_bucket", "outputCount": 1, "job": "filling",
     "inputs": [{"item": "minecraft:bucket", "count": 1}]},
    {"output": "minecraft:chest", "outputCount": 1, "job": "crafter",
     "inputs": [
         {"item": "minecraft:oak_planks", "count": 1, "slot": 1},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 2},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 3},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 5},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 7},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 9},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 10},
         {"item": "minecraft:oak_planks", "count": 1, "slot": 11},
     ]},
    {"output": "minecraft:dried_kelp_block", "outputCount": 1, "job": "crafter",
     "inputs": [{"item": "minecraft:dried_kelp", "count": 9, "slot": 1}]},
]


def find_jar(mods_dir, prefix):
    for fn in os.listdir(mods_dir):
        if fn.startswith(prefix) and fn.endswith(".jar"):
            return os.path.join(mods_dir, fn)
    return None


def extract_jars(mods_dir, dest_dir):
    jar_dirs = []
    for prefix in JAR_TO_NAMESPACES:
        jar_path = find_jar(mods_dir, prefix)
        if jar_path is None:
            print(f"warning: no jar found for prefix {prefix!r} in {mods_dir}", file=sys.stderr)
            continue
        out_dir = os.path.join(dest_dir, prefix.rstrip("-"))
        os.makedirs(out_dir, exist_ok=True)
        subprocess.run(
            ["unzip", "-o", "-q", jar_path, "data/*/recipe/*", "data/*/tags/item/*", "-d", out_dir],
            check=False,
        )
        jar_dirs.append(out_dir)
    return jar_dirs


def build_tag_index(jar_dirs):
    tag_files = {}
    for jar_dir in jar_dirs:
        root = os.path.join(jar_dir, "data")
        if not os.path.isdir(root):
            continue
        for dirpath, _, files in os.walk(root):
            norm = dirpath.replace(os.sep, "/")
            if "/tags/item/" not in norm and not norm.endswith("/tags/item"):
                continue
            ns = norm.split("/data/")[1].split("/")[0]
            sub = norm.split("/tags/item")[1].lstrip("/")
            for fn in files:
                if not fn.endswith(".json"):
                    continue
                key = ns + ":" + (sub + "/" + fn[:-5] if sub else fn[:-5])
                try:
                    with open(os.path.join(dirpath, fn)) as f:
                        parsed = json.load(f)
                except Exception:
                    continue
                tag_files.setdefault(key, {"values": []})["values"].extend(parsed.get("values", []))
    return tag_files


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    mods_dir = sys.argv[1]
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    config_dir = os.path.join(os.path.dirname(repo_root), "src", "pkg", "player", "8durt", "config")

    with tempfile.TemporaryDirectory() as tmp:
        jar_dirs = extract_jars(mods_dir, tmp)
        tag_files = build_tag_index(jar_dirs)
        unresolved = []

        def resolve_tag(tag_id, _seen=None):
            if _seen is None:
                _seen = set()
            if tag_id in _seen:
                return None
            _seen.add(tag_id)
            if tag_id in tag_files:
                for v in tag_files[tag_id].get("values", []):
                    if isinstance(v, dict):
                        v = v.get("id")
                    if not v:
                        continue
                    if v.startswith("#"):
                        resolved = resolve_tag(v[1:], _seen)
                        if resolved:
                            return resolved
                    elif v.split(":")[0] in INSTALLED:
                        return v
                return None
            return MANUAL_TAG_OVERRIDES.get(tag_id)

        def first_concrete(ref, context):
            if isinstance(ref, list):
                for alt in ref:
                    got = first_concrete(alt, context)
                    if got:
                        return got
                return None
            if not isinstance(ref, dict):
                return None
            if "item" in ref:
                return ref["item"] if ref["item"].split(":")[0] in INSTALLED else None
            if "tag" in ref:
                resolved = resolve_tag(ref["tag"])
                if resolved is None:
                    unresolved.append((context, ref["tag"]))
                return resolved
            return None

        def has_fluid_ingredient(entries):
            for e in entries:
                for it in (e if isinstance(e, list) else [e]):
                    if isinstance(it, dict) and ("fluid" in it or "amount" in it):
                        return True
            return False

        def slot_for(row, col):
            return row * 4 + col + 1

        def convert_shaped(data, context):
            inputs = []
            for row, rowstr in enumerate(data["pattern"]):
                for col, ch in enumerate(rowstr):
                    if ch == " " or ch not in data["key"]:
                        continue
                    item = first_concrete(data["key"][ch], context)
                    if item is None:
                        return None
                    inputs.append({"item": item, "count": 1, "slot": slot_for(row, col)})
            return inputs or None

        def convert_shapeless(data, context):
            counts = defaultdict(int)
            for ing in data["ingredients"]:
                item = first_concrete(ing, context)
                if item is None:
                    return None
                counts[item] += 1
            inputs = []
            for i, (item, count) in enumerate(counts.items()):
                if i >= len(SEQ_SLOTS):
                    return None
                inputs.append({"item": item, "count": count, "slot": SEQ_SLOTS[i]})
            return inputs

        def convert_single_ingredient(data, context, key_name="ingredient"):
            item = first_concrete(data[key_name], context)
            return None if item is None else [{"item": item, "count": 1}]

        def convert_multi_ingredient(data, context):
            inputs = []
            for ing in data["ingredients"]:
                item = first_concrete(ing, context)
                if item is None:
                    return None
                found = next((i for i in inputs if i["item"] == item), None)
                if found:
                    found["count"] += 1
                else:
                    inputs.append({"item": item, "count": 1})
            return inputs

        results = []
        skipped_type = defaultdict(int)
        skipped_decorative = skipped_unresolved = skipped_other = 0
        seen_recipe_paths = set()
        seen_sigs = set()

        for jar_dir in jar_dirs:
            recipe_root = os.path.join(jar_dir, "data")
            for dirpath, _, files in os.walk(recipe_root):
                norm = dirpath.replace(os.sep, "/")
                if "/recipe/" not in norm and not norm.endswith("/recipe"):
                    continue
                if "/compat/" in norm:
                    continue
                for fn in files:
                    if not fn.endswith(".json"):
                        continue
                    path = os.path.join(dirpath, fn)
                    rel_key = norm.split("/data/")[1] + "/" + fn
                    if rel_key in seen_recipe_paths:
                        continue
                    seen_recipe_paths.add(rel_key)
                    try:
                        with open(path) as f:
                            data = json.load(f)
                    except Exception:
                        continue
                    rtype = data.get("type", "?")
                    if rtype in SKIP_TYPES or rtype == "?":
                        skipped_type[rtype] += 1
                        continue

                    result = data.get("result")
                    if isinstance(result, list):
                        result = result[0] if result else {}
                    if result is None:
                        result = (data.get("results") or [{}])[0]
                    if isinstance(result, dict) and isinstance(result.get("item"), dict):
                        result = result["item"]
                    if not isinstance(result, dict):
                        skipped_other += 1
                        continue
                    out_id = result.get("id")
                    if out_id is None or out_id.split(":")[0] not in INSTALLED:
                        skipped_other += 1
                        continue
                    if "amount" in result:
                        skipped_other += 1
                        continue
                    if is_decorative(out_id):
                        skipped_decorative += 1
                        continue
                    if any(m in fn for m in ("_from_deoxidising", "_from_removing_wax", "_from_waxing")):
                        skipped_decorative += 1
                        continue

                    context = rel_key
                    job, inputs = None, None
                    fluid_types = {"create:crushing", "create:milling", "create:mixing",
                                    "create:pressing", "create:cutting", "create:compacting",
                                    "create:deploying", "create:item_application",
                                    "create:splashing", "farmersdelight:cooking"}
                    if rtype in fluid_types and has_fluid_ingredient(data.get("ingredients", [])):
                        skipped_other += 1
                        continue

                    if rtype == "minecraft:crafting_shaped":
                        job, inputs = "crafter", convert_shaped(data, context)
                    elif rtype == "minecraft:crafting_shapeless":
                        job, inputs = "crafter", convert_shapeless(data, context)
                    elif rtype == "minecraft:smelting":
                        job, inputs = "smelter", convert_single_ingredient(data, context)
                    elif rtype == "minecraft:smoking":
                        job, inputs = "smoker", convert_single_ingredient(data, context)
                    elif rtype == "minecraft:stonecutting":
                        job, inputs = "stonecutting", convert_single_ingredient(data, context)
                    elif rtype == "create:crushing":
                        job, inputs = "crushing", convert_multi_ingredient(data, context)
                    elif rtype == "create:milling":
                        job, inputs = "milling", convert_multi_ingredient(data, context)
                    elif rtype == "create:mixing":
                        heat = data.get("heat_requirement", "none")
                        job = "mixing_heated" if heat in ("heated", "superheated") else "mixing_unheated"
                        inputs = convert_multi_ingredient(data, context)
                    elif rtype == "create:pressing":
                        job, inputs = "pressing", convert_multi_ingredient(data, context)
                    elif rtype == "create:cutting":
                        job, inputs = "cutting", convert_multi_ingredient(data, context)
                    elif rtype == "create:compacting":
                        job, inputs = "compacting", convert_multi_ingredient(data, context)
                    elif rtype in ("create:deploying", "create:item_application"):
                        job, inputs = "deploying", convert_multi_ingredient(data, context)
                    elif rtype == "create:splashing":
                        job, inputs = "splashing", convert_multi_ingredient(data, context)
                    elif rtype == "farmersdelight:cutting":
                        job = "cutting_board"
                        ings = data.get("ingredients", [])
                        item = first_concrete(ings[0], context) if ings else None
                        inputs = None if item is None else [{"item": item, "count": 1}]
                    elif rtype == "farmersdelight:cooking":
                        job, inputs = "cooking_pot", convert_multi_ingredient(data, context)
                    else:
                        skipped_type[rtype] += 1
                        continue

                    if inputs is None:
                        skipped_unresolved += 1
                        continue
                    if any(inp["count"] <= 0 for inp in inputs):
                        skipped_other += 1
                        continue

                    job = JOB_OVERRIDES_BY_OUTPUT.get(out_id, job)
                    entry = {"output": out_id, "outputCount": result.get("count", 1),
                             "job": job, "inputs": inputs}
                    sig = (out_id, job, tuple((i["item"], i["count"], i.get("slot")) for i in inputs))
                    if sig in seen_sigs:
                        continue
                    seen_sigs.add(sig)
                    results.append(entry)

        print(f"generated entries: {len(results)}")
        print(f"skipped_decorative: {skipped_decorative}, skipped_unresolved: {skipped_unresolved}, "
              f"skipped_other: {skipped_other}")
        print("skipped by type (top 15):")
        for t, c in sorted(skipped_type.items(), key=lambda kv: -kv[1])[:15]:
            print(f"  {c:5d}  {t}")
        if unresolved:
            print(f"unresolved tag refs (unique): {len(set(t for _, t in unresolved))}")

    # --- CreateFood scoping + dependency closure ---
    createfood_by_output = defaultdict(list)
    for r in results:
        if r["output"].startswith("createfood:"):
            createfood_by_output[r["output"]].append(r)
    seed = {out for out in createfood_by_output
            if any(k in out.split(":", 1)[1] for k in CREATEFOOD_KEEP_KEYWORDS)}
    kept = set(seed)
    frontier = set(seed)
    while frontier:
        nxt = set()
        for out in frontier:
            for r in createfood_by_output.get(out, []):
                for inp in r["inputs"]:
                    if inp["item"].startswith("createfood:") and inp["item"] not in kept:
                        kept.add(inp["item"])
                        nxt.add(inp["item"])
        frontier = nxt
    results = [r for r in results if not r["output"].startswith("createfood:") or r["output"] in kept]
    print(f"createfood scoped to {len(seed)} seed dishes -> {len(kept)} outputs incl. prerequisites")

    all_recipes = results + MANUAL_VANILLA_RECIPES
    for r in all_recipes:
        if r["output"] == "create:andesite_alloy":
            r["priority"] = 1 if any(i["item"] == "minecraft:iron_nugget" for i in r["inputs"]) else 2
        if r["output"] == "minecraft:stripped_oak_log":
            # Both the Mechanical Saw ("cutting") and Farmer's Delight's
            # Cutting Board ("cutting_board") can strip logs - identical
            # 1:1 ratio, so the efficiency heuristic can't break the tie
            # and Lua's pairs() iteration order isn't guaranteed. Saw
            # pinned as the default on the (documented) assumption most
            # builds have one; override here if a build relies on the
            # Cutting Board for this instead.
            r["priority"] = 1 if r["job"] == "cutting" else 2

    def lua_str(s):
        return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

    lines = [
        "-- Generated from real recipe JSON extracted out of the installed mod",
        "-- jars - see scripts/extract_recipes.py and PLAN.md \"Comprehensive",
        "-- extraction pass, v3\" for methodology, exclusions, and known gaps.",
        "-- Not hand-edited - regenerate via that script rather than patching",
        "-- entries here piecemeal, except the small vanilla-supplement block",
        "-- (MANUAL_VANILLA_RECIPES in that script) a human maintains by hand.",
        "return {",
        "  recipes = {",
    ]
    for r in all_recipes:
        parts = [f'output = {lua_str(r["output"])}', f'outputCount = {r["outputCount"]}',
                  f'job = {lua_str(r["job"])}']
        if "priority" in r:
            parts.append(f'priority = {r["priority"]}')
        input_strs = []
        for i in r["inputs"]:
            ip = [f'item = {lua_str(i["item"])}', f'count = {i["count"]}']
            if i.get("slot") is not None:
                ip.append(f'slot = {i["slot"]}')
            input_strs.append("{ " + ", ".join(ip) + " }")
        parts.append("inputs = { " + ", ".join(input_strs) + " }")
        lines.append("    { " + ", ".join(parts) + " },")
    lines.append("  },")
    lines.append("}")
    out_text = "\n".join(lines) + "\n"

    out_path = os.path.join(config_dir, "resource-tree.lua")
    with open(out_path, "w") as f:
        f.write(out_text)
    print(f"wrote {out_path}: {len(all_recipes)} recipes, {len(out_text)/1024:.1f} KB")


if __name__ == "__main__":
    main()
