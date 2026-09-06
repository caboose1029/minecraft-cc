#!/usr/bin/env bash
set -euo pipefail

# Runs transpiled Lua output against real CraftOS-PC (headless) to validate
# syntax, ktox-lib runtime behavior, and common/*.kt bindings against a
# real CC:Tweaked Lua 5.1 environment (not the Gradle plugin's bundled
# LuaJ, which can differ subtly).
#
# Prepends ktox-cc-shim.lua ahead of the entry point in one combined temp
# script, so shim globals (ktoxGpsLocate, ktoxInspectName, ...) are defined
# before the program runs — mirroring what startup.lua does on a real boot.
# This is necessary because CraftOS-PC's --script flag runs BEFORE the
# computer's own startup.lua, and dofile() from within a --script'd file
# doesn't get a working `require()` (that's only set up for the file
# CraftOS-PC invokes directly via --script) — see AGENTS.md.
#
# KNOWN LIMITATIONS:
# - turtle.* calls fail here with "attempt to index global 'turtle' (a nil
#   value)". This runs against a plain computer, not a turtle. CC:Tweaked's
#   turtle emulation (https://github.com/MCJack123/craftos2-turtle) is
#   C++ source only, with no precompiled release and no build script —
#   building it would mean reverse-engineering CraftOS-PC's internal
#   plugin SDK from scratch. Until that's done (see AGENTS.md roadmap),
#   this validates everything except live turtle.* calls.
# - gps.locate() genuinely returns nil here (no GPS hosts in the
#   emulator) — confirming graceful nil-handling is as far as this script
#   can verify; real position data needs a real world + GPS host network.
#
# Usage: scripts/validate.sh [entry-point.lua] ["shell args string"]
#   e.g. scripts/validate.sh Digsite.lua "100:110 200:215"

CRAFTOS_BIN="/Applications/CraftOS-PC.app/Contents/MacOS/craftos"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Output lands in the monorepo's shared src/ tree, not under this subproject.
LUA_OUTPUT_DIR="$PROJECT_ROOT/../src/pkg/player/8durt"
ENTRY_POINT="${1:-Hello.lua}"
PROGRAM_ARGS="${2:-}"
RUN_SECONDS="${VALIDATE_TIMEOUT:-8}"

if [ ! -x "$CRAFTOS_BIN" ]; then
  echo "CraftOS-PC not found at $CRAFTOS_BIN" >&2
  exit 1
fi

if [ ! -f "$LUA_OUTPUT_DIR/$ENTRY_POINT" ]; then
  echo "No build output at $LUA_OUTPUT_DIR/$ENTRY_POINT — run ./gradlew build first." >&2
  exit 1
fi

# Isolated throwaway data dir so this never touches real CraftOS-PC state
# (saved computers, config, etc).
DATA_DIR="$(mktemp -d)"
trap 'rm -rf "$DATA_DIR"' EXIT

mkdir -p "$DATA_DIR/computer/0"
cp -R "$LUA_OUTPUT_DIR"/* "$DATA_DIR/computer/0/"

COMBINED_SCRIPT="$DATA_DIR/combined.lua"
cat "$LUA_OUTPUT_DIR/ktox-cc-shim.lua" "$LUA_OUTPUT_DIR/$ENTRY_POINT" > "$COMBINED_SCRIPT"

echo "Running $ENTRY_POINT in headless CraftOS-PC (${RUN_SECONDS}s)..."
"$CRAFTOS_BIN" \
  --headless \
  --directory "$DATA_DIR" \
  --script "$COMBINED_SCRIPT" \
  --args "$PROGRAM_ARGS" &
PID=$!

sleep "$RUN_SECONDS"
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
