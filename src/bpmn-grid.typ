// Fallback layout for hand-written YAML that has no BPMNDI coordinates.
//
// You give each node a `row` and `col` (same idea as `bpmap`'s grid) and this
// assigns bounds, derives pool/lane frames, and routes the flows orthogonally.
// It is deliberately simple: no crossing minimisation, no label collision
// avoidance. For anything intricate, draw it in a modeler and convert the XML,
// the modeler is better at layout than a few hundred lines of Typst will ever be.

#let grid-defaults = (
  col: 150,      // column pitch, BPMN units
  row: 130,      // row pitch
  pad: 40,       // padding inside a pool
  band: 30,      // pool/lane title band
  task: (100, 80),
  event: (36, 36),
  gateway: (50, 50),
  data: (36, 50),
  annotation: (120, 50),
  label-gap: 6,
  label-w: 110,
  label-h: 28,
)

#let _size(n, g) = {
  let k = n.at("kind", default: "task")
  if k == "task" or k == "subprocess" { g.task }
  else if k == "event" { g.event }
  else if k == "gateway" { g.gateway }
  else if k == "data" { g.data }
  else { g.annotation }
}

#let _centre(n, g, x0, y0) = {
  let (w, h) = _size(n, g)
  let cx = x0 + (n.at("col", default: 1) - 0.5) * g.col
  let cy = y0 + (n.at("row", default: 1) - 0.5) * g.row
  (x: cx - w / 2, y: cy - h / 2, w: w, h: h)
}

// ------------------------------------------------------------------ ports ---
// A shape has four attachment points: right, bottom, left, top, which on a
// gateway diamond are exactly its four vertices. Every flow touching a node gets
// one of its own, so a gateway with two outgoing branches sends one out of the
// right vertex and the other out of the bottom vertex, the way a modeler would
// draw it. Without this, both branches leave the same pixel and their labels
// land on top of each other.

#let _PORTS = ("right", "bottom", "left", "top")

#let _port-point(b, port) = {
  if port == "right" { (b.x + b.w, b.y + b.h / 2) }
  else if port == "left" { (b.x, b.y + b.h / 2) }
  else if port == "bottom" { (b.x + b.w / 2, b.y + b.h) }
  else { (b.x + b.w / 2, b.y) }
}

#let _is-horiz(port) = port == "right" or port == "left"

/// Angular preference order for reaching (dx, dy) from a node centre.
#let _port-order(dx, dy) = {
  let score = (
    right: dx, left: -dx, bottom: dy, top: -dy,
  )
  _PORTS.sorted(key: p => -score.at(p))
}

/// Give every flow attached to `bounds` a distinct port. `wants` is a list of
/// (key, dx, dy); returns a dictionary key -> port.
#let _allocate(wants) = {
  // strongest preference first, so a dead-straight branch keeps the port it
  // deserves and the diagonal one gets bumped
  let ranked = wants.sorted(key: ((k, dx, dy)) => -calc.max(calc.abs(dx), calc.abs(dy))
    / calc.max(1, calc.min(calc.abs(dx), calc.abs(dy)) + 1))
  let taken = ()
  let out = (:)
  for (k, dx, dy) in ranked {
    let order = _port-order(dx, dy)
    let free = order.filter(p => not taken.contains(p))
    let pick = if free.len() > 0 { free.first() } else { order.first() }
    taken.push(pick)
    out.insert(k, pick)
  }
  out
}

/// Orthogonal path between two ports. Horizontal-to-horizontal goes through a
/// mid-x dogleg, vertical-to-vertical through a mid-y one, and a mixed pair
/// needs a single elbow.
#let _route-ports(a, ap, b, bp) = {
  let p = _port-point(a, ap)
  let q = _port-point(b, bp)
  let (ah, bh) = (_is-horiz(ap), _is-horiz(bp))
  if ah and bh {
    if calc.abs(p.at(1) - q.at(1)) < 2 { return (p, q) }
    let mx = (p.at(0) + q.at(0)) / 2
    (p, (mx, p.at(1)), (mx, q.at(1)), q)
  } else if not ah and not bh {
    if calc.abs(p.at(0) - q.at(0)) < 2 { return (p, q) }
    let my = (p.at(1) + q.at(1)) / 2
    (p, (p.at(0), my), (q.at(0), my), q)
  } else if ah {
    (p, (q.at(0), p.at(1)), q)
  } else {
    (p, (p.at(0), q.at(1)), q)
  }
}

/// Turn a coordinate-free model into one the renderer can draw.
#let grid-layout(model, opts: (:)) = {
  let g = grid-defaults
  for (k, v) in opts { g.insert(k, v) }
  for (k, v) in model.meta.at("grid", default: (:)) { g.insert(k, v) }

  // --- rows are grouped per pool, stacked in declaration order ---------------
  let pools-in = model.at("pools", default: ())
  let nodes-in = model.nodes

  // which pool does each node belong to (by id or name); "" = no pool
  let pool-of(n) = n.at("pool", default: "")
  let pool-key(p) = p.at("id", default: p.at("name", default: ""))

  let known = pools-in.map(p => (p.at("id", default: ""), p.at("name", default: "")))
  let pool-index(want) = {
    let i = 0
    let hit = -1
    for k in known {
      if k.contains(want) { hit = i }
      i += 1
    }
    hit
  }

  // rows used by each pool, so pools can be stacked without overlapping
  let rows-of(pi) = {
    let rs = nodes-in
      .filter(n => pool-index(pool-of(n)) == pi)
      .map(n => n.at("row", default: 1))
    if rs.len() == 0 { (1,) } else { rs }
  }

  let x0 = g.pad + g.band
  // vertical offset per pool
  let offsets = ()
  let acc = g.pad
  let i = 0
  for p in pools-in {
    let rs = rows-of(i)
    let span = calc.max(..rs) * g.row + 2 * g.pad
    offsets.push((y: acc, h: span))
    acc += span + g.pad
    i += 1
  }
  if pools-in.len() == 0 { offsets = ((y: g.pad, h: 0),) }

  // --- nodes ---------------------------------------------------------------
  let nodes = nodes-in.map(n => {
    let m = n
    let pi = pool-index(pool-of(n))
    let oy = if pi >= 0 { offsets.at(pi).y + g.pad } else { g.pad }
    if "bounds" not in m { m.bounds = _centre(n, g, x0, oy) }
    m
  })
  let by-id = (:)
  for n in nodes { by-id.insert(n.id, n) }

  // --- pools ---------------------------------------------------------------
  let width = if nodes.len() == 0 { g.col } else {
    calc.max(..nodes.map(n => n.bounds.x + n.bounds.w)) + g.pad - x0 + g.pad
  }
  let pools = ()
  let i = 0
  for p in pools-in {
    let o = offsets.at(i)
    let q = p
    q.id = pool-key(p)
    q.horizontal = true
    q.bounds = (x: g.pad, y: o.y, w: width + g.band, h: o.h)
    if "lanes" in p {
      // split the pool evenly between its lanes, in declaration order
      let lh = o.h / p.lanes.len()
      q.lanes = p.lanes.enumerate().map(((j, l)) => {
        let r = if type(l) == str { (name: l) } else { l }
        r.id = r.at("id", default: r.at("name", default: str(j)))
        r.bounds = (x: g.pad + g.band, y: o.y + j * lh, w: width, h: lh)
        r
      })
    }
    pools.push(q)
    i += 1
  }

  // --- flows ---------------------------------------------------------------
  let flows-in = model.at("flows", default: ()).enumerate().map(((i, f)) => {
    let m = f
    m.kind = f.at("kind", default: "sequence")
    if "id" not in m { m.id = f.source + "->" + f.target + "#" + str(i) }
    m
  })

  let centre(id) = {
    let n = by-id.at(id, default: none)
    if n == none {
      panic("bpmn grid: flow references unknown node '" + id + "'")
    }
    (n.bounds.x + n.bounds.w / 2, n.bounds.y + n.bounds.h / 2)
  }

  // one port per attached flow, allocated per node
  let ports = (:)
  for n in nodes {
    let c = (n.bounds.x + n.bounds.w / 2, n.bounds.y + n.bounds.h / 2)
    let wants = ()
    for f in flows-in {
      if "waypoints" in f and f.waypoints.len() >= 2 { continue }
      if f.source == n.id {
        let o = centre(f.target)
        wants.push((f.id + "|out", o.at(0) - c.at(0), o.at(1) - c.at(1)))
      } else if f.target == n.id {
        let o = centre(f.source)
        wants.push((f.id + "|in", o.at(0) - c.at(0), o.at(1) - c.at(1)))
      }
    }
    if wants.len() == 0 { continue }
    for (k, p) in _allocate(wants) { ports.insert(k, p) }
  }

  // External labels go on a side no flow is using, otherwise a gateway's name
  // ends up sitting on top of its own outgoing branch.
  let used-sides = (:)
  for n in nodes {
    let sides = ()
    for f in flows-in {
      if f.source == n.id { sides.push(ports.at(f.id + "|out", default: "right")) }
      if f.target == n.id { sides.push(ports.at(f.id + "|in", default: "left")) }
    }
    used-sides.insert(n.id, sides)
  }
  let nodes = nodes.map(n => {
    if n.kind not in ("event", "gateway", "data") { return n }
    if n.at("name", default: "") == "" or "label" in n { return n }
    let b = n.bounds
    let used = used-sides.at(n.id, default: ())
    let side = ("bottom", "top", "right", "left").find(s => not used.contains(s))
    let m = n
    m.label = if side == "top" {
      (x: b.x + b.w / 2 - g.label-w / 2, y: b.y - g.label-h - g.label-gap,
       w: g.label-w, h: g.label-h)
    } else if side == "right" {
      (x: b.x + b.w + g.label-gap, y: b.y + b.h / 2 - g.label-h / 2,
       w: g.label-w, h: g.label-h)
    } else if side == "left" {
      (x: b.x - g.label-w - g.label-gap, y: b.y + b.h / 2 - g.label-h / 2,
       w: g.label-w, h: g.label-h)
    } else {
      (x: b.x + b.w / 2 - g.label-w / 2, y: b.y + b.h + g.label-gap,
       w: g.label-w, h: g.label-h)
    }
    m
  })

  let flows = flows-in.map(f => {
    let m = f
    if "waypoints" not in m or m.waypoints.len() < 2 {
      let a = by-id.at(f.source)
      let b = by-id.at(f.target)
      let ap = ports.at(f.id + "|out", default: "right")
      let bp = ports.at(f.id + "|in", default: "left")
      m.waypoints = _route-ports(a.bounds, ap, b.bounds, bp).map(p => (p.at(0), p.at(1)))
    }
    // Anchor the label to the *source* end, the way a modeler labels a gateway
    // branch, rather than to the path midpoint where two branches would collide.
    if m.at("name", default: "") != "" and "label" not in m {
      let (p0, p1) = (m.waypoints.at(0), m.waypoints.at(1))
      let (dx, dy) = (p1.at(0) - p0.at(0), p1.at(1) - p0.at(1))
      let len = calc.max(1, calc.sqrt(dx * dx + dy * dy))
      let t = calc.min(0.5, 26 / len)
      let (ax, ay) = (p0.at(0) + dx * t, p0.at(1) + dy * t)
      m.label = if calc.abs(dy) < calc.abs(dx) {
        (x: ax - g.label-w / 2, y: ay - g.label-h - 4, w: g.label-w, h: g.label-h)
      } else {
        (x: ax + 6, y: ay - g.label-h / 2, w: g.label-w, h: g.label-h)
      }
    }
    m
  })

  // --- extent --------------------------------------------------------------
  let boxes = pools.map(p => p.bounds) + nodes.map(n => n.bounds)
  boxes += nodes.filter(n => "label" in n).map(n => n.label)
  boxes += flows.filter(f => "label" in f).map(f => f.label)
  let xs = boxes.map(b => (b.x, b.x + b.w)).flatten()
  let ys = boxes.map(b => (b.y, b.y + b.h)).flatten()
  xs += flows.map(f => f.waypoints.map(w => w.at(0))).flatten()
  ys += flows.map(f => f.waypoints.map(w => w.at(1))).flatten()
  let pad = 12

  let m = model
  m.pools = pools
  m.nodes = nodes
  m.flows = flows
  m.meta.extent = (
    x: calc.min(..xs) - pad, y: calc.min(..ys) - pad,
    w: calc.max(..xs) - calc.min(..xs) + 2 * pad,
    h: calc.max(..ys) - calc.min(..ys) + 2 * pad,
  )
  m.meta.layout = "grid"
  m
}
