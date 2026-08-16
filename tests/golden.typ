// Structural golden file.
//
// Renders nothing. For a fixed matrix of model x view x compact, it records the
// numbers that describe the result: element counts, the extent the layout
// settled on, and the label size that extent implies at a reference width.
//
//   just golden          regenerate and diff against tests/golden/manifest.json
//   just golden-update   re-approve after an intentional change
//
// Why numbers instead of reference images: a PNG depends on which fonts the
// machine has, so a pixel golden would fail on someone else's laptop for
// reasons that have nothing to do with the code. These numbers are
// font-independent and the diff says *what* moved, not just that something did.
//
// What this does not catch: changes to how a shape is drawn. The extent is
// unchanged if an icon is redrawn. That is what tests/conformance.typ is for —
// it is a visual check, run by eye.

#import "/src/bpmn.typ": *

#let REF-WIDTH = 174mm

// (label, source)
#let MODELS = (
  ("b04", yaml("/models/b04-btvn01.yaml")),
  ("vertical", yaml("/models/vertical-pools.yaml")),
  ("no-pool", yaml("/models/leading-comment.yaml")),
  ("grid", yaml("/examples/leave-request.yaml")),
)

// (label, view, compact)
#let CASES = (
  ("full", none, none),
  ("compact-x", none, true),
  ("compact-both", none, (axis: "both")),
)

// views that only apply to particular models
#let SLICES = (
  ("b04", "pool-ts", (pool: "Thí Sinh"), true),
  ("b04", "pool-ts-nobb", (pool: "Thí Sinh", blackbox: false), true),
  ("b04", "lane-hdht", (lane: "Hội Đồng Học Thuật"), true),
  ("vertical", "pool-bank", (pool: "Ngân hàng"), true),
)

#let snap(src, vw, cp) = {
  let i = bpmn-info(src, view: vw, compact: cp, width: REF-WIDTH)
  (
    pools: i.pools,
    lanes: i.lanes,
    nodes: i.nodes,
    flows: i.flows,
    w: calc.round(i.extent.w),
    h: calc.round(i.extent.h),
    label-pt: calc.round(i.label-size / 1pt, digits: 2),
    by-kind: i.by-kind,
  )
}

#let rows = {
  let out = (:)
  for (mname, src) in MODELS {
    for (cname, vw, cp) in CASES {
      out.insert(mname + " / " + cname, snap(src, vw, cp))
    }
  }
  for (mname, cname, vw, cp) in SLICES {
    let src = MODELS.find(((n, _)) => n == mname).at(1)
    out.insert(mname + " / " + cname, snap(src, vw, cp))
  }
  out
}

#metadata(rows) <golden>

// Something has to be on the page or Typst has no document to query.
#set page(width: 100mm, height: auto, margin: 5mm)
#set text(size: 8pt)
#text(weight: "bold")[typst-bpmn golden manifest] \
#rows.len() cases · reference width #REF-WIDTH
