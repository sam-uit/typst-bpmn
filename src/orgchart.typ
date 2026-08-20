// /template/components/orgchart.typ
// Organization Chart: sơ đồ tổ chức dựng từ YAML, thuần Typst.
//
// Không dùng thư viện ngoài (fletcher/cetz): bố cục cây được tính bằng
// `measure` + thuật toán xếp cây, sau đó vẽ bằng `place` + `line` + `polygon`.
//
// Ba loại node (giữ nguyên quy ước o/r/p của tài liệu):
//   o = Đơn vị tổ chức  (viền kép)
//   r = Vị trí/Vai trò  (viền đơn, nền chuyển sắc)
//   p = Con người       (viền đứt)
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - ocnode(body, kind: "o"|"r"|"p", ..)  : Một khối node đơn lẻ.
//   - orgchart(tree, ..)                   : Sơ đồ hoàn chỉnh.
//   - orgchart-data(data, ..)              : Dựng từ dict đã nạp.
//   - orgchart-file(path, ..)              : Nạp YAML/JSON rồi dựng.
//   - orgchart-legend(..)                  : Chú giải ba loại node.
//   - oc-themes                            : Các bộ màu dựng sẵn.

// MARK: Themes
#import "bptext.typ": bp-text, bp-flatten

#let oc-themes = (
  // Vàng hổ phách, giống sơ đồ mẫu
  classic: (
    line: luma(20%),
    o-fill: gradient.linear(rgb("#fffdf2"), rgb("#f6dd80")),
    o-stroke: luma(20%),
    r-fill: gradient.linear(rgb("#fffdf2"), rgb("#f7e79a")),
    r-stroke: luma(20%),
    p-fill: white,
    p-stroke: luma(20%),
    text: black,
  ),
  // Đen trắng, an toàn khi in
  bw: (
    line: luma(25%),
    o-fill: luma(93%),
    o-stroke: luma(25%),
    r-fill: luma(97%),
    r-stroke: luma(25%),
    p-fill: white,
    p-stroke: luma(45%),
    text: black,
  ),
  // Xanh ngọc, đồng bộ với theme báo cáo
  aqua: (
    line: rgb("#1d7c92"),
    o-fill: gradient.linear(rgb("#f2fafc"), rgb("#bfe0e8")),
    o-stroke: rgb("#1d7c92"),
    r-fill: gradient.linear(rgb("#f7fcfd"), rgb("#d8eef3")),
    r-stroke: rgb("#1d7c92"),
    p-fill: white,
    p-stroke: rgb("#5aa0b0"),
    text: rgb("#0d3d49"),
  ),
  // Cam, đồng bộ với bản vẽ fletcher cũ
  amber: (
    line: luma(30%),
    o-fill: gradient.linear(rgb("#fff8f0"), rgb("#ffd9a8")),
    o-stroke: luma(30%),
    r-fill: gradient.linear(rgb("#fffaf4"), rgb("#ffe7c9")),
    r-stroke: luma(30%),
    p-fill: white,
    p-stroke: luma(45%),
    text: black,
  ),
)

// MARK: Component: một node
#let ocnode(
  body,
  kind: "o",
  theme: oc-themes.classic,
  width: 100%,
  height: 100%,
  inset: 5pt,
  radius: 1pt,
  size: 8.5pt,
  font: auto,
) = {
  let txt = body => align(center + horizon, {
    set text(
      size: size,
      fill: theme.text,
      hyphenate: false,
      weight: if kind == "o" { "medium" } else { "regular" },
      ..(if font != auto { (font: font) } else { (:) }),
    )
    set par(justify: false, leading: 0.45em)
    body
  })

  if kind == "o" {
    // Viền kép: khối ngoài + khối trong
    block(
      width: width,
      height: height,
      stroke: 0.7pt + theme.o-stroke,
      radius: radius,
      inset: 1.6pt,
      block(
        width: 100%,
        height: 100%,
        fill: theme.o-fill,
        stroke: 0.7pt + theme.o-stroke,
        radius: radius,
        inset: inset,
        txt(body),
      ),
    )
  } else if kind == "p" {
    // Viền đứt
    block(
      width: width,
      height: height,
      fill: theme.p-fill,
      stroke: (paint: theme.p-stroke, thickness: 0.7pt, dash: "dashed"),
      radius: radius,
      inset: inset,
      txt(body),
    )
  } else {
    block(
      width: width,
      height: height,
      fill: theme.r-fill,
      stroke: 0.7pt + theme.r-stroke,
      radius: radius,
      inset: inset,
      txt(body),
    )
  }
}

// MARK: Chú giải
#let orgchart-legend(
  theme: "classic",
  size: 8.5pt,
  labels: ("Đơn Vị Tổ Chức", "Vị Trí/Vai Trò", "Cá Nhân"),
  dir: ltr,
  width: 3cm,
) = {
  let th = if type(theme) == str { oc-themes.at(theme) } else { theme }
  let one = (k, l) => box(width: width, height: 1cm, ocnode(l, kind: k, theme: th, size: size))
  stack(
    dir: dir,
    spacing: 8pt,
    one("o", labels.at(0)),
    one("r", labels.at(1)),
    one("p", labels.at(2)),
  )
}

// MARK: Chuẩn hóa dữ liệu
// Một node có thể là:
//   "Tên"                              -> person
//   { o: "Tên", children: [...] }      -> đơn vị, khóa o/r/p vừa là loại vừa là nhãn
//   { r: "Tên", p: ["A", "B"] }        -> vai trò + danh sách người (rút gọn)
//   { name: "Tên", type: "o", .. }     -> dạng tường minh
#let oc-parse(node) = {
  if type(node) == str or type(node) == content {
    return (kind: "p", label: node, children: (), fill: auto)
  }
  if type(node) != dictionary { return (kind: "p", label: [], children: (), fill: auto) }

  let kind = none
  let label = none
  for k in ("o", "r", "p") {
    if kind == none and k in node and type(node.at(k)) != array {
      kind = k
      label = node.at(k)
    }
  }
  // Dạng tường minh
  if kind == none {
    kind = node.at("type", default: node.at("kind", default: "o"))
    label = node.at("name", default: node.at("text", default: node.at("label", default: "")))
  }

  let kids = ()
  for c in node.at("children", default: ()) { kids.push(oc-parse(c)) }
  // Rút gọn: `p:` là danh sách người con (khi node không phải person)
  if kind != "p" and "p" in node {
    let ps = node.at("p")
    if type(ps) == array {
      for x in ps { kids.push(oc-parse(x)) }
    } else if kind != "p" and "children" not in node and type(ps) == str {
      kids.push(oc-parse(ps))
    }
  }

  (
    kind: kind,
    label: label,
    children: kids,
    fill: node.at("color", default: node.at("fill", default: auto)),
    stack: node.at("stack", default: auto),
  )
}

// MARK: Lọc cây
#let oc-filter(node, depth: none, only: none, exclude: none, d: 0) = {
  if only != none and node.kind not in only { return none }
  if exclude != none and type(node.label) == str and node.label in exclude { return none }
  let kids = if depth != none and d >= depth { () } else {
    node.children
      .map(c => oc-filter(c, depth: depth, only: only, exclude: exclude, d: d + 1))
      .filter(x => x != none)
  }
  node + (children: kids)
}

// Tìm một node theo nhãn (để vẽ riêng một nhánh)
#let oc-find(node, name) = {
  if type(node.label) == str and node.label == name { return node }
  for c in node.children {
    let hit = oc-find(c, name)
    if hit != none { return hit }
  }
  none
}

// MARK: Đo kích thước
// Gán w/h cho từng node. Bề rộng: đo tự nhiên rồi kẹp trong [min-width, max-width].
#let oc-measure(
  node,
  size: 8.5pt,
  inset: 5pt,
  min-width: 2cm,
  max-width: 3.4cm,
  node-width: auto,
  font: auto,
  // Bề rộng ép theo cấp (dict "0" -> length), dùng cho chế độ cột đều nhau
  widths: none,
  d: 0,
) = {
  let styled = body => {
    let body = bp-text(body)
    set text(
      size: size,
      hyphenate: false,
      weight: if node.kind == "o" { "medium" } else { "regular" },
      ..(if font != auto { (font: font) } else { (:) }),
    )
    set par(justify: false, leading: 0.45em)
    body
  }
  let pad = 2 * inset + (if node.kind == "o" { 3.2pt } else { 0pt })
  let w = if widths != none and str(d) in widths {
    widths.at(str(d))
  } else if node-width != auto {
    node-width
  } else {
    let nat = measure(styled(node.label)).width + pad
    calc.max(min-width, calc.min(max-width, nat))
  }
  let h = measure(block(width: w - pad, styled(node.label))).height + pad
  let kids = node.children.map(c => oc-measure(
    c,
    size: size,
    inset: inset,
    min-width: min-width,
    max-width: max-width,
    node-width: node-width,
    font: font,
    widths: widths,
    d: d + 1,
  ))
  node + (w: w, h: h, children: kids)
}

// MARK: Dịch chuyển cả cây con theo trục ngang
#let oc-shift(node, dx) = node + (
  cx: node.cx + dx,
  children: node.children.map(c => oc-shift(c, dx)),
)

// MARK: Bố cục Trên-Xuống (TB)
// Trả về (node, span). `cx` là toạ độ tâm theo trục ngang.
#let oc-layout-tb(node, x0, hgap: 8pt, stack-gap: 4pt, stack-when: none) = {
  let kids = node.children
  if kids.len() == 0 {
    return (node: node + (cx: x0 + node.w / 2), span: node.w)
  }

  // Xếp chồng dọc khi các con đều là lá và:
  //   - đều là person (mặc định), hoặc
  //   - số lượng >= `stack-when` (tránh một hàng ngang quá rộng)
  let all-leaf = kids.all(k => k.children.len() == 0)
  let stacked = if node.stack != auto { node.stack } else {
    all-leaf and (
      kids.all(k => k.kind == "p") or (stack-when != none and kids.len() >= stack-when)
    )
  }
  if stacked and not all-leaf {
    panic("orgchart: `stack` chỉ dùng được khi mọi node con đều là lá: " + repr(node.label))
  }

  if stacked {
    let span = calc.max(node.w, ..kids.map(k => k.w))
    let cx = x0 + span / 2
    let kids2 = kids.map(k => k + (cx: cx, stacked: true))
    return (node: node + (cx: cx, children: kids2, stacks: true), span: span)
  }

  let cursor = x0
  let out = ()
  for k in kids {
    let r = oc-layout-tb(k, cursor, hgap: hgap, stack-gap: stack-gap, stack-when: stack-when)
    out.push(r.node)
    cursor += r.span + hgap
  }
  let kspan = cursor - hgap - x0
  let kcenter = (out.first().cx + out.last().cx) / 2

  if node.w > kspan {
    // Node cha rộng hơn cả hàng con -> đẩy các con vào giữa
    let dx = (node.w - kspan) / 2
    out = out.map(k => oc-shift(k, dx))
    (node: node + (cx: x0 + node.w / 2, children: out, stacks: false), span: node.w)
  } else {
    (node: node + (cx: kcenter, children: out, stacks: false), span: kspan)
  }
}

// Gán toạ độ y theo cấp (TB): mỗi cấp một hàng, chiều cao hàng = node cao nhất
#let oc-row-heights(node, d: 0, acc: (:)) = {
  let key = str(d)
  let cur = acc.at(key, default: 0pt)
  let acc2 = acc
  // Node trong cụm xếp chồng không tham gia tính chiều cao hàng
  acc2.insert(key, calc.max(cur, node.h))
  for c in node.children {
    if node.at("stacks", default: false) { continue }
    acc2 = oc-row-heights(c, d: d + 1, acc: acc2)
  }
  acc2
}

#let oc-assign-y(node, y, rows, vgap: 14pt, stack-gap: 4pt, d: 0) = {
  let n = node + (y: y)
  if node.children.len() == 0 { return n }
  if node.at("stacks", default: false) {
    // Người xếp chồng: chảy dọc ngay dưới node cha
    let cy = y + node.h + vgap
    let kids = ()
    for k in node.children {
      kids.push(k + (y: cy))
      cy += k.h + stack-gap
    }
    return n + (children: kids)
  }
  let ny = y + rows.at(str(d), default: node.h) + vgap
  n + (children: node.children.map(c => oc-assign-y(c, ny, rows, vgap: vgap, stack-gap: stack-gap, d: d + 1)))
}

// MARK: Bố cục Trái-Phải (LR)
// Trục chính là x theo cấp, các con luôn xếp chồng dọc.
#let oc-col-widths(node, d: 0, acc: (:)) = {
  let key = str(d)
  let acc2 = acc
  acc2.insert(key, calc.max(acc.at(key, default: 0pt), node.w))
  for c in node.children { acc2 = oc-col-widths(c, d: d + 1, acc: acc2) }
  acc2
}

#let oc-shift-y(node, dy) = node + (
  cy: node.cy + dy,
  children: node.children.map(c => oc-shift-y(c, dy)),
)

#let oc-layout-lr(node, y0, vgap: 5pt) = {
  let kids = node.children
  if kids.len() == 0 {
    return (node: node + (cy: y0 + node.h / 2), span: node.h)
  }
  let cursor = y0
  let out = ()
  for k in kids {
    let r = oc-layout-lr(k, cursor, vgap: vgap)
    out.push(r.node)
    cursor += r.span + vgap
  }
  let kspan = cursor - vgap - y0
  let kcenter = (out.first().cy + out.last().cy) / 2
  if node.h > kspan {
    let dy = (node.h - kspan) / 2
    out = out.map(k => oc-shift-y(k, dy))
    (node: node + (cy: y0 + node.h / 2, children: out), span: node.h)
  } else {
    (node: node + (cy: kcenter, children: out), span: kspan)
  }
}

#let oc-assign-x(node, x, cols, hgap: 16pt, d: 0) = {
  let n = node + (x: x)
  if node.children.len() == 0 { return n }
  let nx = x + cols.at(str(d), default: node.w) + hgap
  n + (children: node.children.map(c => oc-assign-x(c, nx, cols, hgap: hgap, d: d + 1)))
}

// MARK: Làm phẳng cây -> danh sách node + danh sách cạnh
#let oc-flatten-tb(node, vgap: 14pt) = {
  let nodes = ((x: node.cx - node.w / 2, y: node.y, w: node.w, h: node.h, kind: node.kind, label: node.label, fill: node.fill),)
  let edges = ()
  let kids = node.children
  if kids.len() > 0 {
    if node.at("stacks", default: false) {
      // Đường dọc: cha -> con đầu, rồi nối giữa các con liên tiếp
      let prev = (y: node.y + node.h)
      for k in kids {
        edges.push((kind: "v", x: node.cx, y1: prev.y, y2: k.y))
        prev = (y: k.y + k.h)
      }
    } else {
      let bus = node.y + node.h + vgap / 2
      edges.push((kind: "v", x: node.cx, y1: node.y + node.h, y2: bus))
      let xs = kids.map(k => k.cx)
      if kids.len() > 1 {
        edges.push((kind: "h", y: bus, x1: calc.min(..xs), x2: calc.max(..xs)))
      }
      for k in kids {
        edges.push((kind: "v", x: k.cx, y1: bus, y2: k.y))
      }
    }
    for k in kids {
      let r = oc-flatten-tb(k, vgap: vgap)
      nodes += r.nodes
      edges += r.edges
    }
  }
  (nodes: nodes, edges: edges)
}

#let oc-flatten-lr(node, hgap: 16pt) = {
  let nodes = ((x: node.x, y: node.cy - node.h / 2, w: node.w, h: node.h, kind: node.kind, label: node.label, fill: node.fill),)
  let edges = ()
  let kids = node.children
  if kids.len() > 0 {
    let bus = node.x + node.w + hgap / 2
    edges.push((kind: "h", y: node.cy, x1: node.x + node.w, x2: bus))
    let ys = kids.map(k => k.cy)
    if kids.len() > 1 {
      edges.push((kind: "v", x: bus, y1: calc.min(..ys), y2: calc.max(..ys)))
    }
    for k in kids {
      edges.push((kind: "h", y: k.cy, x1: bus, x2: k.x))
    }
    for k in kids {
      let r = oc-flatten-lr(k, hgap: hgap)
      nodes += r.nodes
      edges += r.edges
    }
  }
  (nodes: nodes, edges: edges)
}

// MARK: Component: sơ đồ tổ chức
#let orgchart(
  tree,
  // "tb" (trên-xuống) | "lr" (trái-phải)
  dir: "tb",
  // Lọc dữ liệu trước khi vẽ
  depth: none,
  only: none,
  exclude: none,
  root: none,
  // Giao diện
  theme: "classic",
  size: 8.5pt,
  inset: 5pt,
  node-width: auto,
  min-width: 2cm,
  max-width: 3.4cm,
  // Các node cùng cấp có bề rộng bằng nhau (mặc định: bật cho "lr")
  uniform: auto,
  hgap: 8pt,
  vgap: 14pt,
  stack-gap: 4pt,
  // Nhóm >= n node lá cùng cha thì xếp chồng dọc thay vì trải ngang (TB)
  stack-when: none,
  stroke: 0.7pt,
  // "width" = tự co cho vừa bề ngang; "none" = giữ nguyên
  fit: "width",
  font: auto,
) = context layout(avail => {
  let th = if type(theme) == str { oc-themes.at(theme) } else { theme }

  // --- Dữ liệu ---
  let roots = if type(tree) == array { tree.map(oc-parse) } else { (oc-parse(tree),) }
  if root != none {
    let hit = none
    for r in roots {
      if hit == none { hit = oc-find(r, root) }
    }
    if hit == none { panic("orgchart: không tìm thấy node '" + root + "'") }
    roots = (hit,)
  }
  roots = roots.map(r => oc-filter(r, depth: depth, only: only, exclude: exclude)).filter(x => x != none)
  if roots.len() == 0 { return }

  let mw = if dir == "lr" { calc.min(max-width, 3.2cm) } else { max-width }
  let msr = (rs, widths) => rs.map(r => oc-measure(
    r,
    size: size,
    inset: inset,
    min-width: min-width,
    max-width: mw,
    node-width: node-width,
    font: font,
    widths: widths,
  ))
  roots = msr(roots, none)

  // Cột đều nhau: đo lại với bề rộng lớn nhất của từng cấp
  let unify = if uniform == auto { dir == "lr" } else { uniform }
  if unify and node-width == auto {
    let cols = (:)
    for r in roots { cols = oc-col-widths(r, acc: cols) }
    roots = msr(roots, cols)
  }

  // --- Bố cục ---
  let all-nodes = ()
  let all-edges = ()
  let W = 0pt
  let H = 0pt

  if dir == "lr" {
    let cursor = 0pt
    for r in roots {
      let laid = oc-layout-lr(r, cursor, vgap: calc.max(stack-gap, 5pt))
      let cols = oc-col-widths(laid.node)
      let placed = oc-assign-x(laid.node, 0pt, cols, hgap: hgap * 2)
      let f = oc-flatten-lr(placed, hgap: hgap * 2)
      all-nodes += f.nodes
      all-edges += f.edges
      cursor += laid.span + vgap
    }
  } else {
    let cursor = 0pt
    for r in roots {
      let laid = oc-layout-tb(r, cursor, hgap: hgap, stack-gap: stack-gap, stack-when: stack-when)
      let rows = oc-row-heights(laid.node)
      let placed = oc-assign-y(laid.node, 0pt, rows, vgap: vgap, stack-gap: stack-gap)
      let f = oc-flatten-tb(placed, vgap: vgap)
      all-nodes += f.nodes
      all-edges += f.edges
      cursor += laid.span + hgap * 2
    }
  }

  for n in all-nodes {
    W = calc.max(W, n.x + n.w)
    H = calc.max(H, n.y + n.h)
  }

  // --- Vẽ ---
  let body = block(width: W, height: H, {
    set line(stroke: stroke + th.line)
    for e in all-edges {
      if e.kind == "v" {
        place(dx: 0pt, dy: 0pt, line(start: (e.x, e.y1), end: (e.x, e.y2)))
      } else {
        place(dx: 0pt, dy: 0pt, line(start: (e.x1, e.y), end: (e.x2, e.y)))
      }
    }
    for n in all-nodes {
      place(dx: n.x, dy: n.y, ocnode(
        bp-text(n.label),
        kind: n.kind,
        theme: if n.fill == auto { th } else {
          th + (
            o-fill: n.fill,
            r-fill: n.fill,
            p-fill: n.fill,
          )
        },
        width: n.w,
        height: n.h,
        inset: inset,
        size: size,
        font: font,
      ))
    }
  })

  if fit == "width" and W > avail.width {
    let r = avail.width / W
    scale(x: r * 100%, y: r * 100%, origin: top + left, reflow: true, body)
  } else {
    body
  }
})

// MARK: Wrapper: dựng từ dữ liệu đã nạp
// Khóa hiểu được: tree | root | chart (cây), caption, label, options
#let orgchart-data(data, ..args) = {
  if type(data) == array { return orgchart(data, ..args) }
  if type(data) != dictionary { return orgchart(data, ..args) }

  let named = data.at("options", default: (:)) + args.named()
  let caption = named.at("caption", default: data.at("caption", default: none))
  let lbl = named.at("label", default: data.at("label", default: none))
  for k in ("caption", "label", "title") {
    if k in named { let _ = named.remove(k) }
  }

  let tree = if "tree" in data { data.tree } else if "chart" in data { data.chart } else if "root" in data {
    data.root
  } else { data }

  let out = if caption != none {
    figure(orgchart(tree, ..named), caption: caption, kind: image, supplement: "Hình ảnh")
  } else {
    orgchart(tree, ..named)
  }
  if lbl != none { [#out #label(lbl)] } else { out }
}

// MARK: Wrapper: nạp và dựng trong một lệnh
// LƯU Ý: đường dẫn tuyệt đối từ gốc project ("/content/diagrams/x.yaml").
#let orgchart-file(path, ..args) = {
  let raw = if path.ends-with(".yaml") or path.ends-with(".yml") {
    yaml(path)
  } else if path.ends-with(".json") {
    json(path)
  } else {
    panic("orgchart: không hỗ trợ định dạng của " + path)
  }
  orgchart-data(raw, ..args)
}
