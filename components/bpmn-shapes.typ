// BPMN 2.0 shape vocabulary — pure Typst, no external packages.
//
// Every function returns content sized exactly (w, h) so the renderer can
// `place` it at absolute coordinates. Icons are drawn in a unit square and
// scaled, which keeps them crisp at any diagram scale.

#let _p(v) = if type(v) == length { v } else { v * 1pt }

// ---------------------------------------------------------------- helpers ---

#let canvas(w, h, ..body) = box(width: w, height: h, {
  for b in body.pos() { b }
})

/// Draw a polyline/polygon in a unit square scaled to `size`.
#let unit-path(size, pts, close: false, stroke: none, fill: none) = {
  let c = pts.map(((x, y)) => (x * size, y * size))
  place(curve(
    stroke: stroke, fill: fill,
    curve.move(c.first()),
    ..c.slice(1).map(p => curve.line(p)),
    ..if close { (curve.close(),) } else { () },
  ))
}

// ------------------------------------------------------------------ icons ---
// All take `size` (length) and return content of that size.

#let icon-message(size, filled: false, paint: black) = {
  let bg = if filled { paint } else { none }
  let fg = if filled { white } else { paint }
  canvas(size, size,
    place(dy: 0.16 * size, rect(width: size, height: 0.68 * size,
      stroke: 0.055 * size + paint, fill: bg)),
    unit-path(size, ((0.02, 0.19), (0.5, 0.56), (0.98, 0.19)), stroke: 0.055 * size + fg),
  )
}

#let icon-timer(size, paint: black) = canvas(size, size,
  place(circle(radius: 0.46 * size, stroke: 0.055 * size + paint)),
  ..range(12).map(i => {
    let a = i * 30deg
    let (c, s) = (calc.cos(a), calc.sin(a))
    place(curve(stroke: 0.04 * size + paint,
      curve.move((0.46 * size + 0.38 * size * c, 0.46 * size + 0.38 * size * s)),
      curve.line((0.46 * size + 0.45 * size * c, 0.46 * size + 0.45 * size * s))))
  }),
  place(curve(stroke: 0.055 * size + paint,
    curve.move((0.46 * size, 0.46 * size)), curve.line((0.46 * size, 0.16 * size)))),
  place(curve(stroke: 0.055 * size + paint,
    curve.move((0.46 * size, 0.46 * size)), curve.line((0.70 * size, 0.60 * size)))),
)

#let icon-user(size, paint: black) = canvas(size, size,
  place(rect(width: size, height: size, stroke: 0.05 * size + paint, radius: 0.06 * size)),
  place(dx: 0.36 * size, dy: 0.12 * size,
    circle(radius: 0.14 * size, stroke: 0.05 * size + paint)),
  place(curve(stroke: 0.05 * size + paint,
    curve.move((0.16 * size, 0.94 * size)),
    curve.cubic((0.20 * size, 0.52 * size), (0.80 * size, 0.52 * size), (0.84 * size, 0.94 * size)))),
)

// Outlined gear. Filled teeth on a filled disc turn into an unreadable blob once
// the diagram is scaled down, so this is drawn as strokes throughout.
#let icon-service(size, paint: black) = {
  let (cx, cy) = (0.5 * size, 0.5 * size)
  let t = 0.075 * size
  let teeth = range(8).map(i => {
    let a = i * 45deg
    let (c, s) = (calc.cos(a), calc.sin(a))
    place(curve(stroke: (paint: paint, thickness: t, cap: "round"),
      curve.move((cx + 0.30 * size * c, cy + 0.30 * size * s)),
      curve.line((cx + 0.47 * size * c, cy + 0.47 * size * s))))
  })
  canvas(size, size,
    ..teeth,
    place(dx: cx - 0.30 * size, dy: cy - 0.30 * size,
      circle(radius: 0.30 * size, stroke: t + paint)),
    place(dx: cx - 0.12 * size, dy: cy - 0.12 * size,
      circle(radius: 0.12 * size, fill: paint)),
  )
}

#let icon-script(size, paint: black) = canvas(size, size,
  place(dx: 0.14 * size, rect(width: 0.72 * size, height: size,
    stroke: 0.05 * size + paint, radius: (top-left: 0.3 * size, bottom-right: 0.3 * size))),
  ..range(3).map(i => place(dx: 0.26 * size, dy: (0.26 + i * 0.22) * size,
    curve(stroke: 0.045 * size + paint, curve.move((0pt, 0pt)), curve.line((0.48 * size, 0pt))))),
)

#let icon-rule(size, paint: black) = canvas(size, size,
  place(dy: 0.12 * size, rect(width: size, height: 0.76 * size, stroke: 0.05 * size + paint)),
  place(dy: 0.12 * size, rect(width: size, height: 0.22 * size, fill: paint)),
  place(dy: 0.50 * size, curve(stroke: 0.045 * size + paint,
    curve.move((0pt, 0pt)), curve.line((size, 0pt)))),
  place(dx: 0.38 * size, dy: 0.34 * size, curve(stroke: 0.045 * size + paint,
    curve.move((0pt, 0pt)), curve.line((0pt, 0.54 * size)))),
)

// A hand: palm plus four fingers reaching right.
#let icon-manual(size, paint: black) = canvas(size, size,
  place(dx: 0.02 * size, dy: 0.40 * size,
    rect(width: 0.34 * size, height: 0.40 * size,
      stroke: 0.055 * size + paint, radius: (left: 0.14 * size))),
  ..range(4).map(i => place(dx: 0.30 * size, dy: (0.30 + i * 0.135) * size,
    rect(width: (0.62 - i * 0.06) * size, height: 0.105 * size,
      stroke: 0.045 * size + paint, radius: 0.05 * size))),
)

#let icon-error(size, paint: black, filled: false) = unit-path(size,
  ((0.10, 0.92), (0.38, 0.24), (0.60, 0.58), (0.90, 0.10), (0.62, 0.80), (0.40, 0.46)),
  close: true, stroke: 0.06 * size + paint, fill: if filled { paint } else { none })

#let icon-signal(size, paint: black, filled: false) = unit-path(size,
  ((0.5, 0.10), (0.96, 0.86), (0.04, 0.86)),
  close: true, stroke: 0.07 * size + paint, fill: if filled { paint } else { none })

#let icon-escalation(size, paint: black, filled: false) = unit-path(size,
  ((0.5, 0.06), (0.92, 0.94), (0.5, 0.54), (0.08, 0.94)),
  close: true, stroke: 0.06 * size + paint, fill: if filled { paint } else { none })

#let icon-link(size, paint: black, filled: false) = unit-path(size,
  ((0.06, 0.36), (0.56, 0.36), (0.56, 0.16), (0.96, 0.50), (0.56, 0.84), (0.56, 0.64), (0.06, 0.64)),
  close: true, stroke: 0.06 * size + paint, fill: if filled { paint } else { none })

#let icon-conditional(size, paint: black) = canvas(size, size,
  place(rect(width: 0.86 * size, height: size, stroke: 0.055 * size + paint)),
  ..range(4).map(i => place(dx: 0.1 * size, dy: (0.17 + i * 0.22) * size,
    curve(stroke: 0.05 * size + paint, curve.move((0pt, 0pt)), curve.line((0.66 * size, 0pt))))),
)

#let icon-compensate(size, paint: black, filled: false) = {
  let f = if filled { paint } else { none }
  canvas(size, size,
    unit-path(size, ((0.46, 0.10), (0.46, 0.90), (0.02, 0.50)), close: true,
      stroke: 0.06 * size + paint, fill: f),
    unit-path(size, ((0.98, 0.10), (0.98, 0.90), (0.54, 0.50)), close: true,
      stroke: 0.06 * size + paint, fill: f),
  )
}

#let icon-terminate(size, paint: black) = place(circle(radius: 0.5 * size, fill: paint))

#let event-icon(definition, size, paint: black, filled: false) = {
  let f = filled
  if definition == "message" { icon-message(size, filled: f, paint: paint) }
  else if definition == "timer" { icon-timer(size, paint: paint) }
  else if definition == "error" { icon-error(size, paint: paint, filled: f) }
  else if definition == "signal" { icon-signal(size, paint: paint, filled: f) }
  else if definition == "escalation" { icon-escalation(size, paint: paint, filled: f) }
  else if definition == "link" { icon-link(size, paint: paint, filled: f) }
  else if definition == "conditional" { icon-conditional(size, paint: paint) }
  else if definition == "compensate" { icon-compensate(size, paint: paint, filled: f) }
  else if definition == "terminate" { icon-terminate(size, paint: paint) }
  else { none }
}

#let task-icon(kind, size, paint: black) = {
  if kind == "user" { icon-user(size, paint: paint) }
  else if kind == "service" { icon-service(size, paint: paint) }
  else if kind == "send" { icon-message(size, filled: true, paint: paint) }
  else if kind == "receive" { icon-message(size, filled: false, paint: paint) }
  else if kind == "manual" { icon-manual(size, paint: paint) }
  else if kind == "script" { icon-script(size, paint: paint) }
  else if kind == "rule" { icon-rule(size, paint: paint) }
  else { none }
}


// --------------------------------------------------------- activity markers ---
// BPMN draws these in a row, centred along the bottom edge of an activity.

#let marker-sub(size, paint: black) = canvas(size, size,
  place(rect(width: size, height: size, stroke: 0.09 * size + paint)),
  place(dy: size / 2, curve(stroke: 0.09 * size + paint,
    curve.move((0.22 * size, 0pt)), curve.line((0.78 * size, 0pt)))),
  place(dx: size / 2, curve(stroke: 0.09 * size + paint,
    curve.move((0pt, 0.22 * size)), curve.line((0pt, 0.78 * size)))),
)

#let marker-loop(size, paint: black) = {
  let (cx, cy, r) = (0.5 * size, 0.54 * size, 0.38 * size)
  canvas(size, size,
    place(curve(stroke: (paint: paint, thickness: 0.09 * size, cap: "round"),
      curve.move((cx + r * calc.cos(35deg), cy - r * calc.sin(35deg))),
      curve.cubic((cx + r * 1.5, cy - r * 1.2), (cx - r * 1.5, cy - r * 1.2),
                  (cx - r * calc.cos(20deg), cy + r * calc.sin(20deg))),
      curve.cubic((cx - r * 0.6, cy + r * 1.3), (cx + r * 0.6, cy + r * 1.3),
                  (cx + r * 0.95, cy + r * 0.45)))),
    // arrowhead on the open end
    unit-path(size, ((0.72, 0.30), (0.98, 0.36), (0.80, 0.56)), close: true, fill: paint),
  )
}

#let marker-mi(size, paint: black, sequential: false) = canvas(size, size,
  ..range(3).map(i => if sequential {
    place(dy: (0.16 + i * 0.30) * size,
      rect(width: size, height: 0.13 * size, fill: paint))
  } else {
    place(dx: (0.16 + i * 0.30) * size,
      rect(width: 0.13 * size, height: size, fill: paint))
  }))

#let marker-compensation(size, paint: black) = canvas(size, size,
  unit-path(size, ((0.46, 0.14), (0.46, 0.86), (0.02, 0.50)), close: true,
    stroke: 0.07 * size + paint, fill: paint),
  unit-path(size, ((0.96, 0.14), (0.96, 0.86), (0.52, 0.50)), close: true,
    stroke: 0.07 * size + paint, fill: paint),
)

#let marker-adhoc(size, paint: black) = place(dy: 0.5 * size, curve(
  stroke: (paint: paint, thickness: 0.13 * size, cap: "round"),
  curve.move((0.04 * size, 0pt)),
  curve.cubic((0.28 * size, -0.42 * size), (0.44 * size, 0.42 * size), (0.62 * size, 0pt)),
  curve.cubic((0.76 * size, -0.30 * size), (0.86 * size, -0.24 * size), (0.96 * size, -0.12 * size)),
))

#let activity-marker(kind, size, paint: black) = {
  if kind == "sub" { marker-sub(size, paint: paint) }
  else if kind == "loop" { marker-loop(size, paint: paint) }
  else if kind == "mi-parallel" { marker-mi(size, paint: paint) }
  else if kind == "mi-sequential" { marker-mi(size, paint: paint, sequential: true) }
  else if kind == "compensation" { marker-compensation(size, paint: paint) }
  else if kind == "adhoc" { marker-adhoc(size, paint: paint) }
  else { none }
}

/// Lay a row of markers along the bottom edge of a (w, h) activity.
#let marker-row(w, h, markers, paint: black) = {
  let ms = markers.filter(m => m != none and m != "")
  if ms.len() == 0 { return none }
  let s = calc.min(w, h) * 0.16
  let gap = s * 0.35
  let total = ms.len() * s + (ms.len() - 1) * gap
  ms.enumerate().map(((i, m)) => {
    let ic = activity-marker(m, s, paint: paint)
    if ic == none { none } else {
      place(dx: w / 2 - total / 2 + i * (s + gap), dy: h - s * 1.45, ic)
    }
  }).join()
}

// ------------------------------------------------------------------ nodes ---

/// Event: circle, ring style by family, icon by definition.
#let shape-event(w, h, family: "start", definition: "none", throw: false,
                 interrupting: true, fill: white, stroke: black) = {
  let r = calc.min(w, h) / 2
  let dash = if family == "boundary" and not interrupting { "dashed" } else { none }
  let thin = 0.055 * r * 2
  let thick = 0.13 * r * 2
  let outer = if family == "end" { thick } else { thin }
  let ring = (
    place(circle(radius: r, fill: fill,
      stroke: (paint: stroke, thickness: outer, dash: dash))),
  )
  let inner = if family in ("intermediate", "boundary") {
    (place(dx: 0.11 * r, dy: 0.11 * r, circle(radius: 0.89 * r,
      stroke: (paint: stroke, thickness: thin, dash: dash))),)
  } else { () }
  let ic = event-icon(definition, r, paint: stroke, filled: throw)
  canvas(w, h, ..ring, ..inner,
    if ic != none { place(dx: r - r / 2, dy: r - r / 2, ic) })
}

/// Activity: rounded rectangle, type marker top-left, behaviour markers bottom-centre.
/// A call activity gets the spec's thick border.
#let shape-task(w, h, kind: "none", markers: (), fill: white, stroke: black, radius: 10) = {
  let m = calc.min(w, h) * 0.18
  let ic = task-icon(kind, m, paint: stroke)
  let t = 1.6pt * (w / 100pt) * (if kind == "call" { 2.8 } else { 1 })
  canvas(w, h,
    place(rect(width: w, height: h, fill: fill, stroke: t + stroke,
      radius: radius * (w / 100))),
    if ic != none { place(dx: 0.06 * w, dy: 0.06 * w, ic) },
    marker-row(w, h, markers, paint: stroke))
}

/// Sub-process: a task frame plus the collapsed [+] and any behaviour markers.
/// `transaction` draws the spec's double border, `event-sub` the dashed one.
#let shape-subprocess(w, h, expanded: false, event-sub: false, transaction: false,
                      markers: (), fill: white, stroke: black) = {
  let t = 1.6pt * (w / 100pt)
  let r = 10 * (w / 100)
  let inner = if transaction {
    let d = 0.04 * calc.min(w, h)
    (place(dx: d, dy: d, rect(width: w - 2 * d, height: h - 2 * d,
      stroke: t + stroke, radius: r * 0.8)),)
  } else { () }
  let ms = if expanded { markers } else { ("sub",) + markers }
  canvas(w, h,
    place(rect(width: w, height: h, fill: fill, radius: r,
      stroke: (paint: stroke, thickness: t,
               dash: if event-sub { "dashed" } else { none }))),
    ..inner,
    marker-row(w, h, ms, paint: stroke))
}

/// Gateway: diamond with the symbol for its kind.
#let shape-gateway(w, h, kind: "exclusive", marker: true, fill: white, stroke: black) = {
  let t = 1.6pt * (w / 50pt)
  let s = calc.min(w, h)
  let g = 0.28 * s // symbol half-extent
  let sym = if kind == "exclusive" and marker {
    (unit-path(s, ((0.30, 0.30), (0.70, 0.70)), stroke: 0.075 * s + stroke),
     unit-path(s, ((0.70, 0.30), (0.30, 0.70)), stroke: 0.075 * s + stroke))
  } else if kind == "parallel" {
    (unit-path(s, ((0.5, 0.22), (0.5, 0.78)), stroke: 0.075 * s + stroke),
     unit-path(s, ((0.22, 0.5), (0.78, 0.5)), stroke: 0.075 * s + stroke))
  } else if kind == "inclusive" {
    (place(dx: 0.5 * s - 0.28 * s, dy: 0.5 * s - 0.28 * s,
      circle(radius: 0.28 * s, stroke: 0.075 * s + stroke)),)
  } else if kind == "event" {
    (place(dx: 0.5 * s - 0.32 * s, dy: 0.5 * s - 0.32 * s,
      circle(radius: 0.32 * s, stroke: 0.045 * s + stroke)),
     place(dx: 0.5 * s - 0.27 * s, dy: 0.5 * s - 0.27 * s,
      circle(radius: 0.27 * s, stroke: 0.045 * s + stroke)),
     unit-path(s, ((0.50, 0.29), (0.70, 0.43), (0.62, 0.67), (0.38, 0.67), (0.30, 0.43)),
      close: true, stroke: 0.05 * s + stroke))
  } else if kind == "complex" {
    (unit-path(s, ((0.5, 0.20), (0.5, 0.80)), stroke: 0.07 * s + stroke),
     unit-path(s, ((0.20, 0.5), (0.80, 0.5)), stroke: 0.07 * s + stroke),
     unit-path(s, ((0.28, 0.28), (0.72, 0.72)), stroke: 0.07 * s + stroke),
     unit-path(s, ((0.72, 0.28), (0.28, 0.72)), stroke: 0.07 * s + stroke))
  } else { () }
  canvas(w, h,
    place(curve(fill: fill, stroke: t + stroke,
      curve.move((w / 2, 0pt)), curve.line((w, h / 2)),
      curve.line((w / 2, h)), curve.line((0pt, h / 2)), curve.close())),
    ..sym)
}

/// Data object: page with a folded corner. `store` draws a cylinder instead.
#let shape-data(w, h, kind: "object", collection: false, direction: none,
                fill: white, stroke: black) = {
  let t = 1.2pt * (w / 36pt)
  if kind == "store" {
    let e = 0.16 * h
    canvas(w, h,
      place(curve(fill: fill, stroke: t + stroke,
        curve.move((0pt, e)),
        curve.cubic((0pt, 0pt), (w, 0pt), (w, e)),
        curve.line((w, h - e)),
        curve.cubic((w, h), (0pt, h), (0pt, h - e)),
        curve.close())),
      place(curve(stroke: t + stroke,
        curve.move((0pt, e)), curve.cubic((0pt, 2 * e), (w, 2 * e), (w, e)))),
    )
  } else {
    let f = 0.3 * w
    let a = 0.2 * w
    // data input is an open arrow, data output a filled one
    let arrow = if direction == none { () } else {
      (place(dx: 0.13 * w, dy: 0.1 * h, canvas(a, a,
        unit-path(a, ((0.0, 0.35), (0.55, 0.35), (0.55, 0.1), (1.0, 0.5),
                      (0.55, 0.9), (0.55, 0.65), (0.0, 0.65)),
          close: true, stroke: 0.08 * a + stroke,
          fill: if direction == "output" { stroke } else { none }))),)
    }
    let coll = if not collection { () } else {
      range(3).map(i => place(dx: w / 2 - 0.16 * w + i * 0.16 * w, dy: h - 0.26 * h,
        rect(width: 0.05 * w, height: 0.2 * h, fill: stroke)))
    }
    canvas(w, h,
      place(curve(fill: fill, stroke: t + stroke,
        curve.move((0pt, 0pt)), curve.line((w - f, 0pt)), curve.line((w, f)),
        curve.line((w, h)), curve.line((0pt, h)), curve.close())),
      place(curve(stroke: t + stroke,
        curve.move((w - f, 0pt)), curve.line((w - f, f)), curve.line((w, f)))),
      ..arrow, ..coll,
    )
  }
}

/// Group: dashed rounded rectangle (no semantics, purely visual grouping).
#let shape-group(w, h, stroke: rgb("#666666")) = place(rect(width: w, height: h,
  stroke: (paint: stroke, thickness: 1.2pt * (w / 400pt), dash: "loosely-dashed"),
  radius: 6pt))

/// Text annotation: the open left bracket only.
#let shape-annotation(w, h, stroke: black) = {
  let t = 1pt * calc.max(0.4, h / 40pt)
  let arm = calc.min(0.22 * w, 0.18 * h)
  place(curve(stroke: t + stroke,
    curve.move((arm, 0pt)), curve.line((0pt, 0pt)),
    curve.line((0pt, h)), curve.line((arm, h))))
}
