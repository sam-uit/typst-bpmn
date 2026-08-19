// Public API for BPMN diagrams in Typst.
//
//   #import "/src/bpmn.typ": *
//
//   #bpmn-figure(yaml("models/admission.yaml"), caption: [Admission process])
//   #bpmn-figure(xml("models/admission.bpmn"))                  // no build step
//   #bpmn-figure(m, view: (pool: "Thí Sinh"), caption: [...])   // one pool only
//
// Sizing is decided at layout time: the diagram is scaled to the container
// width, and if that would make labels illegible it is rotated a quarter turn
// instead. Neither ever helps a genuinely dense model — use `view:` to cut the
// model down instead, the same way `bpmap`'s `only:` works.

#import "bpmn-render.typ": draw-canvas, default-theme, grayscale-theme
#import "bpmn-xml.typ": bpmn-from-xml
#import "bpmn-grid.typ": grid-layout, grid-defaults
#import "bpmn-compact.typ": compact, compact-defaults
#import "bpmn-palette.typ": camunda-palette, outline-palette, mono-palette, swatch, swatch-names

// --------------------------------------------------------------- loading ---

/// Accept an already-parsed model, `yaml(..)` output, or `xml(..)` output.
///
/// Models converted from a modeler carry `meta.layout: di` and absolute bounds.
/// Hand-written YAML normally has neither, in which case the grid layout fills
/// them in from each node's `row`/`col`.
#let bpmn-model(src) = {
  let m = if type(src) == array { bpmn-from-xml(src) }
    else if type(src) == dictionary and "meta" in src and "nodes" in src { src }
    else if type(src) == dictionary and "tag" in src { bpmn-from-xml(src) }
    else { panic("bpmn: expected a model dictionary, yaml() output, or xml() output") }

  // A plain process with no collaboration has no participants at all, and the
  // YAML writer omits empty sections. Normalise so nothing downstream has to
  // guard for a missing key.
  for k in ("pools", "nodes", "flows") {
    if k not in m { m.insert(k, ()) }
  }

  let needs-layout = (m.meta.at("layout", default: "grid") != "di"
    or m.nodes.any(n => "bounds" not in n))
  if needs-layout { grid-layout(m) } else { m }
}

// --------------------------------------------------------------- slicing ---

#let _matches(item, wanted) = {
  let names = (item.at("id", default: ""), item.at("name", default: ""))
  wanted.any(w => names.contains(w))
}

#let _as-array(v) = if v == none { () } else if type(v) == array { v } else { (v,) }

/// Keep only part of a model. `view` accepts:
///   (pool: "..." | ("...",))   (lane: ... )   (nodes: (ids...))   (exclude: (...))
///   (blackbox: false)          drop counterpart participants instead of collapsing them
///
/// By default a participant that the slice removed but that still exchanges
/// messages with what remains is kept as a **black box**: a collapsed band with
/// its name and nothing inside. That is the BPMN idiom for "this partner exists,
/// its internals are not your concern", and it means slicing by pool no longer
/// silently deletes half the collaboration.
#let bpmn-slice(model, view, pad: 20) = {
  if view == none { return model }
  let blackbox = view.at("blackbox", default: true)
  let bb-height = view.at("blackbox-height", default: 56)
  let bb-gap = view.at("blackbox-gap", default: 46)
  let want-pools = _as-array(view.at("pool", default: view.at("pools", default: none)))
  let want-lanes = _as-array(view.at("lane", default: view.at("lanes", default: none)))
  let want-nodes = _as-array(view.at("nodes", default: none))
  let drop = _as-array(view.at("exclude", default: none))

  let pools = model.pools
  if want-pools.len() > 0 { pools = pools.filter(p => _matches(p, want-pools)) }
  if drop.len() > 0 { pools = pools.filter(p => not _matches(p, drop)) }
  let pool-ids = pools.map(p => p.id)

  // lanes: narrow the surviving pools to the requested lanes
  if want-lanes.len() > 0 {
    pools = pools.map(p => {
      let q = p
      if "lanes" in p {
        let keep = p.lanes.filter(l => _matches(l, want-lanes))
        if keep.len() > 0 {
          q.lanes = keep
          // shrink the pool frame to the kept lanes
          let y0 = calc.min(..keep.map(l => l.bounds.y))
          let y1 = calc.max(..keep.map(l => l.bounds.y + l.bounds.h))
          q.bounds = (x: p.bounds.x, y: y0, w: p.bounds.w, h: y1 - y0)
        }
      }
      q
    })
  }
  let lane-ids = pools.map(p => p.at("lanes", default: ()).map(l => l.id)).flatten()

  let keep-node(n) = {
    if drop.len() > 0 and _matches(n, drop) { return false }
    if want-nodes.len() > 0 { return _matches(n, want-nodes) }
    if n.kind == "group" { return want-pools.len() == 0 and want-lanes.len() == 0 }
    let np = n.at("pool", default: "")
    let nl = n.at("lane", default: "")
    if want-lanes.len() > 0 { return lane-ids.contains(nl) }
    if want-pools.len() > 0 { return pool-ids.contains(np) }
    true
  }
  let core = model.nodes.filter(keep-node)
  let core-ids = core.map(n => n.id)

  // Lượt hai: nhặt những gì *gắn vào* phần vừa giữ.
  //
  // Chỉ chạy khi cắt theo `nodes`, vì đó là lối cắt duy nhất nhận vào một danh sách id
  // đóng. Cắt theo pool/lane thì data object và comment đã thuộc pool nào đó nên đã
  // được giữ theo; còn `nodes` thì đúng những gì có trong danh sách mới sống.
  //
  // Vì sao danh sách đó luôn thiếu: `bpmn-span` tính tập id bằng cách đi theo **sequence
  // flow**, và đó là định nghĩa đúng của "đoạn từ A tới B". Nhưng data object, comment
  // và group không nằm *trên* dòng chảy, chúng *gắn vào* dòng chảy, nên không bao giờ
  // xuất hiện trong tập đó. Kết quả là lát cắt đúng về đồ thị mà mất sạch bối cảnh: nó
  // thôi là bản phóng to của cùng một hình.
  //
  // Hợp đồng sau khi sửa: **sequence flow quyết định biên, mọi thứ gắn vào phần trong
  // biên thì đi theo.**
  let attached = if want-nodes.len() == 0 { () } else {
    // Comment và data object nối vào dòng chảy bằng association (hoặc data association).
    let links = model.flows.filter(f => (
      f.at("kind", default: "sequence") in ("association", "data")
    ))
    let touched = (:)
    for f in links {
      if core-ids.contains(f.source) { touched.insert(f.target, true) }
      if core-ids.contains(f.target) { touched.insert(f.source, true) }
    }
    let inside(b, c) = {
      // Lấy *tâm* hộp chứ không lấy giao hai hình: một group thường chờm lên hàng xóm
      // vài đơn vị, xét theo giao thì nó kéo theo cả những node nó chỉ chạm mép.
      let cx = c.bounds.x + c.bounds.w / 2
      let cy = c.bounds.y + c.bounds.h / 2
      cx > b.x and cx < b.x + b.w and cy > b.y and cy < b.y + b.h
    }
    model.nodes.filter(n => {
      if core-ids.contains(n.id) { return false }
      if drop.len() > 0 and _matches(n, drop) { return false }
      // Group đi theo khi nó bao trùm ít nhất một phần tử đã giữ.
      if n.kind == "group" { return core.any(c => inside(n.bounds, c)) }
      n.kind in ("data", "annotation") and touched.at(n.id, default: false)
    })
  }

  let nodes = core + attached
  let ids = nodes.map(n => n.id)
  // a connection survives only if both of its ends did
  let flows = model.flows.filter(f => ids.contains(f.source) and ids.contains(f.target))

  // Drop pools that ended up empty. Slicing by lane would otherwise leave the
  // other participants standing around as blank frames, and their bounds would
  // still inflate the extent.
  let live-pools = nodes.map(n => n.at("pool", default: "")).dedup()
  pools = pools.filter(p => _matches(p, want-pools) or live-pools.contains(p.id))

  // recompute the extent over what is left
  let boxes = pools.map(p => p.bounds)
  boxes += nodes.map(n => n.bounds)
  boxes += nodes.filter(n => "label" in n).map(n => n.label)
  boxes += flows.filter(f => "label" in f).map(f => f.label)
  let xs = boxes.map(b => (b.x, b.x + b.w)).flatten()
  let ys = boxes.map(b => (b.y, b.y + b.h)).flatten()
  xs += flows.map(f => f.waypoints.map(w => w.at(0))).flatten()
  ys += flows.map(f => f.waypoints.map(w => w.at(1))).flatten()
  if xs.len() == 0 { panic("bpmn: view removed every element") }

  let ce = (x: calc.min(..xs) - pad, y: calc.min(..ys) - pad,
            w: calc.max(..xs) - calc.min(..xs) + 2 * pad,
            h: calc.max(..ys) - calc.min(..ys) + 2 * pad)

  // ---- collapse the counterpart participants into black boxes --------------
  let dropped = model.nodes.filter(n => not ids.contains(n.id))
  let pool-of = (:)
  for n in model.nodes { pool-of.insert(n.id, n.at("pool", default: "")) }
  // Một message flow có thể neo thẳng vào *participant* chứ không vào node nào bên
  // trong, và đó chính là hình dạng của một đối tác hộp đen: nó không có process nên
  // không có node để neo vào. Tra `pool-of` bằng id participant thì không thấy, trả về
  // "" rồi bị lọc bỏ ngay dòng dưới, nên cả đối tác lẫn message flow biến mất khỏi lát
  // cắt mà không có gì báo. Ánh xạ mỗi participant về chính nó là đủ.
  //
  // Đây là mảnh còn sót của việc nhận diện hộp đen ở v0.13.0: parser đã biết một
  // participant không `processRef` là hộp đen, phần cắt lát thì vẫn giả định mọi đầu
  // của message flow là một node.
  for p in model.pools { if p.id not in pool-of { pool-of.insert(p.id, p.id) } }
  let orig-pool = (:)
  for p in model.pools { orig-pool.insert(p.id, p) }

  // message flows with exactly one end still on stage
  let crossing = if blackbox {
    model.flows.filter(f => f.kind == "message"
      and (ids.contains(f.source) != ids.contains(f.target)))
  } else { () }

  let partner-ids = crossing
    .map(f => pool-of.at(if ids.contains(f.source) { f.target } else { f.source }, default: ""))
    .filter(p => p != "" and not pools.map(q => q.id).contains(p))
    .dedup()

  // Horizontal pools stack, so a black box goes above or below; vertical pools
  // sit side by side, so it goes left or right. Either way the band keeps the
  // partner on the side it was originally on.
  let vertical = (pools.len() > 0
    and pools.all(p => not p.at("horizontal", default: true)))
  let near(p) = if vertical { orig-pool.at(p).bounds.x } else { orig-pool.at(p).bounds.y }
  let kept-near = if pools.len() == 0 { if vertical { ce.x } else { ce.y } } else {
    calc.min(..pools.map(p => if vertical { p.bounds.x } else { p.bounds.y }))
  }
  // Xếp theo vị trí gốc để thứ tự các dải giữ đúng thứ tự người vẽ đã đặt, không
  // phụ thuộc vào thứ tự message flow gặp được.
  let before = partner-ids.filter(p => near(p) < kept-near).sorted(key: near)
  let after = partner-ids.filter(p => near(p) >= kept-near).sorted(key: near)

  // the band spans the content on the other axis
  let span-lo = if pools.len() == 0 { if vertical { ce.y } else { ce.x } } else {
    calc.min(..pools.map(p => if vertical { p.bounds.y } else { p.bounds.x }))
  }
  let span-hi = if pools.len() == 0 { if vertical { ce.y + ce.h } else { ce.x + ce.w } } else {
    calc.max(..pools.map(p => if vertical { p.bounds.y + p.bounds.h } else { p.bounds.x + p.bounds.w }))
  }
  let span = span-hi - span-lo

  let band-at(offset) = if vertical {
    (x: offset, y: span-lo, w: bb-height, h: span)
  } else {
    (x: span-lo, y: offset, w: span, h: bb-height)
  }
  let content-lo = if vertical { ce.x } else { ce.y }
  let content-hi = if vertical { ce.x + ce.w } else { ce.y + ce.h }

  // Hai pool cạnh nhau trong BPMN luôn có khoảng trắng giữa chúng; các dải hộp đen
  // cũng vậy. Trước đây chúng được xếp sát nhau nên hai hộp đen liền kề dính thành
  // một khối và chỉ còn một đường kẻ phân cách.
  let pitch = bb-height + bb-gap
  let bands = (:)
  for (i, pid) in before.enumerate() {
    let k = before.len() - 1 - i          // khoảng cách tính từ phần nội dung
    bands.insert(pid, band-at(content-lo - bb-gap - bb-height - k * pitch))
  }
  for (i, pid) in after.enumerate() {
    bands.insert(pid, band-at(content-hi + bb-gap + i * pitch))
  }

  let bb-pools = partner-ids.map(pid => (
    id: pid, name: orig-pool.at(pid).at("name", default: ""),
    horizontal: not vertical, blackbox: true, bounds: bands.at(pid),
  ))

  // re-route each crossing message flow: the original waypoints ran to a shape
  // that is no longer drawn, so replace them with a straight drop between the
  // surviving node and the edge of its partner's band
  let by-id = (:)
  for n in nodes { by-id.insert(n.id, n) }
  let bb-flows = crossing.enumerate().map(((fi, f)) => {
    let src-kept = ids.contains(f.source)
    let node = by-id.at(if src-kept { f.source } else { f.target })
    let pid = pool-of.at(if src-kept { f.target } else { f.source }, default: "")
    if not bands.keys().contains(pid) { return none }
    let bb = bands.at(pid)
    // Nudge each drop off its neighbours: two nodes at the same coordinate would
    // otherwise put their message flows on exactly the same line and read as one.
    let nudge = (calc.rem(fi, 3) - 1) * 7
    let (at-node, at-band) = if vertical {
      let ny = node.bounds.y + node.bounds.h / 2 + nudge
      let leftwards = bb.x < node.bounds.x
      ((if leftwards { node.bounds.x } else { node.bounds.x + node.bounds.w }, ny),
       (if leftwards { bb.x + bb.w } else { bb.x }, ny))
    } else {
      let nx = node.bounds.x + node.bounds.w / 2 + nudge
      let up = bb.y < node.bounds.y
      ((nx, if up { node.bounds.y } else { node.bounds.y + node.bounds.h }),
       (nx, if up { bb.y + bb.h } else { bb.y }))
    }
    let q = f
    q.waypoints = if src-kept { (at-node, at-band) } else { (at-band, at-node) }
    q.remove("label", default: none)
    q
  }).filter(f => f != none)

  let m = model
  m.pools = pools + bb-pools
  m.nodes = nodes
  m.flows = flows + bb-flows
  m.meta.extent = if bb-pools.len() == 0 { ce } else if vertical {
    let x0 = calc.min(ce.x, ..bb-pools.map(p => p.bounds.x)) - pad
    let x1 = calc.max(ce.x + ce.w, ..bb-pools.map(p => p.bounds.x + p.bounds.w)) + pad
    (x: x0, y: ce.y, w: x1 - x0, h: ce.h)
  } else {
    let y0 = calc.min(ce.y, ..bb-pools.map(p => p.bounds.y)) - pad
    let y1 = calc.max(ce.y + ce.h, ..bb-pools.map(p => p.bounds.y + p.bounds.h)) + pad
    (x: ce.x, y: y0, w: ce.w, h: y1 - y0)
  }
  m
}

/// load -> slice -> compact, in that order. Slicing first means compaction only
/// has to deal with what will actually be drawn.
#let _prepare(src, view, comp) = {
  let m = bpmn-slice(bpmn-model(src), view)
  if comp == none or comp == false { return m }
  compact(m, opts: if type(comp) == dictionary { comp } else { (:) })
}

// ------------------------------------------------------------- rendering ---

/// Draw at an exact width, no layout queries. Returns content.
#let bpmn-at(model, width, theme: default-theme) = {
  let u = width / model.meta.extent.w
  draw-canvas(model, u, theme)
}

/// Pick a fit mode and the resulting length-per-unit for a given container.
/// `reserve` is space along the container's cross axis that the caption will
/// take once the figure is turned.
#let _fit-mode(e, size, fit, width, scale, theme, min-font, max-aspect, reserve: 0pt) = {
  let avail-w = size.width * scale
  let avail-h = size.height * scale
  let u-flat = avail-w / e.w
  let u-rot = calc.min(avail-h / e.w, calc.max(1pt, avail-w - reserve) / e.h)

  let mode = fit
  if fit == "auto" {
    // Rotate only when it actually buys legibility. A banner-shaped diagram
    // (very wide, very short) scores well on raw scale when rotated but ends up
    // as a thin column down an otherwise empty page, so leave those flat and let
    // the small-label signal push the author towards `view:` instead.
    let too-small = theme.font-size * u-flat < min-font
    let banner = e.w / e.h > max-aspect
    mode = if too-small and not banner and u-rot > u-flat * 1.1 { "rotate" } else { "width" }
  }
  let u = if mode == "fixed" {
    if width == none { panic("bpmn: fit: \"fixed\" needs width:") }
    width / e.w
  } else if mode == "rotate" { u-rot } else { u-flat }
  (mode: mode, u: u)
}

/// Layout-aware body: scales to the container, rotating if labels would be too small.
#let bpmn-body(
  model,
  fit: "auto",          // "auto" | "width" | "rotate" | "fixed"
  width: none,          // required for fit: "fixed"
  scale: 100%,
  theme: default-theme,
  min-font: 6pt,
  turn: "ccw",          // rotation sense for fit: "rotate"
  max-aspect: 2.5,      // wider than this and rotating just wastes the page
  debug: false,
) = layout(size => {
  let e = model.meta.extent
  let (mode, u) = _fit-mode(e, size, fit, width, scale, theme, min-font, max-aspect)

  let body = draw-canvas(model, u, theme)
  let out = if mode == "rotate" {
    // ccw: read by turning the page clockwise (the LaTeX sidewaysfigure convention)
    box(width: e.h * u, height: e.w * u,
      if turn == "cw" {
        place(dx: e.h * u, rotate(90deg, origin: top + left, reflow: false, body))
      } else {
        place(dy: e.w * u, rotate(-90deg, origin: top + left, reflow: false, body))
      })
  } else { body }

  // NB: no `place(bottom + ..)` here. A bottom-anchored placement needs a
  // definite container height, which makes the figure claim the whole remaining
  // page and pushes everything after it onto the next one.
  let body = align(center, box(out))
  if debug {
    let fs = theme.font-size * u
    body + align(right, text(size: 6pt, fill: rgb("#b00"),
      [#mode · #calc.round(e.w) × #calc.round(e.h) u · label #calc.round(fs / 1pt, digits: 2)pt · #model.nodes.len() nodes]))
  } else { body }
})

// ---------------------------------------------------------------- figure ---

/// A `#figure` wrapping the diagram.
///
/// Caption resolution: the `caption:` argument wins; otherwise `meta.caption`
/// from the YAML; otherwise `meta.title` (the BPMN group label, if any).
#let bpmn-figure(
  src,
  caption: none,
  view: none,
  fit: "auto",
  width: none,
  scale: 100%,
  theme: default-theme,
  min-font: 6pt,
  turn: "ccw",
  turn-caption: auto,   // auto = turn the caption too whenever the figure turns
  max-aspect: 2.5,
  landscape: false,
  label: none,          // see the note below: `<lbl>` after the call will not work
  compact: none,
  debug: false,
  kind: image,
  supplement: auto,
  ..figure-args,
) = {
  let model = _prepare(src, view, compact)
  let cap = caption
  if cap == none {
    let m = model.meta
    let t = m.at("caption", default: m.at("title", default: ""))
    if t != "" { cap = [#t] }
  }
  // `bpmn-figure` returns a wrapper (a rotate, a flipped page, a layout), and in
  // Typst `#foo(..) <lbl>` labels the *outermost* element — so a label written
  // after the call lands on the wrapper and `@lbl` fails with "cannot reference
  // rotate". Pass `label: <lbl>` instead and it is attached to the figure.
  let tag(fig) = if label == none { fig } else { [#fig#label] }

  if landscape {
    let body = bpmn-body(model, fit: fit, width: width, scale: scale, theme: theme,
      min-font: min-font, turn: turn, max-aspect: max-aspect, debug: debug)
    return page(flipped: true,
      tag(figure(body, caption: cap, kind: kind, supplement: supplement, ..figure-args)))
  }

  layout(size => {
    let e = model.meta.extent
    let probe = _fit-mode(e, size, fit, width, scale, theme, min-font, max-aspect)

    // A sideways figure whose caption stays horizontal wastes the space the
    // caption sits in twice over: once under the diagram, once as the band the
    // rotation could not use. Turning the whole figure — diagram and caption as
    // one unit, the way `sidewaysfigure` does it — reclaims that.
    let turning = (probe.mode == "rotate" and cap != none
      and (turn-caption == true or turn-caption == auto))

    if not turning {
      let body = bpmn-body(model, fit: fit, width: width, scale: scale, theme: theme,
        min-font: min-font, turn: turn, max-aspect: max-aspect, debug: debug)
      return tag(figure(body, caption: cap, kind: kind, supplement: supplement, ..figure-args))
    }

    // Two passes: size the diagram, measure how tall the caption comes out at
    // that width, then re-size with that height taken off the budget.
    let cap-h(u) = measure(box(width: e.w * u, cap)).height + 1.4 * text.size
    let first = _fit-mode(e, size, fit, width, scale, theme, min-font, max-aspect)
    let fitted = _fit-mode(e, size, fit, width, scale, theme, min-font, max-aspect,
      reserve: cap-h(first.u))
    let u = fitted.u

    let inner = draw-canvas(model, u, theme)
    let note = if debug {
      align(right, text(size: 6pt, fill: rgb("#b00"),
        [turned · #calc.round(e.w) × #calc.round(e.h) u · label #calc.round(theme.font-size * u / 1pt, digits: 2)pt]))
    }
    let fig = tag(figure(align(center, box(inner)) + note, caption: cap,
      kind: kind, supplement: supplement, ..figure-args))
    rotate(if turn == "cw" { 90deg } else { -90deg }, reflow: true,
      box(width: e.w * u, fig))
  })
}

/// Diagram without figure furniture.
#let bpmn(src, view: none, compact: none, ..args) = bpmn-body(_prepare(src, view, compact), ..args)

// ------------------------------------------------------------------ info ---

/// Numbers you might want in prose or in a test: element counts and the label
/// size the diagram would render at for a given width.
#let bpmn-info(src, width: 170mm, view: none, compact: none, theme: default-theme) = {
  let m = _prepare(src, view, compact)
  let u = width / m.meta.extent.w
  (
    pools: m.pools.len(),
    lanes: m.pools.map(p => p.at("lanes", default: ()).len()).sum(default: 0),
    nodes: m.nodes.len(),
    flows: m.flows.len(),
    extent: m.meta.extent,
    label-size: theme.font-size * u,
    by-kind: {
      let d = (:)
      for n in m.nodes { d.insert(n.kind, d.at(n.kind, default: 0) + 1) }
      d
    },
  )
}
