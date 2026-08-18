// Render a parsed BPMN model onto an absolutely-positioned canvas.
//
// Everything is expressed in BPMN diagram units (1 unit == 1 px in the modeler)
// and multiplied by `u`, the length-per-unit, at draw time. That keeps the whole
// file scale-independent: change `u` and the diagram scales, strokes and all.

#import "bpmn-shapes.typ": *
#import "bptext.typ": bp-text
#import "bpmn-palette.typ": camunda-palette, mono-palette, swatch

// ------------------------------------------------------------------ theme ---

#let default-theme = (
  font: "DejaVu Sans",
  // Nhãn lấy từ mô hình đi qua chế độ nào — xem bptext.typ.
  //   "smart"  (mặc định) đổi `--`/`---`/`...` thành ký hiệu đúng, không eval
  //   "markup" eval đầy đủ: được cả `$->$`, nhưng `#` sẽ biến mất im lặng
  //   "raw"    giữ nguyên
  markup: "smart",
  // Camunda Modeler's own default stroke is rgb(34, 36, 42), not pure black.
  stroke: rgb("#22242A"),
  fill: rgb("#FFFFFF"),
  palette: camunda-palette,
  pool-stroke: rgb("#22242A"),
  pool-fill: none,
  pool-band: rgb("#f8f8f8"),
  blackbox-fill: rgb("#f4f4f4"),
  lane-stroke: rgb("#22242A"),
  group-stroke: rgb("#666666"),
  label: rgb("#22242A"),
  font-size: 11, // BPMN units
  label-leading: 0.32,
  honor-colors: true, // use bioc:/color: extensions from the model
)

#let grayscale-theme = (default-theme + (honor-colors: false, palette: mono-palette))

// ---------------------------------------------------------------- helpers ---

#let _col(v, fallback) = if v == none or v == "" { fallback } else { rgb(v) }

/// Colour precedence: explicit `fill:`/`stroke:` hex, then a named `color:`
/// swatch, then the theme default. `honor-colors: false` collapses all of it.
#let _node-colors(n, theme) = {
  if not theme.honor-colors { return (fill: theme.fill, stroke: theme.stroke) }
  let base = (fill: theme.fill, stroke: theme.stroke)
  let named = n.at("color", default: none)
  if named != none {
    let sw = swatch(named, palette: theme.at("palette", default: camunda-palette))
    if sw != none { base = sw }
  }
  (fill: _col(n.at("fill", default: none), base.fill),
   stroke: _col(n.at("stroke", default: none), base.stroke))
}

/// Text block placed at absolute DI label bounds.
#let _label(lb, body, u, theme, paint: none, size: none, align-x: center) = {
  if body == none or body == "" { return none }
  // Nhãn ở đây do người khác gõ trong Camunda Modeler, cho một công cụ khác. Mặc
  // định "smart": được en-dash và em-dash, không có `#` biến mất im lặng. Muốn cả
  // math thì `theme + (markup: "markup")`.
  let body = bp-text(body, mode: theme.at("markup", default: "smart"))
  let fs = (if size == none { theme.font-size } else { size }) * u
  place(dx: lb.x * u, dy: lb.y * u,
    box(width: lb.w * u,
      align(align-x + top,
        text(size: fs, fill: if paint == none { theme.label } else { paint },
          par(leading: theme.label-leading * fs, justify: false, body)))))
}

/// Place a label inside a shape's own bounds. Centred by default; `anchor:` moves
/// it, which is how an expanded sub-process gets its name at the top of the frame
/// instead of across the middle of its own children.
#let _inner-label(b, body, u, theme, paint: none, size: none, pad: 6, pad-y: 0,
                  anchor: center + horizon) = {
  if body == none or body == "" { return none }
  let body = bp-text(body, mode: theme.at("markup", default: "smart"))
  let fs = (if size == none { theme.font-size } else { size }) * u
  place(dx: (b.x + pad) * u, dy: (b.y + pad-y) * u,
    box(width: (b.w - 2 * pad) * u, height: (b.h - 2 * pad-y) * u,
      align(anchor,
        text(size: fs, fill: if paint == none { theme.label } else { paint },
          par(leading: theme.label-leading * fs, justify: false, body)))))
}

// ------------------------------------------------------------------ edges ---

#let _norm(dx, dy) = {
  let m = calc.sqrt(dx * dx + dy * dy)
  if m == 0 { (0.0, 0.0) } else { (dx / m, dy / m) }
}

/// Arrowhead at `p` pointing along `dir`. `open` draws it unfilled (message flow).
#let _arrow(p, dir, u, paint, open: false, size: 10) = {
  let (dx, dy) = dir
  let (px, py) = (-dy, dx) // perpendicular
  let (l, w) = (size, size * 0.42)
  let tip = (p.at(0) * u, p.at(1) * u)
  let base = (p.at(0) - dx * l, p.at(1) - dy * l)
  let a = ((base.at(0) + px * w) * u, (base.at(1) + py * w) * u)
  let b = ((base.at(0) - px * w) * u, (base.at(1) - py * w) * u)
  place(curve(
    fill: if open { white } else { paint },
    stroke: (paint: paint, thickness: 0.1 * size * u, join: "miter"),
    curve.move(tip), curve.line(a), curve.line(b), curve.close()))
}

/// Small hollow circle at the start of a message flow.
#let _msg-start(p, u, paint, size: 5) = place(
  dx: (p.at(0) - size) * u, dy: (p.at(1) - size) * u,
  circle(radius: size * u, fill: white, stroke: 0.1 * size * u + paint))

/// Rounded-corner polyline through `pts` (list of (x, y) in units).
#let _polyline(pts, u, paint, dash: none, thickness: 1.4, radius: 6) = {
  if pts.len() < 2 { return none }
  let segs = (curve.move((pts.first().at(0) * u, pts.first().at(1) * u)),)
  for i in range(1, pts.len() - 1) {
    let (p0, p1, p2) = (pts.at(i - 1), pts.at(i), pts.at(i + 1))
    let (i0x, i0y) = _norm(p0.at(0) - p1.at(0), p0.at(1) - p1.at(1))
    let (i2x, i2y) = _norm(p2.at(0) - p1.at(0), p2.at(1) - p1.at(1))
    let d0 = calc.sqrt(calc.pow(p0.at(0) - p1.at(0), 2) + calc.pow(p0.at(1) - p1.at(1), 2))
    let d2 = calc.sqrt(calc.pow(p2.at(0) - p1.at(0), 2) + calc.pow(p2.at(1) - p1.at(1), 2))
    let r = calc.min(radius, d0 / 2, d2 / 2)
    let a = ((p1.at(0) + i0x * r) * u, (p1.at(1) + i0y * r) * u)
    let b = ((p1.at(0) + i2x * r) * u, (p1.at(1) + i2y * r) * u)
    segs.push(curve.line(a))
    segs.push(curve.quad((p1.at(0) * u, p1.at(1) * u), b))
  }
  segs.push(curve.line((pts.last().at(0) * u, pts.last().at(1) * u)))
  place(curve(stroke: (paint: paint, thickness: thickness * u, dash: dash,
    cap: "round", join: "round"), ..segs))
}

/// The little slash marking a gateway's default flow.
#let _default-slash(pts, u, paint) = {
  let (p0, p1) = (pts.at(0), pts.at(1))
  let (dx, dy) = _norm(p1.at(0) - p0.at(0), p1.at(1) - p0.at(1))
  let c = (p0.at(0) + dx * 16, p0.at(1) + dy * 16)
  // a short stroke at ~45 degrees to the flow direction
  let (ax, ay) = (dx * 0.7071 - dy * 0.7071, dx * 0.7071 + dy * 0.7071)
  place(curve(stroke: 1.4 * u + paint,
    curve.move(((c.at(0) - ax * 6) * u, (c.at(1) - ay * 6) * u)),
    curve.line(((c.at(0) + ax * 6) * u, (c.at(1) + ay * 6) * u))))
}

/// The hollow diamond a conditional sequence flow carries at its source.
#let _condition-diamond(pts, u, paint) = {
  let (p0, p1) = (pts.at(0), pts.at(1))
  let (dx, dy) = _norm(p1.at(0) - p0.at(0), p1.at(1) - p0.at(1))
  let (px, py) = (-dy, dx)
  let (l, w) = (9, 5)
  let pt(a, b) = ((p0.at(0) + dx * a + px * b) * u, (p0.at(1) + dy * a + py * b) * u)
  place(curve(fill: white, stroke: 1.2 * u + paint,
    curve.move(pt(0, 0)), curve.line(pt(l, w)), curve.line(pt(2 * l, 0)),
    curve.line(pt(l, -w)), curve.close()))
}

#let draw-flow(f, u, theme) = {
  let pts = f.waypoints
  if pts.len() < 2 { return none }
  let kind = f.at("kind", default: "sequence")
  let paint = if not theme.honor-colors { theme.stroke } else {
    let named = f.at("color", default: none)
    let base = if named == none { theme.stroke } else {
      swatch(named, palette: theme.at("palette", default: camunda-palette)).stroke
    }
    _col(f.at("stroke", default: none), base)
  }

  let dash = if kind == "message" { "dashed" }
    else if kind in ("association", "data") { "dotted" }
    else { none }
  let thickness = if kind == "sequence" { 1.6 } else { 1.3 }

  let last = pts.last()
  let prev = pts.at(pts.len() - 2)
  let dir = _norm(last.at(0) - prev.at(0), last.at(1) - prev.at(1))

  // stop the line short of the arrow tip so the stroke does not poke through
  let head = if kind == "sequence" { 9 } else if kind == "message" { 9 } else { 0 }
  let trimmed = pts
  if head > 0 {
    trimmed = pts.slice(0, pts.len() - 1)
    trimmed.push((last.at(0) - dir.at(0) * head * 0.8, last.at(1) - dir.at(1) * head * 0.8))
  }

  _polyline(trimmed, u, paint, dash: dash, thickness: thickness)

  if kind == "sequence" { _arrow(last, dir, u, paint) }
  if kind == "message" {
    _arrow(last, dir, u, paint, open: true)
    _msg-start(pts.first(), u, paint)
  }
  if kind in ("association", "data") and f.at("direction", default: "none") != "none" {
    _arrow(last, dir, u, paint, open: true, size: 8)
  }
  if f.at("default", default: false) { _default-slash(pts, u, paint) }
  if f.at("conditional", default: false) { _condition-diamond(pts, u, paint) }

  if "label" in f and f.at("name", default: "") != "" {
    _label(f.label, f.name, u, theme, paint: paint, size: theme.font-size * 0.92)
  }
}

// ------------------------------------------------------------------ nodes ---

#let draw-node(n, u, theme) = {
  let b = n.bounds
  let c = _node-colors(n, theme)
  let kind = n.kind

  if kind == "group" {
    // A group is grey *unless the author coloured it*. Everywhere else the theme
    // is the fallback and the model wins; a group had the theme hard-wired, so a
    // deliberate colour chosen in the modeler was silently thrown away — and a
    // group is one of the few elements whose only job is to say "these belong
    // together", which is exactly what people reach for colour to say.
    let painted = (n.at("stroke", default: none) != none
      or n.at("color", default: none) != none)
    let gs = if theme.honor-colors and painted { c.stroke } else { theme.group-stroke }
    place(dx: b.x * u, dy: b.y * u,
      shape-group(b.w * u, b.h * u, stroke: gs, unit: u))
    if n.at("name", default: "") != "" {
      // Ignore the DI label bounds here: modelers size them to the rendered
      // string, which forces a wrap as soon as the font differs. A group title
      // has the whole width of the group to sit in.
      let y = if "label" in n { n.label.y } else { b.y + 6 }
      _label((x: b.x, y: y, w: b.w, h: 20), n.name, u, theme, paint: gs)
    }
    return
  }

  if kind == "annotation" {
    place(dx: b.x * u, dy: b.y * u, shape-annotation(b.w * u, b.h * u, stroke: c.stroke))
    place(dx: (b.x + 7) * u, dy: (b.y + 3) * u,
      box(width: (b.w - 10) * u, height: (b.h - 6) * u,
        align(left + horizon, text(size: theme.font-size * u, fill: c.stroke,
          par(leading: theme.label-leading * theme.font-size * u,
            n.at("text", default: ""))))))
    return
  }

  let shape = if kind == "event" {
    shape-event(b.w * u, b.h * u,
      family: n.at("event", default: "start"),
      definition: n.at("definition", default: "none"),
      throw: n.at("throw", default: false),
      interrupting: n.at("interrupting", default: true),
      fill: c.fill, stroke: c.stroke)
  } else if kind == "task" {
    shape-task(b.w * u, b.h * u, kind: n.at("task", default: "none"),
      markers: n.at("markers", default: ()), fill: c.fill, stroke: c.stroke,
      unit: u)
  } else if kind == "subprocess" {
    shape-subprocess(b.w * u, b.h * u,
      expanded: n.at("expanded", default: false),
      event-sub: n.at("triggered-by-event", default: false),
      transaction: n.at("transaction", default: false),
      markers: n.at("markers", default: ()),
      fill: c.fill, stroke: c.stroke, unit: u)
  } else if kind == "gateway" {
    shape-gateway(b.w * u, b.h * u, kind: n.at("gateway", default: "exclusive"),
      marker: n.at("marker", default: true),
      event-type: n.at("event-type", default: "exclusive"),
      instantiate: n.at("instantiate", default: false),
      fill: c.fill, stroke: c.stroke)
  } else if kind == "data" {
    shape-data(b.w * u, b.h * u, kind: n.at("data", default: "object"),
      collection: n.at("collection", default: false),
      direction: n.at("direction", default: none),
      fill: c.fill, stroke: c.stroke)
  } else { none }

  if shape != none { place(dx: b.x * u, dy: b.y * u, shape) }

  // labels: inside activities, outside everything else
  let name = n.at("name", default: "")
  if name != "" {
    if kind in ("task", "subprocess") {
      // An expanded sub-process's body belongs to its children, so its own name
      // goes at the top of the frame (bpmn-js: `center-top`). A collapsed one is
      // read as a single activity, so it keeps the task's centred name.
      if kind == "subprocess" and n.at("expanded", default: false) {
        _inner-label(b, name, u, theme, paint: c.stroke,
          pad-y: 5, anchor: center + top)
      } else {
        _inner-label(b, name, u, theme, paint: c.stroke)
      }
    } else if "label" in n {
      _label(n.label, name, u, theme, paint: c.stroke)
    } else {
      // no DI label bounds: park it under the shape
      _label((x: b.x - 30, y: b.y + b.h + 4, w: b.w + 60, h: 20), name, u, theme, paint: c.stroke)
    }
  }
}

// ------------------------------------------------------------------ pools ---

#let _band = 30 // pool/lane title band width in BPMN units

#let draw-pool(p, u, theme) = {
  let b = p.bounds
  let horiz = p.at("horizontal", default: true)
  let stroke = if theme.honor-colors {
    _col(p.at("stroke", default: none), theme.pool-stroke)
  } else { theme.pool-stroke }

  // A collapsed participant: no lanes, no title band, name centred in the box.
  // This is what is left of a partner whose internals the current view hides.
  if p.at("blackbox", default: false) {
    place(dx: b.x * u, dy: b.y * u,
      rect(width: b.w * u, height: b.h * u, fill: theme.blackbox-fill,
        stroke: 1.6 * u + stroke))
    let name = p.at("name", default: "")
    if name != "" {
      // a collapsed participant beside a vertical pool is a tall, thin strip;
      // its name only fits turned
      let turned = b.h > b.w
      let inner = box(width: (if turned { b.h } else { b.w }) * u,
        align(center, text(size: theme.font-size * 1.05 * u, fill: theme.label, name)))
      place(dx: b.x * u, dy: b.y * u,
        box(width: b.w * u, height: b.h * u, align(center + horizon,
          if turned { rotate(-90deg, reflow: false, inner) } else { inner })))
    }
    return
  }

  place(dx: b.x * u, dy: b.y * u,
    rect(width: b.w * u, height: b.h * u, fill: theme.pool-fill, stroke: 1.6 * u + stroke))

  // A title band runs down the left of a horizontal pool and across the top of a
  // vertical one, with the text turned to match. Lanes follow the same rule: they
  // stack downwards in a horizontal pool and sit side by side in a vertical one,
  // so their bands and their text turn with the pool.
  // `rule` — draw the line that closes the band off from the body of the pool.
  //
  // A participant has one: the modeler boxes its name off. A lane does not, and adding
  // it is not a small liberty — it reads as a table header row, which invites the eye
  // to look for columns that are not there. The name already sits turned on its side
  // against the frame; nothing more is needed to tell it apart from the shapes. This
  // matches what bpmn-js draws, which is the whole promise of the renderer.
  let band(bb, label, size, thickness, fill, rule: true) = {
    let (bw, bh) = if horiz { (_band * u, bb.h * u) } else { (bb.w * u, _band * u) }
    if rule or fill != none {
      place(dx: bb.x * u, dy: bb.y * u, rect(
        width: bw, height: bh, fill: fill,
        stroke: if rule { thickness * u + stroke } else { none },
      ))
    }
    if label == "" { return }
    let inner = box(width: if horiz { bb.h * u } else { bb.w * u },
      align(center, text(size: size * u, fill: theme.label, label)))
    place(dx: bb.x * u, dy: bb.y * u,
      box(width: bw, height: bh, align(center + horizon,
        if horiz { rotate(-90deg, reflow: false, inner) } else { inner })))
  }

  band(b, p.at("name", default: ""), theme.font-size, 1.6, theme.pool-band)

  for l in p.at("lanes", default: ()) {
    let lb = l.bounds
    place(dx: lb.x * u, dy: lb.y * u,
      rect(width: lb.w * u, height: lb.h * u, fill: none, stroke: 1.2 * u + stroke))
    band(lb, l.at("name", default: ""), theme.font-size * 0.95, 1.2, none, rule: false)
  }
}

// ----------------------------------------------------------------- canvas ---

/// Draw the whole model into a block of exactly (extent.w * u, extent.h * u).
#let draw-canvas(model, u, theme) = {
  let e = model.meta.extent
  // shift so that extent origin maps to (0, 0)
  let sx = -e.x
  let sy = -e.y
  let shift-b(b) = (x: b.x + sx, y: b.y + sy, w: b.w, h: b.h)
  let shift-node(n) = {
    let m = n
    m.bounds = shift-b(n.bounds)
    if "label" in n { m.label = shift-b(n.label) }
    m
  }
  let shift-flow(f) = {
    let m = f
    m.waypoints = f.waypoints.map(((x, y)) => (x + sx, y + sy))
    if "label" in f { m.label = shift-b(f.label) }
    m
  }
  let shift-pool(p) = {
    let m = p
    m.bounds = shift-b(p.bounds)
    if "lanes" in p {
      m.lanes = p.lanes.map(l => { let q = l; q.bounds = shift-b(l.bounds); q })
    }
    m
  }

  // Z-order, bottom to top. Typst has no z-index, so the draw order *is* the
  // stacking, and it has to be stated once here rather than emerging from the
  // order the parser happened to return things in.
  //
  //   1  pools and lanes            the sheet everything else sits on
  //   2  expanded sub-processes     containers: opaque, and wide enough to hide
  //                                 anything crossing them, so they go early
  //   3  sequence flows             they live inside one pool, with its nodes
  //   4  activities, events, gateways
  //   5  data objects, annotations, groups
  //   6  message and (data) association flows
  //
  // The two that matter, and that the old order got wrong: a message flow is a
  // *conversation between pools*, so it has to stay legible wherever it passes —
  // it was being buried under sub-process frames. And a sub-process is scenery
  // for its own children, so it belongs below them, not above the flows.
  let is-frame(n) = n.kind == "subprocess" and n.at("expanded", default: false)
  let is-over(n) = n.kind in ("group", "annotation", "data")
  let over-flow(f) = f.at("kind", default: "sequence") in ("message", "association", "data")

  set text(font: theme.font, hyphenate: false)
  block(width: e.w * u, height: e.h * u, breakable: false, {
    for p in model.pools { draw-pool(shift-pool(p), u, theme) }
    for n in model.nodes.filter(is-frame) { draw-node(shift-node(n), u, theme) }
    for f in model.flows.filter(f => not over-flow(f)) { draw-flow(shift-flow(f), u, theme) }
    for n in model.nodes.filter(n => not is-frame(n) and not is-over(n)) {
      draw-node(shift-node(n), u, theme)
    }
    for n in model.nodes.filter(is-over) { draw-node(shift-node(n), u, theme) }
    for f in model.flows.filter(over-flow) { draw-flow(shift-flow(f), u, theme) }
  })
}
