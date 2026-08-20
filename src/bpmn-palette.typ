// The Camunda Modeler / bpmn.io colour palette.
//
// These are the six swatches the colour picker in Camunda Modeler offers, plus
// the renderer's own defaults. Values verified against bpmn-io/bpmn-js-color-picker
// (`colors/ColorPopupProvider.js`) and against the colours Camunda actually wrote
// into the reference model.
//
// Only the numbers are taken: the shapes in this project are drawn from the OMG
// BPMN 2.0 specification, not copied from bpmn-js.
//
//   #bpmn-figure(M, theme: default-theme + (palette: solarized))
//
// In a model, name a swatch instead of repeating hex:
//
//   - { id: t1, kind: task, name: Gửi chấp thuận, color: green }
//
// which is equivalent to `fill: "#C8E6C9", stroke: "#205022"`. An explicit
// `fill:`/`stroke:` always wins over `color:`.

/// Camunda Modeler's stock palette.
#let camunda-palette = (
  default: (fill: rgb("#FFFFFF"), stroke: rgb("#22242A")),
  blue:    (fill: rgb("#BBDEFB"), stroke: rgb("#0D4372")),
  orange:  (fill: rgb("#FFE0B2"), stroke: rgb("#6B3C00")),
  green:   (fill: rgb("#C8E6C9"), stroke: rgb("#205022")),
  red:     (fill: rgb("#FFCDD2"), stroke: rgb("#831311")),
  purple:  (fill: rgb("#E1BEE7"), stroke: rgb("#5B176D")),
)

/// Same hues, no fill: for documents that want colour coding without the wash.
#let outline-palette = {
  let p = (:)
  for (k, v) in camunda-palette { p.insert(k, (fill: rgb("#FFFFFF"), stroke: v.stroke)) }
  p
}

/// Everything black on white.
#let mono-palette = {
  let p = (:)
  for (k, _) in camunda-palette {
    p.insert(k, (fill: rgb("#FFFFFF"), stroke: rgb("#22242A")))
  }
  p
}

/// Semantic aliases. BPMN has no notion of a "happy path", but every reader does,
/// and these are the conventions the reference model already uses.
#let semantic-aliases = (
  success: "green",
  happy: "green",
  failure: "red",
  error: "red",
  reject: "red",
  warning: "orange",
  rework: "orange",
  info: "blue",
  external: "purple",
)

/// Resolve a swatch name to (fill, stroke). Unknown names fall back to `default`
/// rather than failing the build: a typo in a colour should not stop a report.
#let swatch(name, palette: camunda-palette) = {
  if name == none { return none }
  let key = lower(str(name))
  if key in semantic-aliases { key = semantic-aliases.at(key) }
  palette.at(key, default: palette.at("default", default: (
    fill: rgb("#FFFFFF"), stroke: rgb("#22242A"))))
}

/// Names a model may use, for docs and error messages.
#let swatch-names = camunda-palette.keys() + semantic-aliases.keys()
