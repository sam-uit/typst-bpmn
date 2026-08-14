# typst-bpmn

Draw BPMN collaboration diagrams inside a Typst report. Same idea as `bpstep` and
`bpmap`: **content lives in data, drawing lives in a component, the document just
calls the component.** Pure Typst — no `cetz`, no `fletcher`, no packages at all.

This renders BPMN. It is not a modeler, and it deliberately carries no execution
semantics: the converter drops `extensionElements`, `zeebe:*`, `camunda:*`,
`isExecutable`, expressions, listeners and IO mappings. What survives is what you
can see on the canvas.

## Layout comes from the modeler

The one design decision everything else follows from: a `.bpmn` file exported by
any modeler already contains **BPMNDI** — absolute bounds for every shape, waypoints
for every edge, bounds for every label. So this is a coordinate-transform problem,
not a graph-layout problem, and the output is faithful to what you see in Camunda
Modeler rather than to whatever a layout algorithm would have invented.

Hand-written YAML with no coordinates falls back to a `row`/`col` grid with
orthogonal routing (`bpmn-grid.typ`). That path is fine for a dozen nodes and a
couple of pools. Past that, draw it in a modeler and convert — the modeler is
better at layout than a few hundred lines of Typst will ever be.

## Docs

- [docs/architecture.md](docs/architecture.md) — pipeline, coordinate model, invariants
- [docs/design-system.md](docs/design-system.md) — geometry, shape grammar, theme tokens
- [docs/schema.md](docs/schema.md) — YAML field reference, both dialects
- [docs/roadmap.md](docs/roadmap.md) — Phase 0 / 1 / 2

## Files

```
tools/bpmn2yaml.py        BPMN XML -> trimmed YAML (the build step)
components/
  bpmn.typ                public API: bpmn-figure, bpmn, bpmn-info, bpmn-slice
  bpmn-render.typ         canvas: pools, lanes, edges, labels, themes
  bpmn-shapes.typ         shape vocabulary: events, activities, gateways, data
  bpmn-xml.typ            read .bpmn directly in Typst (no build step)
  bpmn-grid.typ           layout fallback for coordinate-free YAML
  bpmn-compact.typ        collapse empty bands to buy label size
  bpmn-palette.typ        Camunda Modeler's colour swatches
docs/                     design notes and roadmap
tests/conformance.typ     every symbol at three scales, both pool orientations
tests/agreement.typ       the two parsers must produce identical models
tests/golden.typ          structural manifest; `just golden` fails on drift
tests/fixtures/           synthetic models the real samples do not cover
justfile                  build / watch / check runner
examples/leave-request.yaml   hand-authored model, no coordinates
demo.typ                  every feature, rendered
```

`samples/` (source `.bpmn` and reference renders) and `models/` (converted YAML)
are deliberately **not** in the repo — they are inputs and build products, not
code. `demo.typ` expects them; regenerate with:

```bash
python3 tools/bpmn2yaml.py samples/<model>.bpmn -o models/<model>.yaml
```

## Use

```bash
python3 tools/bpmn2yaml.py model.bpmn -o models/model.yaml
```

```typ
#import "/components/bpmn.typ": *

#bpmn-figure(yaml("/models/model.yaml"), caption: [Quy trình tuyển sinh])

// no build step — parse the XML in Typst
#bpmn-figure(xml("/model.bpmn"))

// one pool, one lane, or an explicit node set
#bpmn-figure(M, view: (pool: "Thí Sinh"), caption: [Góc nhìn của thí sinh])
#bpmn-figure(M, view: (lane: "Hội Đồng Học Thuật"))
#bpmn-figure(M, view: (exclude: ("Nhà Trường",)))
```

Prefer `yaml("...")` / `xml("...")` at the call site so the path resolves relative
to *your* file, exactly as with `bpmap-data`.

## Fitting a wide diagram onto A4

The example model is 1510×1130 BPMN units. Scaled to A4 portrait text width that
puts labels at **3.6pt** — legible to nobody. Four levers, in the order worth
reaching for:

1. **`view:`** — render one pool or one lane per figure. Biggest single win, and
   the analogue of `bpmap`'s `only:`.
2. **`compact:`** — squeeze the empty bands out (below). Free ~15% on this model
   and costs nothing in fidelity.
3. **`fit: "auto"`** (default) — scales to the text width, and rotates a quarter
   turn when that would drop labels below `min-font` *and* the diagram is not
   banner-shaped. A very wide, very short diagram scores well on raw scale when
   rotated but ends up a thin column down an empty page, so those stay flat
   (`max-aspect`, default 2.5).
4. **`landscape: true`** — put that one figure on its own flipped page.

`turn: "ccw"` (default) matches LaTeX `sidewaysfigure`: read by turning the page
clockwise. `debug: true` prints the chosen mode, the extent, the resulting label
size and the node count next to the figure.

```typ
#bpmn-info(M, width: 170mm, compact: true)
// (pools: 2, lanes: 2, nodes: 33, flows: 39, label-size: 4.2pt, by-kind: (..))
```

## `compact:` — squeeze out the empty bands

Scaling a diagram to fit the page shrinks the labels with it. Modeler layouts are
generous with horizontal air — routing corridors, slack left over from dragging
things around — and that air costs type size. `compact:` treats the diagram as a
grid, finds the columns (and optionally rows) where nothing lives, and collapses
each to `min-gap`.

Shapes and labels keep their original size; only the emptiness shrinks. The
transform is a monotonic piecewise-linear map per axis, so orthogonal edges stay
orthogonal and nothing crosses that did not cross before.

```typ
#bpmn-figure(M, compact: true)                              // x axis, defaults
#bpmn-figure(M, compact: (axis: "both", min-gap: 24))
```

| | extent | label @174mm |
| --- | --- | --- |
| off | 1510 × 1130 | 3.59pt |
| `compact: true` | 1291 × 1130 | 4.20pt |
| `(axis: "both")` | 1291 × 1094 | 4.20pt |

Options: `axis` (`"x"`, `"y"`, `"both"`), `min-gap` (34), `halo` (7, the protected
margin around a routing corridor so parallel lines in the same empty band stay
distinct), `margin` (14, air at the outer edges).

What counts as occupied: every shape, every label — including the group title —
every pool and lane title band, and a halo around every edge waypoint. Group and
pool *rectangles* are excluded, since they span the diagram and would mark
everything as occupied.

## Black-box participants

Slicing to one pool used to drop the message flows to everyone else, which quietly
throws away half the collaboration. Now a participant that the slice removed but
that still exchanges messages with what remains is kept as a **black box**: a
collapsed band with its name and nothing inside, placed above or below according
to where it sat originally, with its message flows re-routed to the band edge.
That is the BPMN idiom for "this partner exists, its internals are not your
concern".

```typ
#bpmn-figure(M, view: (pool: "Thí Sinh"))                      // 2 pools, 17 flows
#bpmn-figure(M, view: (pool: "Thí Sinh", blackbox: false))     // 1 pool,  12 flows
```

On by default. `blackbox-height` (56) and `blackbox-gap` (46) tune the band.

## Captions

`caption:` wins; otherwise `meta.caption` from the YAML; otherwise `meta.title`,
which the converter fills from the BPMN `group` label if the model has one. So a
diagram can carry its own caption and the document can still override it.

When a figure turns sideways the caption turns with it, as one unit — the
`sidewaysfigure` convention. A horizontal caption under a turned diagram would
waste the band it sits in twice over, and the diagram is sized against the space
the caption actually needs (measured, not guessed). Disable with
`turn-caption: false`.

## Referencing a figure

`bpmn-figure` returns a wrapper — a `rotate`, a flipped `page`, a `layout` — and
in Typst `#foo(..) <lbl>` labels the **outermost** element. A label written after
the call therefore lands on the wrapper, and `@lbl` fails with *cannot reference
rotate*. Pass it instead:

```typ
#bpmn-figure(M, caption: [Quy trình tuyển sinh], label: <fig-admission>)

Xem @fig-admission.
```

Numbering, `@ref` and `#outline(target: figure.where(kind: image))` all work this
way, including for turned and landscape figures.

## YAML schema

Two dialects of one schema: **DI form** (absolute coordinates, what the converter
emits) and **grid form** (`row`/`col`, hand-authored). Full field reference in
[docs/schema.md](docs/schema.md); a runnable grid-form model is
`examples/leave-request.yaml`.

```yaml
meta:
  layout: di                     # `di` = bounds authoritative; anything else = grid
pools:
  - { id: p_mgr, name: Quản lý, lanes: [{ id: l_hr, name: Nhân sự }] }
nodes:
  - { id: g1, kind: gateway, gateway: exclusive, name: "Duyệt?", pool: p_mgr, row: 1, col: 3 }
flows:
  - { source: t1, target: g1, name: "Có" }
```

## Colours

`color:` on any element names a Camunda Modeler swatch instead of repeating hex:

```yaml
- { id: t3, kind: task, task: send, name: Gửi chấp thuận, color: success }
```

`default` `blue` `orange` `green` `red` `purple`, plus semantic aliases
(`success` `happy` `failure` `error` `reject` `warning` `rework` `info`
`external`). Values match `bpmn-io/bpmn-js-color-picker`; explicit `fill:`/
`stroke:` still wins. Alternative palettes: `outline-palette`, `mono-palette`.

Full table in [docs/design-system.md](docs/design-system.md#colour).

## Building

```bash
just            # list recipes
just demo       # convert samples, build out/demo.pdf
just watch      # live rebuild while editing
just conformance# every symbol at three scales
just check      # converter strict + parsers agree + golden manifest unchanged
just golden     # structural regression check on its own
just golden-update  # re-approve after an intentional change
just lint       # compile every source file
```

Set `BPMN_FONTS=/path/to/fonts` if the fonts are not installed system-wide.

## Themes

`default-theme` honours the bpmn.io colour extensions (`bioc:fill`,
`color:background-color`) — worth keeping, since people use them to mark the happy
path. `grayscale-theme` ignores them for black-and-white printing. Both are plain
dictionaries; override any key:

```typ
#bpmn-figure(M, theme: default-theme + (font: "Inter", font-size: 12))
```

`font-size` is in BPMN units, not points — it scales with the diagram.

## Coverage

Events (start / intermediate catch / intermediate throw / end / boundary,
interrupting and not) with message, timer, error, signal, escalation, terminate,
compensate, conditional, link and cancel definitions. Activities: task and the
seven typed tasks, call activity, collapsed and expanded sub-processes, event
sub-processes. Gateways: exclusive, parallel, inclusive, complex, and all three event-based
variants (exclusive instantiating or not, parallel).
Pools and lanes, horizontal and vertical, expanded and collapsed. Data objects and data stores. Groups and
text annotations. Sequence, message, association and data-association flows, with
default-flow markers.

Roughly the BPMN *descriptive* + *analytic* conformance subclasses — the drawable
part. Choreography and conversation diagrams are out of scope. Anything drawable
the converter does not recognise is reported on stderr; `--strict` turns that into
a non-zero exit.

## Known rough edges

- Icons are redrawn from the spec rather than traced from bpmn.io, so the service
  gear and manual hand read differently at small sizes.
- The grid fallback does no crossing minimisation and no label collision
  avoidance.
- Boundary events are drawn where the DI puts them; the grid fallback does not
  place them on their host's edge.
- Adding a black box changes a slice's aspect ratio, which can flip `fit: "auto"`
  from flat to rotated. Two otherwise-identical figures can end up oriented
  differently; pin `fit: "width"` if that matters.
- Compaction protects a halo around every waypoint, so a band crowded with
  routing corridors barely shrinks. That is the intended trade — the alternative
  is parallel lines collapsing onto each other.
- Black boxes are laid out as full-width bands above/below. A model with many
  partners on both sides would want something denser.
- The grid layout allocates ports and routes orthogonally, but does no crossing
  minimisation — see [docs/roadmap.md](docs/roadmap.md#phase-2--hand-authored-bpmn).

## Status

Phase 1 (modeler-first) is feature-complete; Phase 2 (hand-authored) has layout,
ports and routing but no crossing minimisation. Integration into the IE203 report
template happens after Phase 1 closes — the components sit here until then.
See [docs/roadmap.md](docs/roadmap.md).
