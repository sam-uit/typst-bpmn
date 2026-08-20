// The dual-parser guard.
//
// The YAML converter and the in-Typst XML reader must produce the same model.
// Two parsers in two languages will drift the moment one is changed without the
// other, and a single shared renderer is the only reason the drift would ever be
// visible. This makes it fail the build instead.
//
//   just check

#import "/src/bpmn.typ": *

#set page(paper: "a4", margin: 16mm)
#set text(font: "Lora", size: 10pt)

// (label, converted YAML, source XML)
#let PAIRS = (
  ("b04-btvn01", yaml("/models/b04-btvn01.yaml"), xml("/samples/b04-btvn01.bpmn")),
  // vertical pools, and a leading XML comment ahead of the root element
  ("vertical-pools", yaml("/models/vertical-pools.yaml"),
   xml("/tests/fixtures/vertical-pools.bpmn")),
)

// Views to compare, so the check covers slicing and compaction too, not just the
// bare parse.
#let CASES = (
  ("full", none, none),
  ("compact x", none, true),
  ("compact both", none, (axis: "both")),
)

// Slice cases run only where the named pool exists, so they are listed per model.

= Parser agreement

#let rows = ()
#let failures = 0

#for (name, y, x) in PAIRS {
  for (case, vw, cp) in CASES {
    let a = bpmn-info(y, view: vw, compact: cp)
    let b = bpmn-info(x, view: vw, compact: cp)
    // label-size is a length derived from the extent; comparing the whole
    // dictionary catches geometry drift as well as element counts
    let same = a == b
    if not same { failures += 1 }
    rows.push((name, case, a, b, same))
  }
}

#table(
  columns: (auto, auto, auto, auto, auto, auto),
  stroke: none,
  inset: (x: 4pt, y: 3pt),
  align: (left, left, right, right, right, center),
  table.hline(),
  [*model*], [*view*], [*nodes*], [*flows*], [*extent*], [*match*],
  table.hline(stroke: 0.4pt),
  ..rows.map(((n, c, a, b, ok)) => (
    raw(n), raw(c), str(a.nodes), str(a.flows),
    [#calc.round(a.extent.w)×#calc.round(a.extent.h)],
    if ok { text(fill: green.darken(30%))[✓] } else { text(fill: red)[✗] },
  )).flatten(),
  table.hline(),
)

#if failures > 0 {
  panic("parser disagreement in " + str(failures) + " case(s), "
    + "the YAML converter and bpmn-xml.typ have drifted apart")
}

All #str(rows.len()) comparisons agree.

= Coverage

#let cov = bpmn-info(PAIRS.first().at(1))
The reference model exercises:
#for (k, v) in cov.by-kind [ #raw(k): #v · ]
