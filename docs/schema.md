# YAML schema

Two dialects of the same schema. **DI form** carries absolute coordinates and is what the converter emits. **Grid form** carries none and lets `bpmn-grid.typ` compute them. The renderer sees the same dictionary either way.

The switch is `meta.layout`: `di` means the bounds are authoritative; anything else (or any node missing `bounds`) sends the model through the grid layout.

## meta

```yaml
meta:
  id: Definitions_0sd3whz        # from the BPMN file, informational
  source: b04-btvn01.bpmn
  title: IE203 - Assignment 01   # from the BPMN group label, if any
  caption: ...                   # optional; API `caption:` overrides it
  layout: di                     # di | grid
  extent: { x, y, w, h }         # bounding box; recomputed on slice/compact
  grid: { col: 150, row: 130 }   # grid form only, layout tuning
```

Caption resolution: API `caption:` → `meta.caption` → `meta.title` → none.

## pools

```yaml
pools:
  - id: p_mgr                    # referenced by nodes as `pool: p_mgr`
    name: Management
    horizontal: true
    bounds: { x, y, w, h }       # DI form only
    blackbox: false              # set by the slicer, not by hand
    lanes:
      - { id: l_hr, name: HR, bounds: { x, y, w, h } }
```

In grid form `bounds` is omitted and lanes may be bare strings: `lanes: [Team Lead, HR]`. Giving them ids is better: a node can then say `lane: l_hr` and renaming the lane will not break anything.

Within a pool, `row` maps to lane order: row 1 lands in the first lane.

## nodes

Common fields:

```yaml
- id: Event_1                    # required, unique
  kind: event                    # event|task|subprocess|gateway|data|annotation|group
  name: A need to enrol arises
  bounds: { x, y, w, h }         # DI form
  row: 1                         # grid form
  col: 3                         # grid form
  label:  { x, y, w, h }         # external label box; auto-placed in grid form
  color: success                 # named palette swatch (see design-system.md)
  fill: "#c8e6c9"                # explicit hex; wins over `color:`
  stroke: "#205022"
  pool: p_mgr                    # pool id or display name
  lane: l_hr
```

Per-kind fields:

| `kind` | Field | Values |
| --- | --- | --- |
| `event` | `event` | `start` `intermediate` `end` `boundary` |
| | `definition` | `none` `message` `timer` `error` `signal` `escalation` `terminate` `compensate` `conditional` `link` `cancel` |
| | `throw` | `true` fills the icon |
| | `interrupting` | boundary events; `false` dashes the ring |
| | `attached-to` | boundary events: host node id |
| `task` | `task` | `none` `user` `service` `send` `receive` `manual` `script` `rule` `call` |
| | `markers` | any of `loop` `mi-parallel` `mi-sequential` `compensation` |
| `subprocess` | `expanded` | `false` draws the `[+]` marker |
| | `triggered-by-event` | dashed border |
| | `transaction` | second inset border |
| | `markers` | as above, plus `adhoc` |
| `gateway` | `gateway` | `exclusive` `parallel` `inclusive` `event` `complex` |
| | `marker` | exclusive only; `false` hides the X |
| | `event-type` | event gateways: `exclusive` (default) or `parallel` |
| | `instantiate` | event gateways; drops the inner ring |
| `data` | `data` | `object` `store` |
| | `collection` | three bars along the bottom |
| | `direction` | `input` (hollow arrow) or `output` (solid) |
| `annotation` | `text` | the annotation body |
| `group` | `name` | from the BPMN category value |

## flows

```yaml
flows:
  - id: Flow_1                   # optional in grid form; derived if absent
    kind: sequence               # sequence | message | association | data
    source: Event_1
    target: Task_1
    name: "Yes"
    waypoints: [[x, y], [x, y]]  # DI form; grid form routes automatically
    label: { x, y, w, h }
    default: true                # draws the slash near the source
    conditional: true            # hollow diamond near the source
    direction: none              # associations: none | one | both
    color: failure               # named swatch, or explicit stroke: below
    stroke: "#205022"
```

A flow with explicit `waypoints` is always honoured, even in grid form; the layout engine only fills in what is missing.

Note that `dataInputAssociation` and `dataOutputAssociation` in BPMN XML name their far end in a *child element* and take their near end from the activity they are declared inside; both parsers resolve that, so in YAML they look like any other flow.

## Minimal grid-form model

```yaml
meta:
  caption: The leave request process (hand-authored, no coordinates)

pools:
  - { id: p_emp, name: Employee }
  - id: p_mgr
    name: Management
    lanes:
      - { id: l_lead, name: Team Lead }
      - { id: l_hr,   name: HR }

nodes:
  - { id: s1, kind: event,   event: start,       name: Leave needed,  pool: p_emp, row: 1, col: 1 }
  - { id: t1, kind: task,    task: user,         name: Submit the request, pool: p_emp, row: 1, col: 2 }
  - { id: g1, kind: gateway, gateway: exclusive, name: "Approved?",   pool: p_mgr, row: 1, col: 3 }

flows:
  - { source: s1, target: t1 }
  - { source: t1, target: g1, kind: message }
```

A runnable version is `examples/leave-request.yaml`.

## Validation

There is none yet beyond `panic` on an unknown node id. A schema validator with readable errors is a Phase 2 item. Until then the converter's `--strict` flag is the closest thing: it exits non-zero if the source `.bpmn` contains a drawable element the converter does not recognise.
