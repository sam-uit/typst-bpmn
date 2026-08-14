# Architecture

## The decision everything follows from

A `.bpmn` file exported by any modeler already contains **BPMNDI**: absolute
bounds for every shape, waypoints for every edge, bounds for every label. Drawing
it is therefore a *coordinate-transform* problem, not a graph-layout problem.

That single fact sets the shape of the project. We do not compute layout for
modeler-authored diagrams — we transform coordinates and draw. Auto-layout only
exists as a fallback for models that have no coordinates at all.

## Pipeline

```
 .bpmn ──┬── tools/bpmn2yaml.py ──► model.yaml ──┐
         │   (strips execution attrs)            │
         └── components/bpmn-xml.typ ────────────┤   both produce the same
             (in-Typst parser, no build step)    │   model dictionary
                                                 ▼
                                      ┌──────────────────┐
                          no bounds?  │   bpmn-grid.typ  │  row/col -> bounds,
                          ────────────►   (auto-layout)  │  ports, routing
                                      └────────┬─────────┘
                                               ▼
                                      ┌──────────────────┐
                              view:   │  bpmn.typ slice  │  filter + black boxes
                                      └────────┬─────────┘
                                               ▼
                                      ┌──────────────────┐
                           compact:   │ bpmn-compact.typ │  collapse empty bands
                                      └────────┬─────────┘
                                               ▼
                                      ┌──────────────────┐
                                      │ bpmn-render.typ  │  place + draw
                                      │ bpmn-shapes.typ  │
                                      └──────────────────┘
```

Order matters. Slicing runs before compaction so compaction only reasons about
what will actually be drawn; compaction runs before rendering because it rewrites
coordinates.

## The model dictionary

One data shape, produced by two parsers and consumed by one renderer. Keeping the
renderer single-sourced is what makes the dual-parser design safe — the test is
`bpmn-info(yaml(..)) == bpmn-info(xml(..))`.

```
(
  meta:  (id, source, title, caption, extent: (x, y, w, h), layout: "di" | "grid"),
  pools: ((id, name, horizontal, bounds, blackbox?, lanes: ((id, name, bounds),)),),
  nodes: ((id, kind, name, bounds, label?, fill?, stroke?, pool?, lane?, ...),),
  flows: ((id, kind, source, target, name?, waypoints, label?, default?, ...),),
)
```

Full field reference: [schema.md](schema.md).

## Coordinate model

Everything upstream of the renderer is in **BPMN units** — 1 unit = 1 px in the
modeler, the same numbers that appear in `dc:Bounds`. The renderer multiplies by
`u`, a length-per-unit, at draw time:

```typ
place(dx: b.x * u, dy: b.y * u, rect(width: b.w * u, height: b.h * u, ...))
```

Stroke widths, font sizes, corner radii and icon sizes are all expressed as
multiples of `u` too, so the entire diagram is scale-independent: change `u` and
everything scales together, including the type.

`theme.font-size` is therefore **in BPMN units, not points**. At `u = 0.12mm` a
`font-size: 11` renders at about 3.7pt. `bpmn-info()` reports the resolved point
size so a document can reason about legibility.

## Why no cetz / fletcher

`bpstep` and `bpmap` are package-free and work in any Typst project and any
renderer; this follows the same rule. With DI coordinates in hand there is also
nothing to gain — fletcher wants to own anchoring and routing, which is precisely
the part we already have from the modeler. Plain `place` + `curve` is less code
and fewer surprises.

## Invariants worth preserving

1. **The renderer never computes layout.** If a coordinate is missing, that is
   `bpmn-grid.typ`'s job, upstream.
2. **Compaction is a monotonic piecewise-linear map per axis.** This is what
   guarantees orthogonal edges stay orthogonal and no new crossings appear. Any
   future compaction feature must preserve monotonicity.
3. **Both parsers produce identical dictionaries.** Changing one means changing
   the other; the equality check in the verification pass is the guard.
4. **No execution semantics anywhere.** The converter drops them at the door so
   nothing downstream has to think about them.

## Known sharp edges

- `layout()` is used to make fit decisions. Inside it, `size.height` is the
  enclosing region's height, not the space remaining on the page, so a figure
  near the bottom of a page may be sized against the full page height and then
  pushed. That is Typst's model, not a bug we can fix here.
- A bottom-anchored `place()` forces its container to claim full height. Do not
  reintroduce one in `bpmn-body`.
- Adding a black box changes a slice's aspect ratio, which can flip `fit: "auto"`
  between flat and rotated for otherwise-similar figures.
