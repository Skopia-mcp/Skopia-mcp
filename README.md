# Skopia

**A 2D spatial layout engine, reachable as an MCP server.** Define a bounded
space in real millimetres, place things in it, validate, render, and project
elevations from the plan.

```
https://skopia.datatreehaus.com/v1
```

Every call needs a key. Getting one is free, instant, and needs no approval.

## Quick start

```bash
# 1. get a key
curl -X POST https://skopia.datatreehaus.com/v1/keys \
  -H 'content-type: application/json' \
  -d '{"label":"my agent","email":"you@example.com"}'

# 2. add the server
claude mcp add --transport http skopia \
  https://skopia.datatreehaus.com/v1 \
  --header "Authorization: Bearer YOUR_KEY"
```

Codex, `.mcp.json` and raw HTTP are covered at
[/setup](https://skopia.datatreehaus.com/setup).

## What it does that a model cannot do for itself

A model asked to draw a floor plan will emit SVG. The walls will not quite
close, the elevation will not agree with the plan, and it will look entirely
fine. That is the problem this exists to remove.

- **Elevations cannot disagree with the plan.** Not through care. A
  horizontal position in an elevation is a *reference* to a plan feature
  (`opening:3.jamb.left`), so there is no field anywhere that could hold a
  wrong number.
- **It asks instead of guessing.** Give it a survey and `missing_dimensions`
  tells you which measurements were never actually taken, rather than picking
  a plausible number that closes the ring. From the moment software invents
  that number it is indistinguishable from a measured one.
- **Components are asked for, not drawn.** `{"type": "sash", "panes": [3, 2]}`
  is a six-over-six sash. The same window as SVG path data is around fifty
  times the tokens, and a model can get path data subtly wrong in ways nothing
  checks.
- **Refusals name the problem.** Typed, permanent error codes saying *which*
  object offended, because an agent cannot act on "invalid layout".
- **Advisory reads never decide.** `suggest_joins` reports which tables could
  be pushed together and changes nothing. Adjacency may suggest; a person
  decides.
- **No regulatory figures ship here.** Gangway widths, egress distances and
  wheelchair ratios are yours to supply and yours to stand behind. Wrong
  numbers inside software a fire officer reads are a liability, not a bug.

## Tools

| | |
|---|---|
| `edit_layout` | Build or change a layout by applying operations |
| `list_operations` | The forty-operation vocabulary |
| `validate_layout` | Typed errors naming which object offended |
| `render_layout` | Deterministic SVG |
| `project_elevation` | An elevation projected from the plan |
| `list_components` | The window and door stock |
| `suggest_joins` | Which objects could be pushed together |
| `suggest_rotation` | Which way an object should face |
| `check_rules` | Check against rules *you* supply |
| `missing_dimensions` | Which measurements the survey never took |

Ten tools is standing context on every turn, so narrower surfaces exist:
`/v1/core`, `/v1/elevation`, `/v1/advisory`, and they compose
(`/v1/core+elevation`). A key can carry a profile instead.

## Status, honestly

Free, and a **demand probe rather than a product**. It exists to find out
whether anyone wants this. It will be priced eventually and there will be
notice first. It is not promised free for ever, and it is not for production
you cannot afford to have change under you.

The engine's source is not public. This endpoint is the interface, not the
implementation, so this repository contains clients, examples and docs, and
no engine code.

## Examples

See [`examples/`](./examples). They call the hosted endpoint over HTTP and
need nothing installed but `curl` or `node`.
