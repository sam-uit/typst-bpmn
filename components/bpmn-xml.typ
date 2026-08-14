// Read BPMN 2.0 XML directly in Typst, producing the same model dictionary the
// YAML path produces. Useful for drafting (no build step); the Python converter
// stays the better option for reports, since it strips execution attributes once
// and gives you a diffable artefact.
//
//   #bpmn-from-xml(xml("model.bpmn"))
//
// Typst's `xml()` already strips namespace prefixes from tags and attributes,
// so everything below matches on local names.

#let _events = (
  startEvent: ("start", false),
  intermediateCatchEvent: ("intermediate", false),
  intermediateThrowEvent: ("intermediate", true),
  boundaryEvent: ("boundary", false),
  endEvent: ("end", true),
)
#let _event-defs = (
  messageEventDefinition: "message", timerEventDefinition: "timer",
  errorEventDefinition: "error", signalEventDefinition: "signal",
  escalationEventDefinition: "escalation", terminateEventDefinition: "terminate",
  compensateEventDefinition: "compensate", conditionalEventDefinition: "conditional",
  linkEventDefinition: "link", cancelEventDefinition: "cancel",
)
#let _tasks = (
  task: "none", userTask: "user", serviceTask: "service", sendTask: "send",
  receiveTask: "receive", manualTask: "manual", scriptTask: "script",
  businessRuleTask: "rule", callActivity: "call",
)
#let _gateways = (
  exclusiveGateway: "exclusive", parallelGateway: "parallel",
  inclusiveGateway: "inclusive", eventBasedGateway: "event", complexGateway: "complex",
)
#let _subprocess = ("subProcess", "transaction", "adHocSubProcess")
#let _data = (dataObjectReference: "object", dataStoreReference: "store")
#let _flow-kinds = (
  sequenceFlow: "sequence", messageFlow: "message", association: "association",
  dataInputAssociation: "data", dataOutputAssociation: "data",
)

#let _els(e) = if type(e) == dictionary and "children" in e {
  e.children.filter(c => type(c) == dictionary)
} else { () }

#let _first(e, tag) = {
  let m = _els(e).filter(c => c.tag == tag)
  if m.len() > 0 { m.first() } else { none }
}

/// Depth-first walk yielding every element.
#let _walk(e) = {
  let out = (e,)
  for c in _els(e) { out += _walk(c) }
  out
}

#let _num(v, default: 0.0) = if v == none { default } else {
  let f = float(v)
  calc.round(f, digits: 2)
}

#let _attr(e, name, default: none) = e.attrs.at(name, default: default)

#let _bounds(e) = {
  if e == none { return none }
  let b = _first(e, "Bounds")
  if b == none { return none }
  (x: _num(_attr(b, "x")), y: _num(_attr(b, "y")),
   w: _num(_attr(b, "width")), h: _num(_attr(b, "height")))
}

#let _colors(e) = {
  let out = (:)
  let fill = _attr(e, "background-color", default: _attr(e, "fill"))
  let stroke = _attr(e, "border-color", default: _attr(e, "stroke"))
  if fill != none { out.insert("fill", fill) }
  if stroke != none { out.insert("stroke", stroke) }
  out
}

#let bpmn-from-xml(doc, source: "model.bpmn") = {
  let root = if type(doc) == array { doc.first() } else { doc }
  let all = _walk(root)

  // --- index DI ------------------------------------------------------------
  let shapes = (:)
  let edges = (:)
  let category = (:)
  let defaults = ()
  for e in all {
    if e.tag == "BPMNShape" { shapes.insert(_attr(e, "bpmnElement", default: ""), e) }
    else if e.tag == "BPMNEdge" { edges.insert(_attr(e, "bpmnElement", default: ""), e) }
    else if e.tag == "categoryValue" {
      category.insert(_attr(e, "id", default: ""), _attr(e, "value", default: ""))
    }
    let d = _attr(e, "default")
    if d != none { defaults.push(d) }
  }

  // --- pool / lane membership ---------------------------------------------
  let proc-pool = (:)
  for p in all.filter(e => e.tag == "participant") {
    let pr = _attr(p, "processRef")
    if pr != none { proc-pool.insert(pr, _attr(p, "id", default: "")) }
  }
  let node-pool = (:)
  let node-lane = (:)
  for proc in all.filter(e => e.tag == "process") {
    let pool = proc-pool.at(_attr(proc, "id", default: ""), default: "")
    for c in _walk(proc) {
      let id = _attr(c, "id")
      if id != none and not node-pool.keys().contains(id) { node-pool.insert(id, pool) }
      if c.tag == "lane" {
        for ref in _els(c).filter(x => x.tag == "flowNodeRef") {
          let txt = ref.children.filter(t => type(t) == str).join("").trim()
          if txt != "" { node-lane.insert(txt, _attr(c, "id", default: "")) }
        }
      }
    }
  }

  // --- pools ---------------------------------------------------------------
  let pools = ()
  for p in all.filter(e => e.tag == "participant") {
    let pid = _attr(p, "id", default: "")
    let shape = shapes.at(pid, default: none)
    if shape == none { continue }
    let entry = (id: pid, name: _attr(p, "name", default: ""),
                 horizontal: _attr(shape, "isHorizontal", default: "true") != "false",
                 bounds: _bounds(shape))
    for (k, v) in _colors(shape) { entry.insert(k, v) }
    let lanes = ()
    let pr = _attr(p, "processRef", default: "")
    for proc in all.filter(e => e.tag == "process" and _attr(e, "id", default: "") == pr) {
      for l in _walk(proc).filter(e => e.tag == "lane") {
        let ls = shapes.at(_attr(l, "id", default: ""), default: none)
        if ls == none { continue }
        lanes.push((id: _attr(l, "id", default: ""), name: _attr(l, "name", default: ""),
                    bounds: _bounds(ls)))
      }
    }
    if lanes.len() > 0 { entry.insert("lanes", lanes.sorted(key: l => l.bounds.y)) }
    pools.push(entry)
  }
  pools = pools.sorted(key: p => p.bounds.y)

  // --- nodes ---------------------------------------------------------------
  let nodes = ()
  for e in all {
    let t = e.tag
    let id = _attr(e, "id")
    if id == none { continue }
    let shape = shapes.at(id, default: none)
    if shape == none { continue }
    let n = (id: id, name: _attr(e, "name", default: ""))

    if t in _events {
      let (family, throw) = _events.at(t)
      let def = "none"
      for c in _els(e) { if c.tag in _event-defs { def = _event-defs.at(c.tag); break } }
      n += (kind: "event", event: family, definition: def,
            throw: throw or def == "terminate")
      if family == "boundary" {
        n += (attached-to: _attr(e, "attachedToRef", default: ""),
              interrupting: _attr(e, "cancelActivity", default: "true") != "false")
      }
    } else if t in _tasks {
      n += (kind: "task", task: _tasks.at(t))
    } else if _subprocess.contains(t) {
      n += (kind: "subprocess",
            expanded: _attr(shape, "isExpanded", default: "false") != "false",
            triggered-by-event: _attr(e, "triggeredByEvent", default: "false") != "false")
    } else if t in _gateways {
      n += (kind: "gateway", gateway: _gateways.at(t))
      if _gateways.at(t) == "exclusive" {
        n += (marker: _attr(shape, "isMarkerVisible", default: "false") != "false")
      }
    } else if t in _data {
      n += (kind: "data", data: _data.at(t))
    } else if t == "textAnnotation" {
      let txt = _first(e, "text")
      n += (kind: "annotation",
            text: if txt == none { "" } else {
              txt.children.filter(c => type(c) == str).join("").trim()
            })
    } else if t == "group" {
      n += (kind: "group",
            name: category.at(_attr(e, "categoryValueRef", default: ""), default: ""))
    } else { continue }

    n.insert("bounds", _bounds(shape))
    let lb = _bounds(_first(shape, "BPMNLabel"))
    if lb != none and lb.w > 0 { n.insert("label", lb) }
    for (k, v) in _colors(shape) { n.insert(k, v) }
    let pool = node-pool.at(id, default: "")
    if pool != "" { n.insert("pool", pool) }
    let lane = node-lane.at(id, default: "")
    if lane != "" { n.insert("lane", lane) }
    nodes.push(n)
  }
  let order = (group: 0, data: 2, annotation: 3)
  nodes = nodes.sorted(key: n => (order.at(n.kind, default: 1), n.bounds.y, n.bounds.x))

  // --- flows ---------------------------------------------------------------
  let flows = ()
  for e in all.filter(e => e.tag in _flow-kinds) {
    let id = _attr(e, "id", default: "")
    let edge = edges.at(id, default: none)
    if edge == none { continue }
    let f = (id: id, kind: _flow-kinds.at(e.tag),
             source: _attr(e, "sourceRef", default: ""),
             target: _attr(e, "targetRef", default: ""))
    let nm = _attr(e, "name", default: "")
    if nm != "" { f.insert("name", nm) }
    f.insert("waypoints", _els(edge).filter(w => w.tag == "waypoint")
      .map(w => (_num(_attr(w, "x")), _num(_attr(w, "y")))))
    let lb = _bounds(_first(edge, "BPMNLabel"))
    if lb != none and lb.w > 0 { f.insert("label", lb) }
    if defaults.contains(id) { f.insert("default", true) }
    if e.tag == "association" {
      f.insert("direction", lower(_attr(e, "associationDirection", default: "None")))
    }
    for (k, v) in _colors(edge) { f.insert(k, v) }
    flows.push(f)
  }

  // --- extent --------------------------------------------------------------
  let boxes = pools.map(p => p.bounds)
  boxes += nodes.map(n => n.bounds)
  boxes += nodes.filter(n => "label" in n).map(n => n.label)
  boxes += flows.filter(f => "label" in f).map(f => f.label)
  let xs = boxes.map(b => (b.x, b.x + b.w)).flatten()
  let ys = boxes.map(b => (b.y, b.y + b.h)).flatten()
  xs += flows.map(f => f.waypoints.map(w => w.at(0))).flatten()
  ys += flows.map(f => f.waypoints.map(w => w.at(1))).flatten()
  let pad = 10
  let (x0, y0) = (calc.min(..xs) - pad, calc.min(..ys) - pad)
  let extent = (x: x0, y: y0,
                w: calc.max(..xs) - calc.min(..xs) + 2 * pad,
                h: calc.max(..ys) - calc.min(..ys) + 2 * pad)

  let title = ""
  for n in nodes { if n.kind == "group" and n.at("name", default: "") != "" { title = n.name; break } }

  (
    meta: (id: _attr(root, "id", default: ""), source: source, title: title,
           extent: extent, layout: "di"),
    pools: pools, nodes: nodes, flows: flows,
  )
}
