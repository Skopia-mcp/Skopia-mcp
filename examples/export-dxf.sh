#!/usr/bin/env bash
# Build a room and export it as a DXF for CAD. Two calls, no install.
#
#   SKOPIA_KEY=sk_... ./export-dxf.sh
#
# What comes back is model space at 1:1 in millimetres, y up, the plan at the
# document's own coordinates. Layers are named by role — WALL, DOOR,
# DOOR-SWING, WINDOW, OBJECT, TEXT… — and carry their line weights, so a plot
# from CAD reads as the engine's own sheet does: what is cut is heavier than
# what is seen.
set -euo pipefail

: "${SKOPIA_KEY:?Get one: curl -X POST https://skopia.datatreehaus.com/v1/keys -d '{}'}"
BASE=https://skopia.datatreehaus.com/v1

rpc() {  # rpc <method> <params-json> [tool-name]
  curl -sS "$BASE" \
    -H "Authorization: Bearer $SKOPIA_KEY" \
    -H 'content-type: application/json' \
    -H 'MCP-Protocol-Version: 2026-07-28' \
    -H "Mcp-Method: $1" \
    ${3:+-H "Mcp-Name: $3"} \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":{$2\"_meta\":{
         \"io.modelcontextprotocol/protocolVersion\":\"2026-07-28\",
         \"io.modelcontextprotocol/clientCapabilities\":{}}}}"
}

echo "1. A five metre by four metre room, a door, a window, a bath and a WC."
OPS='[{"op":"place_corner","x":0,"y":0},
      {"op":"place_corner","x":5000,"y":0},
      {"op":"place_corner","x":5000,"y":4000},
      {"op":"place_corner","x":0,"y":4000},
      {"op":"close_room"},
      {"op":"add_window","wall":0,"off":2500,"width":1200},
      {"op":"add_door","wall":3,"off":1500,"width":900},
      {"op":"add_fixture","type":"bath","at":{"x":0,"y":4000}},
      {"op":"add_fixture","type":"wc","x":4800,"y":1000,"against":{"wall":1}}]'

DOC=$(rpc tools/call "\"name\":\"edit_layout\",\"arguments\":{\"operations\":$OPS}," edit_layout \
      | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin)["result"]["structuredContent"]["document"]))')

echo "2. Export it. The DXF is the first text block; the placements are the second."
rpc tools/call "\"name\":\"export_dxf\",\"arguments\":{\"document\":$DOC,\"scale\":50}," export_dxf \
  | python3 -c '
import sys, json
r = json.load(sys.stdin)["result"]
open("room.dxf", "w").write(r["content"][0]["text"])
meta = json.loads(r["content"][1]["text"])
print("   wrote room.dxf:", meta["entities"], "entities on", len(meta["layers"]), "layers")
print("   weights (paper mm):", json.dumps(meta["weights"]))
print("   open it in AutoCAD, Vectorworks, Revit, LibreCAD, or any DXF viewer")'
