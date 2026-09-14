# Skopia

**A 2D spatial layout engine, reachable as an MCP server.** Define a bounded
space in real millimetres, place things in it, validate, render, and project
elevations and sections from the plan.

```
https://skopia.datatreehaus.com/v1
```

[![MCP Registry](https://img.shields.io/badge/MCP_Registry-com.datatreehaus%2Fskopia--floor--plan--layout-5DBF80?style=flat-square)](https://registry.modelcontextprotocol.io/v0/servers?search=skopia)
[![Add to Cursor](https://img.shields.io/badge/Cursor-Add_Skopia-141414?style=flat-square)](https://cursor.com/en/install-mcp?name=skopia&config=eyJ1cmwiOiJodHRwczovL3Nrb3BpYS5kYXRhdHJlZWhhdXMuY29tL3YxIiwiaGVhZGVycyI6eyJBdXRob3JpemF0aW9uIjoiQmVhcmVyICR7ZW52OlNLT1BJQV9LRVl9In19)
[![Add to VS Code](https://img.shields.io/badge/VS_Code-Add_Skopia-0098FF?style=flat-square)](https://vscode.dev/redirect/mcp/install?name=skopia&config=%7B%22name%22%3A%22skopia%22%2C%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Fskopia.datatreehaus.com%2Fv1%22%2C%22headers%22%3A%7B%22Authorization%22%3A%22Bearer%20%24%7Binput%3Askopia-key%7D%22%7D%2C%22inputs%22%3A%5B%7B%22id%22%3A%22skopia-key%22%2C%22type%22%3A%22promptString%22%2C%22password%22%3Atrue%2C%22description%22%3A%22Your%20Skopia%20key%20(free%2C%20from%20https%3A%2F%2Fskopia.datatreehaus.com)%22%7D%5D%7D)

Every call needs a key. Getting one is free, instant, and needs no approval.
The one-click installs above carry no key: Cursor reads `SKOPIA_KEY` from
your environment, VS Code asks for it as it installs.

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

Cursor, VS Code, Codex, `.mcp.json`, Claude Desktop (via `mcp-remote`) and
raw HTTP are covered at [/setup](https://skopia.datatreehaus.com/setup).

## What it does that a model cannot do for itself

A model asked to draw a floor plan will emit SVG, and it will look entirely
fine. The walls will not quite close, the elevation will not agree with the
plan, and the door will swing out of its hinge. Nothing will fail. That is
the problem this exists to remove.

**An agent cannot draw a door wrong here, because it does not draw the
door.** It names one — panelled, part-glazed, three rows — and the same
component answers in the plan, the elevation and the section. The swing is
derived once and reviewed once, and cannot come out of the hinge on a
Tuesday.

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

## We wrote the alternative, and it was wrong three times

The case for this had to be tested rather than asserted, so the competitor is
a real file in our repository: a hand-written script that draws the same
house. It was written with the engine's source open — its palette, its wall
conventions, its house data — and corrected three times against renders with
a person reviewing. It is not a cold run and we will not present it as one.

Which makes the failures sharper rather than softer. Given every one of those
advantages, it was still wrong three times.

1. The door's swing arc sprang from the *hinge* instead of the leaf's tip, so
   it floated into the room ending nowhere near the far jamb.
2. Windows were bare white gaps — no frame, no glass line. A hole in a wall,
   not a window.
3. The internal walls had **no doors in them at all**. Three rooms, no way
   into any of them.

Every version rendered cleanly. Two of the three faults were invisible at the
size the drawing was reviewed at, and the third survived two rounds of review
looking perfectly reasonable. An agent running unattended ships it.

**Tokens are not the argument.** On raw count, a script an agent writes once
still beats calling this — the drawing goes to a file, where a tool result
comes back into the context — and our own benchmark says so plainly rather
than burying it. The argument is that the cheap path's failures are silent,
plausible, and found by a human or not at all.

The cheap version is the wrong one, every time.

We have **not** measured tokens-to-completion for a cold agent. That needs a
real run against a brief, with no sight of this engine's source, recorded to
the point where the drawings are actually right. We have not done it, and
nothing above is quoted as though we had.

## And then we ran it ourselves, and it was wrong too

One agent, one brief, this engine, September 2026. It cost about **269,000
tokens** and the drawings came out wrong: a section facing the wrong way, a
blank section B–B, a two-over-two sash that was not one, 1:50 too small for
the sheet, and eight dimension queries too small to read.

- **Looking is the job.** About 100,000 of those tokens — 37% — were
  rendering a drawing and looking at it, roughly 8,000 a picture. An agent
  writing its own SVG has the identical loop at the identical price, so the
  biggest cost in the job is common to both sides and cancels out of the
  comparison entirely. Our own benchmark never counted it.
- **Reading the engine cost ~65,000 tokens** before any work started. Over
  MCP that is a tool list instead — which is the honest argument for the
  server, and one we had backwards.
- **The refusals did their job.** A spot level the schema could not hold and
  two unused wall thicknesses were reported rather than silently dropped.

So: naming a component removes a *class* of error, not the category. An agent
can still ask for the wrong one, point a section the wrong way, or produce a
drawing that comes out blank. We have done all three.

We have **not** run the other side cold. There is no A/B here and we will not
imply one.

## When not to use it

If you want one sketch, once, and nobody is going to build from it, emit the
SVG yourself. It is free, it needs no key, and it will be fine.

Reach for this when the drawings have to agree with each other, when somebody
is going to measure one, or when nobody is going to be looking over the
agent's shoulder.

## Tools

| | |
|---|---|
| `edit_layout` | Build or change a layout by applying operations |
| `list_operations` | The fifty-three-operation vocabulary |
| `validate_layout` | Typed errors naming which object offended |
| `render_layout` | Deterministic SVG |
| `draw_sheet` | A plan and its sections on one sheet, true to scale |
| `project_elevation` | An elevation projected from the plan |
| `project_section` | A section cut through the plan, internal walls and all |
| `suggest_sections` | Where a section could go, and what each place would show |
| `list_components` | The window and door stock |
| `suggest_joins` | Which objects could be pushed together |
| `suggest_rotation` | Which way an object should face |
| `check_rules` | Check against rules *you* supply |
| `overhead_report` | What a section will have to reckon with |
| `roof_report` | Which roof readings are still missing, as questions |
| `missing_dimensions` | Which measurements the survey never took |

Fifteen tools is standing context on every turn, so narrower surfaces exist:
`/v1/core`, `/v1/elevation`, `/v1/advisory`, and they compose
(`/v1/core+elevation`). A key can carry a profile instead.

Every tool is a pure function and says so over the wire (`readOnlyHint`,
`idempotentHint`): nothing is stored, so a client that auto-approves
read-only tools can approve all of these.

## Prompts

Four workflows, served as MCP prompts, so a client that lists them shows the
order to do things in rather than a vocabulary. In Claude Code they arrive as
slash commands.

| | |
|---|---|
| `build_a_room` | A description of a room to a validated, rendered plan |
| `survey_to_drawings` | A measured survey to plan, sections and elevations, asking for what was never measured |
| `check_a_layout` | Validate, then check against a spacing rule *you* supply |
| `seat_a_room` | Place and number tables; report joins as suggestions, never capacity |

Each names the tools it uses and is listed only where every one is mounted,
so a prompt cannot walk a model into a tool the endpoint does not serve.

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
