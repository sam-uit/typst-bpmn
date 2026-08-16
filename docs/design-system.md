# Design system

Everything here is expressed in **BPMN units** (1 unit = 1 px in the modeler) and multiplied by `u` at draw time. Constants below are the defaults Camunda Modeler uses, so a converted diagram matches the modeler's proportions.

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
| Start event ring | 0.055 × diameter |
| Intermediate / boundary event ring | 0.042 × diameter, **both** rings |
| End event ring | 0.13 × diameter |
| Activity / gateway border | 1.6 units at nominal size |
| Sequence flow | 1.6 units |
| Message / association flow | 1.3 units |
| Pool border | 1.6 units · lane border 1.2 |

Non-interrupting boundary events and event sub-processes use `dash: "dashed"`; groups use `"loosely-dashed"`; message flows `"dashed"`; associations `"dotted"`.

## Event ring grammar

The ring says *when*, the icon says *what*, the fill says *catch or throw*.

| Family | Ring | Icon fill |
| --- | --- | --- |
| Start | single thin | outline (catch) |
| Intermediate catch | double thin | outline |
| Intermediate throw | double thin | solid |
| End | single thick | solid |
| Boundary | double thin | outline; dashed ring if non-interrupting |

### The double ring is three numbers, not one

Ring weight, inner radius and the white between them are one system. Get it wrong in
the obvious way — draw the double ring at the single-ring weight of 0.055 d, with the
inner circle bpmn-js's 3/18 r inside — and the arithmetic gives a white gap of exactly
zero: centreline distance 0.055 d minus two half-strokes of 0.0275 d. The strokes
touch, and an intermediate event renders as one thick ring, which is the end event.
The icon stays right the whole time, so nothing looks broken; the *grammar* is what
breaks, silently.

So: each ring 0.042 × diameter (bpmn-js's 1.5 on a 36 box), inner radius `r − 0.22 r`.

The 0.22 is deliberately wider than bpmn-js's 3/18 = 0.167. Their gap leaves 4.2% of
the diameter as white, which is fine on a modeller canvas and not fine on an A4 figure
where the whole event is a few millimetres across — it closes up and you are back to
one thick ring, just at a smaller size. 0.22 r leaves 7.4% and survives the scale-down.
It still clears the icon, which occupies the middle `r × r` box (corners at 0.71 r).

This is the same rule as the service-task gear below: **fidelity at nominal size is not
the whole spec — the symbol has to still say what it says after it is shrunk.**

Definitions covered: none, message, timer, error, signal, escalation, terminate, compensate, conditional, link, cancel.

## Activity type markers

Drawn at 0.18 × min(w, h), inset 0.06 × w from the top-left corner: user, service, send, receive, manual, script, business rule. A call activity gets the spec's thick border instead of an icon.

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

Several can co-exist; they lay out left to right in that order. Transactions get a second inset border, event sub-processes a dashed one.

Icons are **redrawn from the BPMN 2.0 spec**, not traced from bpmn-js — see [roadmap.md](roadmap.md#a-note-on-borrowing-from-bpmn-js) for why that matters. Two rules learned the hard way:

- **Centre on the box, and derive the centre — never write it as a literal.**
  `place(circle(radius: r))` puts the circle's *edge* at the origin, so a dial written
  as `radius: 0.46 * size` is centred on 0.46, not 0.5. The timer icon carried that 4%
  offset for a long time: it looks like nothing on its own and like an unbalanced white
  margin once it sits inside an event ring. Do what `icon-service` does — name
  `(cx, cy) = (0.5 size, 0.5 size)` and place everything relative to it. Where the ink
  is deliberately asymmetric (the loop marker's arrowhead sticks out past the arc),
  solve for the centre of the *inked* extent instead of the geometric one.
- **An arrowhead on a curve belongs *to* the curve, not on its tangent.** Three tries on
  the loop marker: (1) hand-fitted cubics with the head pinned at fixed coordinates — the
  head was not on the path at all; (2) a real arc with the head built on the tangent at
  the tip — geometrically correct and still wrong to look at, because a straight head
  leaving a curve reads as flying off it, and its square base met the curving stroke at
  an angle and left a notch; (3) both ends of the head **on the circle**, so it leans
  with the turn and carries the arc's momentum through the tip, with the base edge along
  the **radius** at its own angle — by construction perpendicular to the tangent exactly
  where the stroke ends, so the two meet square and the notch is gone.
  Using the glyph `↻` instead was considered and rejected: it comes out much lighter
  than the neighbouring markers, and it would make a BPMN symbol depend on the host
  document's font.
- **One sharp point in a set of round caps looks wrong and nobody can say why.** Fills
  that form a point (arrowheads) get a `join: "round"` stroke in the fill colour so their
  corners match the strokes around them.
- **Outline, not fill, at small sizes.** The first service-task gear was a filled disc with filled teeth; below about 40 units it collapsed into a black blob. Strokes throughout survive the scale-down.
- **Icons are drawn in a unit square and scaled**, so a single definition works at every diagram scale.

## Event-based gateway variants

BPMN tells the three renderings apart by `eventGatewayType` and `instantiate`, not by element name:

| `event-type` | `instantiate` | Drawn as |
| --- | --- | --- |
| `exclusive` | `false` | outer ring + inner ring + pentagon |
| `exclusive` | `true` | outer ring + pentagon |
| `parallel` | `true` | outer ring + plus |

Ring radii follow bpmn-js: outer circle inset 0.20 × height from the shape, inner 0.26, so a 50-unit gateway gets r = 15 and r = 12.

## Pool orientation

A pool's title band and its lanes both follow the pool's own axis:

| | Title band | Title text | Lanes |
| --- | --- | --- | --- |
| Horizontal (`isHorizontal="true"`) | down the left | turned −90° | stacked, bands on the left |
| Vertical | across the top | upright | side by side, bands on top |

Lane and pool ordering follows the same axis — top-to-bottom in a horizontal pool, left-to-right in a vertical one — so a slice keeps reading order.

A collapsed (black-box) participant has no band and no lanes: the name is centred in the box, turned only when the box is taller than it is wide.

## Ports

Four attachment points per shape — right, bottom, left, top — which on a gateway diamond are exactly its vertices. Every flow touching a node is allocated its own, by angle, with conflicts resolved in favour of the better-aligned flow. A gateway with one incoming and two outgoing branches therefore uses left / right / bottom, which is how a person would draw it.

External labels (events, gateways, data) are then placed on the first side *no flow is using*, preferring bottom → top → right → left. Without that, a gateway's name lands on top of its own outgoing branch.

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

Override by addition: `default-theme + (font: "Lora", font-size: 12)`. `grayscale-theme` is `default-theme + (honor-colors: false, palette: mono-palette)`.

## Colour

Three sources, in precedence order: an explicit `fill:`/`stroke:` hex on the element, then a named `color:` swatch, then the theme default.

### The Camunda palette

The six swatches Camunda Modeler's colour picker offers. Values taken from `bpmn-io/bpmn-js-color-picker` and confirmed against the colours Camunda wrote into the reference model.

| Name | Fill | Stroke |
| --- | --- | --- |
| `default` | `#FFFFFF` | `#22242A` |
| `blue` | `#BBDEFB` | `#0D4372` |
| `orange` | `#FFE0B2` | `#6B3C00` |
| `green` | `#C8E6C9` | `#205022` |
| `red` | `#FFCDD2` | `#831311` |
| `purple` | `#E1BEE7` | `#5B176D` |

Note the default stroke: Camunda uses `rgb(34, 36, 42)`, not pure black, and the theme now matches.

Semantic aliases so a model can say what it means rather than which hue: `success`/`happy` → green, `failure`/`error`/`reject` → red, `warning`/`rework` → orange, `info` → blue, `external` → purple.

Alternative palettes: `outline-palette` (same hues, white fill) and `mono-palette` (everything black on white). Set one with `theme: default-theme + (palette: outline-palette)`.

An unknown swatch name falls back to `default` rather than failing the build — a typo in a colour should not stop a report.

### Extension attributes

bpmn.io's non-normative colour extensions (`bioc:fill` / `bioc:stroke`, `color:background-color` / `color:border-color`) are carried through and applied to the element's border, fill **and its label**. People use these to mark the happy path and the failure path, so dropping them loses meaning, not just decoration. `honor-colors: false` ignores them for black-and-white printing.

## Typography

Labels are set in `theme.font` at `theme.font-size × u` with tight leading. Where the DI provides label bounds those are honoured exactly, which reproduces the modeler's line breaks — with one exception: **group titles ignore their DI label bounds**, because modelers size those to their own font and any other font forces a wrap.

The font must cover the diagram's script. For Vietnamese, DejaVu Sans, Noto Sans, Lora and Libertinus all work; bpmn.io's own Arial does too.
