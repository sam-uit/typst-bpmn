// Squeeze the empty bands out of a diagram without shrinking anything that
// carries information.
//
// Scaling a diagram to fit the page shrinks the labels along with it. Modeler
// layouts are usually generous with horizontal air — routing corridors, slack
// left over from dragging things around — and that air costs label size. This
// walks the diagram as if it were a grid, finds the columns (and optionally the
// rows) where nothing lives, and collapses each of them to `min-gap`.
//
// The transform is a monotonic piecewise-linear map on each axis, so geometry
// stays consistent: orthogonal edges stay orthogonal, nothing crosses that did
// not cross before, and shapes and labels keep their original size. Only the
// emptiness gets smaller.

#let compact-defaults = (
  axis: "x",        // "x" | "y" | "both"
  min-gap: 34,      // BPMN units of air to leave where a band is collapsed
  halo: 7,          // protected margin around a routing line, so parallel
                    // corridors stay visually distinct
  margin: 14,       // air kept at the outer edges
)

// --------------------------------------------------------------- intervals ---

#let _merge(ivs) = {
  if ivs.len() == 0 { return () }
  let s = ivs.sorted(key: i => i.at(0))
  let out = (s.first(),)
  for iv in s.slice(1) {
    let last = out.last()
    if iv.at(0) <= last.at(1) {
      out.at(out.len() - 1) = (last.at(0), calc.max(last.at(1), iv.at(1)))
    } else { out.push(iv) }
  }
  out
}

/// Everything that must keep its size on `axis`.
#let _occupancy(model, axis, halo, band) = {
  let lo(b) = if axis == "x" { b.x } else { b.y }
  let sz(b) = if axis == "x" { b.w } else { b.h }
  let ivs = ()

  // shapes, except frames — a group or pool rectangle spans the whole diagram
  // and would mark every band as occupied. The group's *title* is still real
  // text that needs its room, so that stays in.
  for n in model.nodes {
    if n.kind != "group" {
      ivs.push((lo(n.bounds), lo(n.bounds) + sz(n.bounds)))
    }
    if "label" in n and n.at("name", default: "") != "" {
      ivs.push((lo(n.label), lo(n.label) + sz(n.label)))
    }
  }
  for f in model.flows {
    if "label" in f { ivs.push((lo(f.label), lo(f.label) + sz(f.label))) }
    // a waypoint pins a routing corridor: protect a halo so two parallel
    // corridors in the same empty band do not collapse onto each other
    for w in f.waypoints {
      let v = if axis == "x" { w.at(0) } else { w.at(1) }
      ivs.push((v - halo, v + halo))
    }
  }
  // pool and lane title bands are drawn at a fixed size by the renderer
  for p in model.pools {
    let b = p.bounds
    if axis == "x" and p.at("horizontal", default: true) {
      ivs.push((b.x, b.x + band))
    } else if axis == "y" and not p.at("horizontal", default: true) {
      ivs.push((b.y, b.y + band))
    }
    for l in p.at("lanes", default: ()) {
      let lb = l.bounds
      if axis == "x" { ivs.push((lb.x, lb.x + band)) }
    }
    // A band whose only content is its own rotated title must keep its height —
    // squeeze it and the title runs out of the band and over its neighbours.
    //
    // The `blackbox` flag alone is not enough to find those: it is set by
    // `bpmn-slice`, so a model loaded whole (which is what `bpmn-sheet` does) has
    // no flag at all and its empty partner pools were being crushed — 60 units to
    // 19 on the promotion model. Ask the geometry instead: a band with no shape
    // centred inside it is empty, however it was loaded.
    let has-node(bb) = model.nodes.any(n => {
      let c = n.bounds.y + n.bounds.h / 2
      c > bb.y and c < bb.y + bb.h
    })
    if axis == "y" and p.at("horizontal", default: true) {
      if p.at("blackbox", default: false) or not has-node(b) { ivs.push((b.y, b.y + b.h)) }
      for l in p.at("lanes", default: ()) {
        if not has-node(l.bounds) { ivs.push((l.bounds.y, l.bounds.y + l.bounds.h)) }
      }
    }
  }
  _merge(ivs)
}

// ----------------------------------------------------------------- mapping ---

/// Build a monotonic piecewise-linear map from the occupied intervals.
/// Returns (breaks: ((from, to, scale-origin, target-origin), ...), span: length).
#let _build-map(occ, lo, hi, o) = {
  if occ.len() == 0 { return ((pieces: ((lo, hi, lo, 0.0),), span: hi - lo)) }
  // segments alternate: gap, occupied, gap, occupied, ..., gap
  let pieces = ()
  let cursor = lo
  let out = 0.0
  for iv in occ {
    let (a, b) = iv
    if a > cursor {
      // an empty band: collapse it, but never below what it already is
      let len = a - cursor
      let target = calc.min(len, if cursor == lo { o.margin } else { o.min-gap })
      pieces.push((cursor, a, out, target / len))
      out += target
    }
    pieces.push((a, b, out, 1.0))
    out += b - a
    cursor = b
  }
  if hi > cursor {
    let len = hi - cursor
    let target = calc.min(len, o.margin)
    pieces.push((cursor, hi, out, target / len))
    out += target
  }
  (pieces: pieces, span: out)
}

#let _apply(m, v) = {
  let first = m.pieces.first()
  if v <= first.at(0) { return first.at(2) + (v - first.at(0)) }
  for p in m.pieces {
    let (a, b, base, k) = p
    if v <= b { return base + (v - a) * k }
  }
  let last = m.pieces.last()
  last.at(2) + (last.at(1) - last.at(0)) * last.at(3) + (v - last.at(1))
}

// ------------------------------------------------------------------- entry ---

/// Collapse the empty bands of `model`. Options: axis, min-gap, halo, margin.
#let compact(model, opts: (:)) = {
  let o = compact-defaults
  for (k, v) in opts { o.insert(k, v) }
  if o.axis == none or o.axis == false { return model }

  let band = 30 // must match `_band` in bpmn-render.typ
  let e = model.meta.extent
  let axes = if o.axis == "both" { ("x", "y") } else { (o.axis,) }

  let m = model
  for ax in axes {
    let occ = _occupancy(m, ax, o.halo, band)
    let ex = m.meta.extent
    let (lo, hi) = if ax == "x" { (ex.x, ex.x + ex.w) } else { (ex.y, ex.y + ex.h) }
    // never let compaction reach outside the current extent
    let occ = occ.map(iv => (calc.max(iv.at(0), lo), calc.min(iv.at(1), hi)))
      .filter(iv => iv.at(1) > iv.at(0))
    let map = _build-map(occ, lo, hi, o)

    let mv(v) = _apply(map, v)
    let mb(b) = if ax == "x" {
      (x: mv(b.x), y: b.y, w: mv(b.x + b.w) - mv(b.x), h: b.h)
    } else {
      (x: b.x, y: mv(b.y), w: b.w, h: mv(b.y + b.h) - mv(b.y))
    }

    m.nodes = m.nodes.map(n => {
      let q = n
      q.bounds = mb(n.bounds)
      if "label" in n { q.label = mb(n.label) }
      q
    })
    m.pools = m.pools.map(p => {
      let q = p
      q.bounds = mb(p.bounds)
      if "lanes" in p { q.lanes = p.lanes.map(l => { let r = l; r.bounds = mb(l.bounds); r }) }
      q
    })
    m.flows = m.flows.map(f => {
      let q = f
      q.waypoints = f.waypoints.map(w => if ax == "x" { (mv(w.at(0)), w.at(1)) }
                                        else { (w.at(0), mv(w.at(1))) })
      if "label" in f { q.label = mb(f.label) }
      q
    })
    m.meta.extent = if ax == "x" {
      (x: 0.0, y: ex.y, w: map.span, h: ex.h)
    } else {
      (x: ex.x, y: 0.0, w: ex.w, h: map.span)
    }
  }
  m.meta.compacted = true
  m
}
