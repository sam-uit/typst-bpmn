// BPMN 2.0 shape vocabulary: pure Typst, no external packages.
//
// Every function returns content sized exactly (w, h) so the renderer can
// `place` it at absolute coordinates. Icons are drawn in a unit square and
// scaled, which keeps them crisp at any diagram scale.

#let _p(v) = if type(v) == length { v } else { v * 1pt }

// ---------------------------------------------------------------- helpers ---

/// One BPMN unit as a length.
///
/// Shapes are handed pre-scaled lengths (`b.w * u`), not the model's numbers, so
/// they cannot see the scale directly. The old trick was to divide by 100 and
/// assume the caller had drawn an activity, true for a task, which BPMN fixes at
/// 100x80, and badly wrong for an expanded sub-process at 350 wide, whose border
/// then came out three and a half times too thick. Callers that know the scale
/// pass `unit:`; the division stays as the fallback so a hand call still works.
#let _scale(w, unit, nominal: 100) = if unit == none { w / nominal } else { unit }

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

// The dial is centred on the box, like every other icon here. It used to be built
// around 0.46: `place(circle(radius: 0.46 * size))` puts the *edge* at the origin,
// so the centre lands at 0.46, not 0.5, and the whole clock sat 0.04 × size up and
// to the left inside its box. Subtle on its own and obvious once the icon is inside
// an event ring, where the white margin is visibly fatter on the right and below.
#let icon-timer(size, paint: black) = {
  let (cx, cy, r) = (0.5 * size, 0.5 * size, 0.46 * size)
  canvas(size, size,
    place(dx: cx - r, dy: cy - r, circle(radius: r, stroke: 0.055 * size + paint)),
    ..range(12).map(i => {
      let a = i * 30deg
      let (c, s) = (calc.cos(a), calc.sin(a))
      place(curve(stroke: 0.04 * size + paint,
        curve.move((cx + 0.38 * size * c, cy + 0.38 * size * s)),
        curve.line((cx + 0.45 * size * c, cy + 0.45 * size * s))))
    }),
    place(curve(stroke: 0.055 * size + paint,
      curve.move((cx, cy)), curve.line((cx, cy - 0.30 * size)))),
    place(curve(stroke: 0.055 * size + paint,
      curve.move((cx, cy)), curve.line((cx + 0.24 * size, cy + 0.14 * size)))),
  )
}

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

/// Loop marker: a circular arc whose arrowhead is *part of the arc*.
///
/// Three revisions, each fixing what the previous one still got wrong:
///
/// 1. Two hand-fitted cubics with the head pinned at fixed unit coordinates. The head
///    was not on the curve at all, a wedge parked beside it, and the mark was
///    off-centre.
/// 2. A real arc with the head built on the *tangent at the tip*. Geometrically correct
///    and still wrong to look at: a straight head leaving a curve reads as flying off
///    the path, and its square base met the curving stroke at an angle, leaving a notch.
/// 3. This one. Both ends of the head sit **on the circle**, so the head leans with the
///    turn instead of escaping it: the arc's momentum carries through the tip. And the
///    base edge runs **along the radius** at its own angle, which is by construction
///    perpendicular to the arc's tangent exactly where the stroke ends, so the two meet
///    square and the notch is gone.
///
/// The construction, in the order you would draw it by hand:
///
///   - run the arc round to the far end of the sweep and call that point the tip;
///   - from the tip, step back **along the circle** by the head's length to get the
///     base point, so both points are on the curve and the head's axis is their chord;
///   - open the base out to either side along the radius by the head's height.
///
/// So the two knobs are the ones you would actually reach for: `head-len` and
/// `head-half`, both a fraction of the box. The angle is derived, never typed,
/// `Δ = 2·asin(L / 2r)`, which keeps the head the same *length* if the radius is ever
/// retuned, instead of silently growing.
///
/// ## Which way round, and where the gap sits
///
/// BPMN 2.0 draws this marker **anticlockwise with the gap at the bottom**: the tail
/// starts around half past five, the arc runs the long way round, and the head stops
/// around seven. The first version here ran clockwise with the gap at the top, which is
/// the same picture flipped about the horizontal axis, right shape, wrong statement.
///
/// Two lines carry that. `P` measures y **downwards** from the centre instead of
/// upwards, which mirrors the whole construction and, because mirroring reverses
/// handedness, turns ↻ into ↺ without touching the sweep. `phase` then rolls the
/// finished figure round the circle by a fixed angle to put the gap where the spec
/// wants it: at `phase = 0` the tail sits at half past four and the head at six
/// o'clock, and −30° moves both on by an hour to 5:30 and 7:00.
///
/// ## Centring
///
/// The figure is built around the origin and moved to the middle afterwards, from the
/// **inked** extent: the arc widened by half the stroke, plus the three corners of the
/// solid head. Solving that by hand only works while the gap sits on an axis; the
/// moment `phase` moves it, a hand-fitted centre is silently wrong on one side.
///
/// Corners are rounded with a `join: "round"` stroke in the fill colour. Everything
/// else in this family is drawn with `cap: "round"`, and a single sharp point is
/// exactly the kind of detail that looks wrong without anyone being able to say why.
///
/// The obvious alternative (the glyph `↻`) was tried and rejected: it comes out far
/// lighter than the neighbouring markers (this family is drawn at 0.09–0.13 × size),
/// and it would make a BPMN symbol depend on whichever font the host document happens
/// to set. The same symbol has to look the same in every report.
#let marker-loop(size, paint: black, phase: -30deg) = {
  let r = 0.36 * size
  let t = 0.10 * size
  let head-len = 0.25 * size      // tip to base, stepped back along the circle
  let hw = 0.11 * size            // height either side of the base, along the radius
  let round = 0.03 * size         // corner radius, via a round-join stroke
  let sweep = 315deg
  // Anticlockwise: y measured *down* from the centre. `phase` rolls the whole figure
  // round the circle, so the gap lands at the bottom where BPMN puts it.
  let P(a) = (r * calc.sin(a + phase), r * calc.cos(a + phase))
  // Chord of length `head-len` subtends 2·asin(L / 2r).
  let base-a = 360deg - 2 * calc.asin(head-len / (2 * r))
  let bc = P(base-a)
  // Outward radial at the base angle. The base edge lies along it, so it is square to
  // the arc where the stroke stops: hence the arc runs to exactly `base-a`, no
  // overlap and no shortfall.
  let (rx, ry) = (calc.sin(base-a + phase), calc.cos(base-a + phase))
  let n = 60
  let a0 = 360deg - sweep
  let arc = range(n + 1).map(i => P(a0 + (base-a - a0) * i / n))
  let head = (
    P(360deg),
    (bc.at(0) + hw * rx, bc.at(1) + hw * ry),
    (bc.at(0) - hw * rx, bc.at(1) - hw * ry),
  )
  // Inked extent: the arc grows by half the stroke on every side, the head by half its
  // own round join. Centre on that, not on the circle.
  let pad-arc = t / 2
  let pad-head = round / 2
  let spread(ps, pad, i) = ps.map(p => p.at(i) - pad) + ps.map(p => p.at(i) + pad)
  let axis(i) = {
    let vs = spread(arc, pad-arc, i) + spread(head, pad-head, i)
    0.5 * size - (calc.min(..vs) + calc.max(..vs)) / 2
  }
  let (dx, dy) = (axis(0), axis(1))
  let T(p) = (p.at(0) + dx, p.at(1) + dy)
  canvas(size, size,
    place(curve(stroke: (paint: paint, thickness: t, cap: "round"),
      curve.move(T(arc.first())), ..arc.slice(1).map(p => curve.line(T(p))))),
    place(curve(
      fill: paint,
      stroke: (paint: paint, thickness: round, join: "round", cap: "round"),
      curve.move(T(head.first())),
      ..head.slice(1).map(p => curve.line(T(p))),
      curve.close())),
  )
}

// Three bars of 0.13 with 0.17 between them span 0.73, so the margins are 0.135,
// not the 0.16 that was there, which pushed the group 0.025 off centre.
#let marker-mi(size, paint: black, sequential: false) = canvas(size, size,
  ..range(3).map(i => if sequential {
    place(dy: (0.135 + i * 0.30) * size,
      rect(width: size, height: 0.13 * size, fill: paint))
  } else {
    place(dx: (0.135 + i * 0.30) * size,
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
#let marker-row(w, h, markers, paint: black, unit: none) = {
  let ms = markers.filter(m => m != none and m != "")
  if ms.len() == 0 { return none }
  // 0.16 of the short side is right for a 100x80 activity, but an *expanded*
  // sub-process is a container, not a bigger task: its markers stay the size
  // bpmn-js draws them (14 units) instead of growing with the frame.
  let s = calc.min(w, h) * 0.16
  if unit != none { s = calc.min(s, 13 * unit) }
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
  // Weights follow bpmn-js on its 36-unit event box: start 2, end 4, and (the part
  // that is easy to get wrong) **1.5 for both rings of a double-ring event**, with
  // the inner circle 3 units smaller in radius (`INNER_OUTER_DIST`).
  //
  // Those three numbers are one system, not three independent knobs. Draw the double
  // ring at the single-ring weight (0.055 d) and the white gap works out to exactly
  // zero: centreline distance 0.11 r == 0.055 d, minus two half-strokes of 0.0275 d,
  // leaves nothing. The two rings touch and read as one thick ring, indistinguishable
  // from an end event, which is precisely the distinction the ring grammar carries.
  let thin = 0.055 * r * 2            // 2/36 , start
  let thick = 0.13 * r * 2            // end
  let double = 0.042 * r * 2          // 1.5/36, each ring of a double-ring event
  // bpmn-js puts the inner circle 3/18 r inside, which leaves 4,2% of the diameter
  // as white. That is enough on a modeller canvas at 100% zoom and not enough on an
  // A4 figure, where the whole event is a few millimetres: the gap closes up and the
  // double ring reads as one thick ring again, the same failure, just later.
  // Pulling the inner circle in to 0.22 r nearly doubles the white to 7,4% and buys
  // the distinction back. It stays clear of the icon, which occupies the middle
  // r x r box (corners at 0.71 r).
  let gap = 0.22 * r                  // inner radius = r - gap
  let doubled = family in ("intermediate", "boundary")
  let outer = if family == "end" { thick } else if doubled { double } else { thin }
  let ring = (
    place(circle(radius: r, fill: fill,
      stroke: (paint: stroke, thickness: outer, dash: dash))),
  )
  let inner = if doubled {
    (place(dx: gap, dy: gap, circle(radius: r - gap,
      stroke: (paint: stroke, thickness: double, dash: dash))),)
  } else { () }
  let ic = event-icon(definition, r, paint: stroke, filled: throw)
  canvas(w, h, ..ring, ..inner,
    if ic != none { place(dx: r - r / 2, dy: r - r / 2, ic) })
}

/// Activity: rounded rectangle, type marker top-left, behaviour markers bottom-centre.
/// A call activity gets the spec's thick border.
#let shape-task(w, h, kind: "none", markers: (), fill: white, stroke: black,
                radius: 10, unit: none) = {
  let m = calc.min(w, h) * 0.18
  let ic = task-icon(kind, m, paint: stroke)
  let sc = _scale(w, unit)
  let t = 1.6 * sc * (if kind == "call" { 2.8 } else { 1 })
  canvas(w, h,
    place(rect(width: w, height: h, fill: fill, stroke: t + stroke,
      radius: radius * sc)),
    if ic != none { place(dx: 0.06 * w, dy: 0.06 * w, ic) },
    marker-row(w, h, markers, paint: stroke, unit: unit))
}

/// Sub-process: a task frame plus the collapsed [+] and any behaviour markers.
/// `transaction` draws the spec's double border, `event-sub` the dashed one.
///
/// An *expanded* sub-process is the one shape in the vocabulary that is routinely
/// several hundred units wide, so `unit:` matters here more than anywhere else:
/// without it the frame's stroke, corner radius and markers all grow with the
/// frame and the container ends up drawn heavier than the tasks inside it. BPMN
/// gives a sub-process the *same* border as a task: it is a container, not an
/// emphasis.
#let shape-subprocess(w, h, expanded: false, event-sub: false, transaction: false,
                      markers: (), fill: white, stroke: black, unit: none) = {
  let sc = _scale(w, unit)
  let t = 1.6 * sc
  let r = 10 * sc
  let inner = if transaction {
    let d = 3 * sc
    (place(dx: d, dy: d, rect(width: w - 2 * d, height: h - 2 * d,
      stroke: t + stroke, radius: r * 0.8)),)
  } else { () }
  let ms = if expanded { markers } else { ("sub",) + markers }
  canvas(w, h,
    place(rect(width: w, height: h, fill: fill, radius: r,
      stroke: (paint: stroke, thickness: t,
               dash: if event-sub { "dashed" } else { none }))),
    ..inner,
    marker-row(w, h, ms, paint: stroke, unit: unit))
}

/// Gateway: diamond with the symbol for its kind.
///
/// The event-based gateway has three renderings, and BPMN distinguishes them by
/// `eventGatewayType` and `instantiate` rather than by element name:
///
///   exclusive, not instantiating  outer ring + inner ring + pentagon  (the common one)
///   exclusive, instantiating      outer ring + pentagon
///   parallel  (always instantiating)  outer ring + plus
///
/// Radii follow bpmn-js: the outer circle sits at 0.20 × height inset from the
/// shape, the inner at 0.26, which for a 50-unit gateway gives r = 15 and r = 12.
#let shape-gateway(w, h, kind: "exclusive", marker: true,
                   event-type: "exclusive", instantiate: false,
                   fill: white, stroke: black) = {
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
    let ring(r) = place(dx: 0.5 * s - r * s, dy: 0.5 * s - r * s,
      circle(radius: r * s, stroke: 0.026 * s + stroke))
    let pentagon = unit-path(s,
      ((0.50, 0.29), (0.70, 0.43), (0.62, 0.67), (0.38, 0.67), (0.30, 0.43)),
      close: true, stroke: 0.05 * s + stroke)
    let plus = (unit-path(s, ((0.5, 0.28), (0.5, 0.72)), stroke: 0.05 * s + stroke),
                unit-path(s, ((0.28, 0.5), (0.72, 0.5)), stroke: 0.05 * s + stroke))
    if event-type == "parallel" {
      (ring(0.30), ..plus)
    } else if instantiate {
      (ring(0.30), pentagon)
    } else {
      (ring(0.30), ring(0.24), pentagon)
    }
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
/// Group: the spec's dash-**dot** frame. Fill is `none`, a group marks a region,
/// it does not own it, so whatever it encloses stays visible through it.
///
/// The dash pattern is bpmn-js's `10,6,0,6` verbatim: a 10-long dash, a gap, a
/// *zero-length* dash, a gap. A zero-length dash under a round cap is a dot, which
/// is why `cap: "round"` is not cosmetic here; with a butt cap the dot vanishes
/// and the frame degrades to a plain dashed line, which in BPMN is the notation
/// for something else entirely.
#let shape-group(w, h, stroke: rgb("#666666"), unit: none) = {
  let sc = _scale(w, unit, nominal: 400)
  place(rect(width: w, height: h, radius: 10 * sc,
    stroke: (paint: stroke, thickness: 1.5 * sc, cap: "round",
             dash: (array: (10 * sc, 6 * sc, 0pt, 6 * sc), phase: 0pt))))
}

/// Text annotation: the open left bracket only.
#let shape-annotation(w, h, stroke: black) = {
  let t = 1pt * calc.max(0.4, h / 40pt)
  let arm = calc.min(0.22 * w, 0.18 * h)
  place(curve(stroke: t + stroke,
    curve.move((arm, 0pt)), curve.line((0pt, 0pt)),
    curve.line((0pt, h)), curve.line((arm, h))))
}
