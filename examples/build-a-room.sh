#!/usr/bin/env bash
# Build a room, put two tables in it, and render it. Three calls, no install.
#
#   SKOPIA_KEY=sk_... ./build-a-room.sh
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

echo "1. A four metre by three metre room, two tables in it."
OPS='[{"op":"place_corner","x":0,"y":0},
      {"op":"place_corner","x":4000,"y":0},
      {"op":"place_corner","x":4000,"y":3000},
      {"op":"place_corner","x":0,"y":3000},
      {"op":"close_room"},
      {"op":"add_window","wall":0,"off":2000,"width":1200},
      {"op":"add_door","wall":3,"off":1500,"width":900},
      {"op":"add_table","x":1200,"y":1500},
      {"op":"add_table","x":2150,"y":1500}]'

DOC=$(rpc tools/call "\"name\":\"edit_layout\",\"arguments\":{\"operations\":$OPS}," edit_layout \
      | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin)["result"]["structuredContent"]["document"]))')
echo "   $(echo "$DOC" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d["boundary"]["verts"]),"corners,",len(d["openings"]),"openings,",len(d["tables"]),"tables")')"

echo "2. Could those two tables be pushed together?"
rpc tools/call "\"name\":\"suggest_joins\",\"arguments\":{\"document\":$DOC}," suggest_joins \
  | python3 -c 'import sys,json; r=json.load(sys.stdin)["result"]["structuredContent"]; print("  ", json.dumps(r)[:300])'

echo "3. Draw it."
rpc tools/call "\"name\":\"render_layout\",\"arguments\":{\"document\":$DOC}," render_layout \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["result"]["structuredContent"]["svg"])' > room.svg
echo "   wrote room.svg ($(wc -c < room.svg) bytes)"
