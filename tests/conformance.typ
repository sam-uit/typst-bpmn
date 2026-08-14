// Visual conformance sheet: every symbol in the vocabulary, at three scales.
//
// Open beside Camunda Modeler and compare proportions. The three scales matter —
// several icons that read fine at full size turn to mush when a diagram is
// squeezed onto A4, and this is where that shows up.
//
//   just conformance

#import "/components/bpmn-shapes.typ": *
#import "/components/bpmn-palette.typ": *

#set page(paper: "a4", margin: 14mm, numbering: "1")
#set text(font: "Lora", size: 9pt)
#show heading: set text(size: 11pt)
#show heading: set block(above: 1.1em, below: 0.5em)

#let SCALES = (1pt, 0.55pt, 0.34pt)
#let ink = rgb("#22242A")

#let cell(label, body, w: 74pt) = box(width: w)[
  #align(center)[#body #v(3pt) #text(size: 6.5pt, fill: rgb("#555"))[#label]]
]

/// Render one symbol at every scale, side by side. `base` is the symbol's width
/// in BPMN units; the cell has to be wide enough for all three plus the gaps or
/// they spill into the neighbouring column.
#let scales(label, make, base: 36) = {
  let gap = 5pt
  let w = base * SCALES.sum() + 2 * gap + 8pt
  box(width: w)[
    #align(center)[
      #stack(dir: ltr, spacing: gap, ..SCALES.map(u => box(baseline: 40%, make(u))))
      #v(3pt) #text(size: 6.5pt, fill: rgb("#555"))[#label]
    ]
  ]
}

#align(center)[
  #text(size: 15pt, weight: "bold")[BPMN 2.0 conformance sheet] \
  #v(2pt)
  #text(size: 8.5pt, fill: rgb("#555"))[
    every symbol at 100% / 55% / 34% · drawn from the OMG spec, not traced from bpmn-js
  ]
]
#v(8pt)

= Events

Ring says *when*, icon says *what*, fill says *catch or throw*.

#let ev(fam, def, throw, lbl) = scales(lbl,
  u => shape-event(36 * u, 36 * u, family: fam, definition: def, throw: throw,
    fill: white, stroke: ink))

*Start*
#grid(columns: 5, row-gutter: 9pt,
  ev("start", "none", false, "none"),
  ev("start", "message", false, "message"),
  ev("start", "timer", false, "timer"),
  ev("start", "signal", false, "signal"),
  ev("start", "conditional", false, "conditional"))

*Intermediate — catch (outline) and throw (solid)*
#grid(columns: 5, row-gutter: 9pt,
  ev("intermediate", "message", false, "message catch"),
  ev("intermediate", "timer", false, "timer"),
  ev("intermediate", "link", false, "link catch"),
  ev("intermediate", "message", true, "message throw"),
  ev("intermediate", "escalation", true, "escalation throw"),
  ev("intermediate", "compensate", true, "compensation"),
  ev("intermediate", "signal", true, "signal throw"),
  ev("intermediate", "link", true, "link throw"))

*End — thick ring, solid icons*
#grid(columns: 5, row-gutter: 9pt,
  ev("end", "none", true, "none"),
  ev("end", "message", true, "message"),
  ev("end", "error", true, "error"),
  ev("end", "escalation", true, "escalation"),
  ev("end", "signal", true, "signal"),
  ev("end", "compensate", true, "compensation"),
  ev("end", "cancel", true, "cancel"),
  ev("end", "terminate", false, "terminate"))

*Boundary — double ring; dashed when non-interrupting*
#grid(columns: 4, row-gutter: 9pt,
  scales("error (interrupting)", u => shape-event(36 * u, 36 * u, family: "boundary",
    definition: "error", stroke: ink)),
  scales("timer (interrupting)", u => shape-event(36 * u, 36 * u, family: "boundary",
    definition: "timer", stroke: ink)),
  scales("timer (non-interrupting)", u => shape-event(36 * u, 36 * u, family: "boundary",
    definition: "timer", interrupting: false, stroke: ink)),
  scales("message (non-interrupting)", u => shape-event(36 * u, 36 * u, family: "boundary",
    definition: "message", interrupting: false, stroke: ink)))

#pagebreak()

= Activities

#let tk(kind, lbl, ..a) = scales(lbl,
  u => shape-task(100 * u, 80 * u, kind: kind, fill: white, stroke: ink, ..a), base: 100)

*Task types*
#grid(columns: 2, row-gutter: 10pt, column-gutter: 4pt,
  tk("none", "task"), tk("user", "user"), tk("service", "service"),
  tk("send", "send"), tk("receive", "receive"), tk("manual", "manual"),
  tk("script", "script"), tk("rule", "business rule"),
  tk("call", "call activity (thick border)"))

*Behaviour markers*
#grid(columns: 2, row-gutter: 10pt, column-gutter: 4pt,
  tk("none", "loop", markers: ("loop",)),
  tk("none", "multi-instance parallel", markers: ("mi-parallel",)),
  tk("none", "multi-instance sequential", markers: ("mi-sequential",)),
  tk("user", "compensation", markers: ("compensation",)),
  tk("none", "loop + compensation", markers: ("loop", "compensation")),
  tk("service", "MI parallel + loop", markers: ("mi-parallel", "loop")))

*Sub-processes*
#grid(columns: 2, row-gutter: 10pt, column-gutter: 4pt,
  scales("collapsed", u => shape-subprocess(100 * u, 80 * u, stroke: ink), base: 100),
  scales("expanded", u => shape-subprocess(100 * u, 80 * u, expanded: true, stroke: ink), base: 100),
  scales("event sub-process", u => shape-subprocess(100 * u, 80 * u, expanded: true,
    event-sub: true, stroke: ink), base: 100),
  scales("transaction", u => shape-subprocess(100 * u, 80 * u, expanded: true,
    transaction: true, stroke: ink), base: 100),
  scales("ad-hoc", u => shape-subprocess(100 * u, 80 * u, expanded: true,
    markers: ("adhoc",), stroke: ink), base: 100),
  scales("collapsed + MI", u => shape-subprocess(100 * u, 80 * u,
    markers: ("mi-parallel",), stroke: ink), base: 100))

#pagebreak()

= Gateways

#grid(columns: 4, row-gutter: 9pt,
  ..(("exclusive", "exclusive (X)"), ("parallel", "parallel (+)"),
     ("inclusive", "inclusive (O)"), ("event", "event-based"),
     ("complex", "complex (*)")).map(((k, lbl)) =>
    scales(lbl, u => shape-gateway(50 * u, 50 * u, kind: k, fill: white, stroke: ink), base: 50)),
  scales("exclusive, marker hidden",
    u => shape-gateway(50 * u, 50 * u, kind: "exclusive", marker: false,
      fill: white, stroke: ink), base: 50))

= Data and artifacts

#grid(columns: 4, row-gutter: 9pt,
  scales("data object", u => shape-data(36 * u, 50 * u, stroke: ink)),
  scales("collection", u => shape-data(36 * u, 50 * u, collection: true, stroke: ink)),
  scales("data input", u => shape-data(36 * u, 50 * u, direction: "input", stroke: ink)),
  scales("data output", u => shape-data(36 * u, 50 * u, direction: "output", stroke: ink)),
  scales("data store", u => shape-data(50 * u, 50 * u, kind: "store", stroke: ink), base: 50))

#v(4pt)
#grid(columns: 2, column-gutter: 12pt,
  cell("text annotation", box(width: 120pt, height: 42pt,
    shape-annotation(120pt, 42pt, stroke: ink)), w: 130pt),
  cell("group", box(width: 170pt, height: 42pt,
    shape-group(170pt, 42pt)), w: 180pt))

#pagebreak()

= Colour palette

The six swatches Camunda Modeler's colour picker offers, plus its default.
Values match `bpmn-io/bpmn-js-color-picker`; the reference model uses orange,
green and red.

#let sw(name) = {
  let c = swatch(name)
  box(width: 84pt)[#align(center)[
    #shape-task(76pt, 46pt, kind: "user", fill: c.fill, stroke: c.stroke)
    #v(3pt)
    #text(size: 7pt)[#raw(name)] \
    #text(size: 5.5pt, fill: rgb("#666"))[#upper(c.fill.to-hex()) / #upper(c.stroke.to-hex())]
  ]]
}

#grid(columns: 4, row-gutter: 10pt, column-gutter: 4pt,
  ..("default", "blue", "orange", "green", "red", "purple").map(sw))

*Semantic aliases* — `success` `happy` → green, `failure` `error` `reject` → red,
`warning` `rework` → orange, `info` → blue, `external` → purple.

= Connections

#let flowline(body) = box(width: 150pt, height: 26pt, body)

#table(columns: (auto, 1fr), stroke: none, inset: (x: 0pt, y: 4pt),
  align: (left + horizon, left + horizon),
  [*sequence*], [solid line, solid arrowhead],
  [*sequence (default)*], [plus a slash near the source],
  [*sequence (conditional)*], [plus a hollow diamond near the source],
  [*message*], [dashed line, hollow arrowhead, hollow circle at the source],
  [*association*], [dotted line, open arrowhead when directed],
  [*data association*], [dotted line, open arrowhead],
)

Connections are drawn by the renderer rather than the shape library, so they are
exercised by the model renders in `demo.typ` instead of here.
