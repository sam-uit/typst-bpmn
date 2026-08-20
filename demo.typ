#import "/src/bpmn.typ": *

#set page(paper: "a4", margin: 18mm, numbering: "1")
#set text(font: "Lora", size: 10pt, lang: "en")
#set par(justify: true, leading: 0.62em)
#show heading: set block(above: 1.3em, below: 0.7em)
#show raw: set text(font: "DejaVu Sans Mono", size: 0.85em)

#let M = yaml("/models/b04-btvn01.yaml")
#let T = default-theme + (font: "Lora")

#align(center)[
  #text(size: 17pt, weight: "bold")[BPMN 2.0 in Typst] \
  #v(2pt)
  #text(size: 9pt)[`b04-btvn01.bpmn` · Camunda Modeler 5.49 · #M.nodes.len() nodes, #M.flows.len() flows]
]
#v(6pt)

The coordinates come straight from the modeler's BPMNDI, so the drawing is faithful to
the original. Three tools bring a wide diagram onto A4, in the order worth reaching for:
slice with `view:`, squeeze the empty bands with `compact:`, and only then turn the page.

= 1. Squeezing out the empty bands

`compact:` does not shrink the drawing: it only removes the empty bands. Shapes and
labels keep their size, so when the result is scaled to the text width the type gets *larger*.

#let stat(vw, cp) = {
  let i = bpmn-info(M, view: vw, compact: cp, theme: T, width: 174mm)
  [#calc.round(i.extent.w) × #calc.round(i.extent.h) u, label #calc.round(i.label-size / 1pt, digits: 2)pt]
}

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  inset: (x: 0pt, y: 3pt),
  align: (left, left, right),
  table.hline(),
  [*Setting*], [*What it does*], [*Result \@174mm*],
  table.hline(stroke: 0.4pt),
  [no compaction], [Camunda's own DI], stat(none, none),
  [`compact: true`], [squeeze the x axis], stat(none, true),
  [`(axis: "both")`], [squeeze both axes], stat(none, (axis: "both")),
  [`(axis: "both", min-gap: 20)`], [squeeze harder], stat(none, (axis: "both", min-gap: 20)),
  table.hline(),
)

#bpmn-figure(M, compact: (axis: "both"), theme: T, debug: true,
  caption: [The whole collaboration with both axes squeezed. Orthogonal edges stay
    orthogonal and nothing overlaps that did not overlap before: the transform is a
    monotonic piecewise-linear map.])

#pagebreak()

= 2. Slicing by pool, keeping the partner as a black box

Showing one pool does *not* delete the other participants. Each collapses to an empty
band carrying its own name, and the message flows are re-routed to the edge of that band.
This is exactly BPMN's black-box idiom: "this partner exists, and its insides are not your
concern". Turn it off with `view: (pool: ..., blackbox: false)`.

#bpmn-figure(M, view: (pool: "Thí Sinh"), compact: true, theme: T,
  caption: [The applicant's view. All 5 message flows to *Nhà Trường* survive, in both
    directions.])

#bpmn-figure(M, view: (pool: "Thí Sinh", blackbox: false), compact: true, theme: T,
  caption: [The same slice with `blackbox: false`, cleaner but with the interaction
    with the partner gone entirely.])

#bpmn-figure(M, view: (pool: "Nhà Trường"), compact: true, theme: T,
  caption: [The university's view, with both lanes intact.])

#pagebreak()

= 3. Slicing by lane

#bpmn-figure(M, view: (lane: "Hội Đồng Học Thuật"), compact: true, theme: T,
  debug: true, caption: [The Hội Đồng Học Thuật lane alone: the labels are now comfortable to read.])

#bpmn-figure(M, view: (lane: "Phòng Tuyển Sinh"), compact: true, theme: T,
  caption: [The Phòng Tuyển Sinh lane.])

= 4. A black-and-white theme

#bpmn-figure(M, view: (lane: "Phòng Tuyển Sinh"), compact: true,
  theme: grayscale-theme + (font: "Lora"),
  caption: [`grayscale-theme` drops bpmn.io's colours for black-and-white printing.])

#pagebreak()

= 5. Reading `.bpmn` directly, with no build step

#bpmn-figure(xml("/samples/b04-btvn01.bpmn"), view: (pool: "Thí Sinh"), compact: true, theme: T,
  caption: [The same slice loaded directly with `xml()`. The two parsers produce
    identical results.])

= 6. Hand-authored YAML, with no coordinates

Drop every `bounds` and `waypoint`, give each node a `row`/`col`, and `bpmn-grid.typ`
does the rest, orthogonal routing included.

#bpmn-figure(yaml("/examples/leave-request.yaml"), theme: T, fit: "width",
  caption: [Grid layout, with not one coordinate in the YAML file.])
