// Render a parsed BPMN model onto an absolutely-positioned canvas.
//
// Everything is expressed in BPMN diagram units (1 unit == 1 px in the modeler)
// and multiplied by `u`, the length-per-unit, at draw time. That keeps the whole
// file scale-independent: change `u` and the diagram scales, strokes and all.

#import "bpmn-shapes.typ": *

// ------------------------------------------------------------------ theme ---

#let default-theme = (
  font: "DejaVu Sans",
  stroke: rgb("#000000"),
  fill: rgb("#ffffff"),
  pool-stroke: rgb("#000000"),
  pool-fill: none,
  pool-band: rgb("#f8f8f8"),
  blackbox-fill: rgb("#f4f4f4"),
  lane-stroke: rgb("#000000"),
  group-stroke: rgb("#666666"),
  label: rgb("#000000"),
  font-size: 11, // BPMN units
  label-leading: 0.32,
  honor-colors: true, // use bioc:/color: extensions from the model
)

#let grayscale-theme = (default-theme + (honor-colors: false))

// ---------------------------------------------------------------- helpers ---

#let _col(v, fallback) = if v == none or v == "" { fallback } else { rgb(v) }

#let _node-colors(n, theme) = {
  if not theme.honor-colors { return (fill: theme.fill, stroke: theme.stroke) }
  (fill: _col(n.at("fill", default: none), theme.fill),
   stroke: _col(n.at("stroke", default: none), theme.stroke))
}

/// Text block placed at absolute DI label bounds.
#let _label(lb, body, u, theme, paint: none, size: none, align-x: center) = {
  if body == none or body == "" { return none }
  let fs = (if size == none { theme.font-size } else { size }) * u
  place(dx: lb.x * u, dy: lb.y * u,
    box(width: lb.w * u,
      align(align-x + top,
        text(size: fs, fill: if paint == none { theme.label } else { paint },
          par(leading: theme.label-leading * fs, justify: false, body)))))
}

/// Centre a label inside a shape's own bounds.
#let _inner-label(b, body, u, theme, paint: none, size: none, pad: 6) = {
  if body == none or body == "" { return none }
  let fs = (if size == none { theme.font-size } else { size }) * u
  place(dx: (b.x + pad) * u, dy: b.y * u,
    box(width: (b.w - 2 * pad) * u, height: b.h * u,
      align(center + horizon,
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

#let draw-flow(f, u, theme) = {
  let pts = f.waypoints
  if pts.len() < 2 { return none }
  let kind = f.at("kind", default: "sequence")
  let paint = if theme.honor-colors {
    _col(f.at("stroke", default: none), theme.stroke)
  } else { theme.stroke }

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
    place(dx: b.x * u, dy: b.y * u, shape-group(b.w * u, b.h * u, stroke: theme.group-stroke))
    if n.at("name", default: "") != "" {
      // Ignore the DI label bounds here: modelers size them to the rendered
      // string, which forces a wrap as soon as the font differs. A group title
      // has the whole width of the group to sit in.
      let y = if "label" in n { n.label.y } else { b.y + 6 }
      _label((x: b.x, y: y, w: b.w, h: 20), n.name, u, theme, paint: theme.label)
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
      fill: c.fill, stroke: c.stroke)
  } else if kind == "subprocess" {
    shape-subprocess(b.w * u, b.h * u,
      expanded: n.at("expanded", default: false),
      event-sub: n.at("triggered-by-event", default: false),
      fill: c.fill, stroke: c.stroke)
  } else if kind == "gateway" {
    shape-gateway(b.w * u, b.h * u, kind: n.at("gateway", default: "exclusive"),
      marker: n.at("marker", default: true), fill: c.fill, stroke: c.stroke)
  } else if kind == "data" {
    shape-data(b.w * u, b.h * u, kind: n.at("data", default: "object"),
      fill: c.fill, stroke: c.stroke)
  } else { none }

  if shape != none { place(dx: b.x * u, dy: b.y * u, shape) }

  // labels: inside activities, outside everything else
  let name = n.at("name", default: "")
  if name != "" {
    if kind in ("task", "subprocess") {
      _inner-label(b, name, u, theme, paint: c.stroke)
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
      place(dx: b.x * u, dy: b.y * u,
        box(width: b.w * u, height: b.h * u, align(center + horizon,
          text(size: theme.font-size * 1.05 * u, fill: theme.label, name))))
    }
    return
  }

  place(dx: b.x * u, dy: b.y * u,
    rect(width: b.w * u, height: b.h * u, fill: theme.pool-fill, stroke: 1.6 * u + stroke))

  let name = p.at("name", default: "")
  if horiz {
    place(dx: b.x * u, dy: b.y * u,
      rect(width: _band * u, height: b.h * u, fill: theme.pool-band, stroke: 1.6 * u + stroke))
    if name != "" {
      place(dx: b.x * u, dy: b.y * u,
        box(width: _band * u, height: b.h * u, align(center + horizon,
          rotate(-90deg, reflow: false,
            box(width: b.h * u, align(center,
              text(size: theme.font-size * u, fill: theme.label, name)))))))
    }
  } else {
    place(dx: b.x * u, dy: b.y * u,
      rect(width: b.w * u, height: _band * u, fill: theme.pool-band, stroke: 1.6 * u + stroke))
    if name != "" {
      place(dx: b.x * u, dy: b.y * u,
        box(width: b.w * u, height: _band * u, align(center + horizon,
          text(size: theme.font-size * u, fill: theme.label, name))))
    }
  }

  for l in p.at("lanes", default: ()) {
    let lb = l.bounds
    place(dx: lb.x * u, dy: lb.y * u,
      rect(width: lb.w * u, height: lb.h * u, fill: none, stroke: 1.2 * u + stroke))
    place(dx: lb.x * u, dy: lb.y * u,
      rect(width: _band * u, height: lb.h * u, fill: none, stroke: 1.2 * u + stroke))
    let ln = l.at("name", default: "")
    if ln != "" {
      place(dx: lb.x * u, dy: lb.y * u,
        box(width: _band * u, height: lb.h * u, align(center + horizon,
          rotate(-90deg, reflow: false,
            box(width: lb.h * u, align(center,
              text(size: theme.font-size * 0.95 * u, fill: theme.label, ln)))))))
    }
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

  set text(font: theme.font, hyphenate: false)
  block(width: e.w * u, height: e.h * u, breakable: false, {
    for n in model.nodes.filter(n => n.kind == "group") { draw-node(shift-node(n), u, theme) }
    for p in model.pools { draw-pool(shift-pool(p), u, theme) }
    for f in model.flows { draw-flow(shift-flow(f), u, theme) }
    for n in model.nodes.filter(n => n.kind != "group") { draw-node(shift-node(n), u, theme) }
  })
}
