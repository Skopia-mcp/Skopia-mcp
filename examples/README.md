# Examples

Each one calls the hosted endpoint over HTTP. Nothing to install, no engine
code here, and that is the point.

Get a key first:

```bash
export SKOPIA_KEY=$(curl -sS -X POST \
  https://skopia.datatreehaus.com/v1/keys \
  -H 'content-type: application/json' -d '{"label":"examples"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["key"])')
```

| | |
|---|---|
| [`build-a-room.sh`](./build-a-room.sh) | A room, two tables, a join suggestion and an SVG in three calls |

## What to notice

The document comes back from `edit_layout` and goes into the next call. The
server stores nothing and remembers nothing between calls, which is why the
same request always gives the same answer and why nobody's layout can leak
into anybody else's.
