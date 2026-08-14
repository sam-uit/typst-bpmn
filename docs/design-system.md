# Design system

Everything here is expressed in **BPMN units** (1 unit = 1 px in the modeler) and
multiplied by `u` at draw time. Constants below are the defaults Camunda Modeler
uses, so a converted diagram matches the modeler's proportions.

## Geometry constants

| Element | Size (units) | Notes |
| --- | --- | --- |
| Event | 36 × 36 | circle, r = 18 |
| Task / sub-process | 100 × 80 | corner radius 10 |
| Gateway | 50 × 50 | diamond, vertices are the four ports |
| Data object | 36 × 50 | folded corner = 0.3 × width |
| Data store | 50 × 50 | ellipse cap = 0.16 × height |
| Pool / lane title band | 30 wide | rotated text for horizontal pools |
| Black-box pool band | 56 tall | name centred, no band, no lanes |
| Label font | 11 | `theme.font-size`, in units |

## Stroke weights

Relative to the shape, so they scale with `u`:

| Stroke | Weight |
| --- | --- |
| Start / intermediate event ring | 0.055 × diameter |
| End event ring | 0.13 × diameter |
| Activity / gateway border | 1.6 units at nominal size |
| Sequence flow | 1.6 units |
| Message / association flow | 1.3 units |
| Pool border | 1.6 units · lane border 1.2 |

Non-interrupting boundary events and event sub-processes use `dash: "dashed"`;
groups use `"loosely-dashed"`; message flows `"dashed"`; associations `"dotted"`.

## Event ring grammar

The ring says *when*, the icon says *what*, the fill says *catch or throw*.

| Family | Ring | Icon fill |
| --- | --- | --- |
| Start | single thin | outline (catch) |
| Intermediate catch | double thin | outline |
| Intermediate throw | double thin | solid |
| End | single thick | solid |
| Boundary | double thin | outline; dashed ring if non-interrupting |

Definitions covered: none, message, timer, error, signal, escalation, terminate,
compensate, conditional, link, cancel.

## Activity type markers

Drawn at 0.18 × min(w, h), inset 0.06 × w from the top-left corner: user,
service, send, receive, manual, script, business rule. A call activity gets the
spec's thick border instead of an icon.

## Activity behaviour markers

A row centred on the bottom edge, each 0.16 × min(w, h) with a 0.35 gap:

| Marker | Drawn as | From |
| --- | --- | --- |
| `sub` | `[+]` in a box | collapsed sub-process |
| `loop` | circular arrow | `standardLoopCharacteristics` |
| `mi-parallel` | three vertical bars | `multiInstanceLoopCharacteristics` |
| `mi-sequential` | three horizontal bars | same, `isSequential="true"` |
| `compensation` | double rewind triangle | `isForCompensation="true"` |
| `adhoc` | tilde | `adHocSubProcess` |

Several can co-exist; they lay out left to right in that order. Transactions get a
second inset border, event sub-processes a dashed one.

Icons are **redrawn from the BPMN 2.0 spec**, not traced from bpmn-js — see
[roadmap.md](roadmap.md#a-note-on-borrowing-from-bpmn-js) for why that matters.
Two rules learned the hard way:

- **Outline, not fill, at small sizes.** The first service-task gear was a filled
  disc with filled teeth; below about 40 units it collapsed into a black blob.
  Strokes throughout survive the scale-down.
- **Icons are drawn in a unit square and scaled**, so a single definition works at
  every diagram scale.

## Ports

Four attachment points per shape — right, bottom, left, top — which on a gateway
diamond are exactly its vertices. Every flow touching a node is allocated its own,
by angle, with conflicts resolved in favour of the better-aligned flow. A gateway
with one incoming and two outgoing branches therefore uses left / right / bottom,
which is how a person would draw it.

External labels (events, gateways, data) are then placed on the first side *no
flow is using*, preferring bottom → top → right → left. Without that, a gateway's
name lands on top of its own outgoing branch.

Applies to the grid layout only; DI models use the modeler's waypoints.

## Theme tokens

```typ
#let default-theme = (
  font: "DejaVu Sans",
  stroke: rgb("#22242A"),      // Camunda's default, not pure black
  fill: rgb("#FFFFFF"),
  palette: camunda-palette,    // resolves `color:` names
  pool-stroke: rgb("#22242A"),
  pool-fill: none,
  pool-band: rgb("#f8f8f8"),   // title band behind pool/lane names
  blackbox-fill: rgb("#f4f4f4"),
  lane-stroke: rgb("#22242A"),
  group-stroke: rgb("#666666"),
  label: rgb("#22242A"),
  font-size: 11,               // BPMN units
  label-leading: 0.32,         // multiple of font size
  honor-colors: true,          // use bioc:/color: extensions from the model
)
```

Override by addition: `default-theme + (font: "Lora", font-size: 12)`.
`grayscale-theme` is `default-theme + (honor-colors: false, palette: mono-palette)`.

## Colour

Three sources, in precedence order: an explicit `fill:`/`stroke:` hex on the
element, then a named `color:` swatch, then the theme default.

### The Camunda palette

The six swatches Camunda Modeler's colour picker offers. Values taken from
`bpmn-io/bpmn-js-color-picker` and confirmed against the colours Camunda wrote
into the reference model.

| Name | Fill | Stroke |
| --- | --- | --- |
| `default` | `#FFFFFF` | `#22242A` |
| `blue` | `#BBDEFB` | `#0D4372` |
| `orange` | `#FFE0B2` | `#6B3C00` |
| `green` | `#C8E6C9` | `#205022` |
| `red` | `#FFCDD2` | `#831311` |
| `purple` | `#E1BEE7` | `#5B176D` |

Note the default stroke: Camunda uses `rgb(34, 36, 42)`, not pure black, and the
theme now matches.

Semantic aliases so a model can say what it means rather than which hue:
`success`/`happy` → green, `failure`/`error`/`reject` → red, `warning`/`rework` →
orange, `info` → blue, `external` → purple.

Alternative palettes: `outline-palette` (same hues, white fill) and
`mono-palette` (everything black on white). Set one with
`theme: default-theme + (palette: outline-palette)`.

An unknown swatch name falls back to `default` rather than failing the build — a
typo in a colour should not stop a report.

### Extension attributes

bpmn.io's non-normative colour extensions (`bioc:fill` / `bioc:stroke`,
`color:background-color` / `color:border-color`) are carried through and applied
to the element's border, fill **and its label**. People use these to mark the
happy path and the failure path, so dropping them loses meaning, not just
decoration. `honor-colors: false` ignores them for black-and-white printing.

## Typography

Labels are set in `theme.font` at `theme.font-size × u` with tight leading. Where
the DI provides label bounds those are honoured exactly, which reproduces the
modeler's line breaks — with one exception: **group titles ignore their DI label
bounds**, because modelers size those to their own font and any other font forces
a wrap.

The font must cover the diagram's script. For Vietnamese, DejaVu Sans, Noto Sans,
Lora and Libertinus all work; bpmn.io's own Arial does too.
