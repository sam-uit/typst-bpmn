// src/bpmap.typ
// Business Process Map: Bản đồ quy trình (Value Chain) theo cách tổ chức của SAP:
//   Level 1: Management Processes / Core Processes / Support Processes
//   Level 2: một Process Area được bóc tách thành các quy trình con
//
// Tái sử dụng: `bpstep` (chevron) cho các quy trình, `grid` cho bố cục.
// Bổ sung: `bphouse` (hộp mái nhà chúc xuống / hướng lên) và `bpvbar`
// (dải dọc "Nhu cầu khách hàng" -> "Sự hài lòng khách hàng" ở hai biên).
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - bphouse(body, ..)      : Hộp ngũ giác mái nhà (point: "down" | "up").
//   - bpbox(body, ..)        : Hộp chữ nhật.
//   - bpvbar(body, ..)       : Dải dọc ở biên, chữ xoay 90 độ.
//   - bpmap(..)              : Bản đồ quy trình hoàn chỉnh (Level 1 hoặc Level 2).
//   - bpmap-data(data, ..)   : Dựng từ dict đã nạp.
//   - bpmap-file(path, ..)   : Nạp YAML/JSON rồi dựng, một lệnh.
//   - bp-themes              : Các bộ màu dựng sẵn ("bw", "sap", "aqua").

#import "bpstep.typ": bpstep, bp-to-color, bp-normalize, bp-contrast, bp-border, load-steps
#import "bpstep.typ": bp-anchor-marks, bp-plain

// MARK: Themes
//   accent      : màu dải dọc hai biên
//   band        : nền dải Quản lý / Hỗ trợ
//   core        : nền dải Cốt lõi
//   group       : nền từng nhóm bên trong dải Cốt lõi
//   shape       : nền mặc định của các khối hình
//   line        : màu đường viền các dải
#let bp-themes = (
  // Đen trắng: an toàn khi in, giống sơ đồ mẫu
  bw: (
    accent: luma(35%),
    accent-text: white,
    band: luma(92%),
    core: white,
    group: luma(93%),
    shape: white,
    line: luma(20%),
  ),
  // Phong cách SAP Signavio
  sap: (
    accent: rgb("#A01050"),
    accent-text: white,
    band: rgb("#fdf2f7"),
    core: white,
    group: rgb("#f4d3e3"),
    shape: white,
    line: rgb("#A01050"),
  ),
  // Xanh ngọc, hợp với template báo cáo
  aqua: (
    accent: rgb("#1d7c92"),
    accent-text: white,
    band: rgb("#eef5f7"),
    core: white,
    group: rgb("#dbeaef"),
    shape: white,
    line: rgb("#1d7c92"),
  ),
)

// MARK: Component: hộp mái nhà
// point: "down" (đỉnh chúc xuống: Quy trình Quản lý)
//        "up"   (đỉnh hướng lên : Quy trình Hỗ trợ)
#let bphouse(
  body,
  // Cắm mốc để component chú giải neo vào; xem bp-anchor-marks
  anchor: none,
  point: "down",
  peak: 22%,
  fill: white,
  stroke: auto,
  text-fill: auto,
  inset: 6pt,
  radius: 0pt,
  width: 100%,
  height: 100%,
  size: 10pt,
  weight: "regular",
  font: auto,
) = {
  let bg = bp-to-color(fill)
  let bd = if stroke == auto { 0.8pt + bp-border(bg) } else { stroke }
  let fg = if text-fill == auto { bp-contrast(bg) } else { bp-to-color(text-fill) }

  let pts = if point == "up" {
    ((0%, peak), (50%, 0%), (100%, peak), (100%, 100%), (0%, 100%))
  } else {
    ((0%, 0%), (100%, 0%), (100%, 100% - peak), (50%, 100%), (0%, 100% - peak))
  }

  block(width: width, height: height, radius: radius, {
    bp-anchor-marks(anchor)
      place(top + left, polygon(fill: bg, stroke: bd, ..pts))
    block(
      width: 100%,
      height: 100%,
      inset: (
        x: inset,
        top: inset + (if point == "up" { peak } else { 0% }),
        bottom: inset + (if point == "down" { peak } else { 0% }),
      ),
      align(center + horizon, {
        set text(
          fill: fg,
          weight: weight,
          size: size,
          hyphenate: false,
          ..(if font != auto { (font: font) } else { (:) }),
        )
        set par(justify: false, leading: 0.5em)
        body
      }),
    )
  })
}

// MARK: Component: hộp chữ nhật
#let bpbox(
  body,
  // Cắm mốc để component chú giải neo vào; xem bp-anchor-marks
  anchor: none,
  fill: white,
  stroke: auto,
  text-fill: auto,
  inset: 6pt,
  radius: 2pt,
  width: 100%,
  height: 100%,
  size: 10pt,
  weight: "regular",
  font: auto,
) = {
  let bg = bp-to-color(fill)
  let bd = if stroke == auto { 0.8pt + bp-border(bg) } else { stroke }
  let fg = if text-fill == auto { bp-contrast(bg) } else { bp-to-color(text-fill) }
  block(
    width: width,
    height: height,
    fill: bg,
    stroke: bd,
    radius: radius,
    inset: inset,
    {
    bp-anchor-marks(anchor)
    align(center + horizon, {
      set text(
        fill: fg,
        weight: weight,
        size: size,
        hyphenate: false,
        ..(if font != auto { (font: font) } else { (:) }),
      )
      set par(justify: false, leading: 0.5em)
      body
    })
    },
  )
}

// MARK: Component: dải dọc hai biên
// Hình thang vát nhẹ, chữ xoay 90 độ (đọc từ dưới lên) như sơ đồ SAP.
#let bpvbar(
  body,
  // Cắm mốc để component chú giải neo vào; xem bp-anchor-marks
  anchor: none,
  height: 4cm,
  width: 26pt,
  side: "left",
  fill: luma(35%),
  text-fill: white,
  taper: 5%,
  size: 9pt,
  weight: "regular",
  font: auto,
) = {
  let bg = bp-to-color(fill)
  let pts = if side == "left" {
    ((0%, 0%), (100%, taper), (100%, 100% - taper), (0%, 100%))
  } else {
    ((0%, taper), (100%, 0%), (100%, 100%), (0%, 100% - taper))
  }
  block(width: width, height: height, {
    bp-anchor-marks(anchor)
    place(top + left, polygon(fill: bg, stroke: none, ..pts))
    place(center + horizon, rotate(
      -90deg,
      reflow: false,
      box(width: height - 10pt, align(center, {
        set text(
          fill: bp-to-color(text-fill),
          size: size,
          weight: weight,
          hyphenate: false,
          ..(if font != auto { (font: font) } else { (:) }),
        )
        set par(justify: false, leading: 0.5em)
        body
      })),
    ))
  })
}

// MARK: Helpers: hình dạng
#let bp-shape-fn(name) = {
  if name == "house-down" or name == "management" {
    (body, ..a) => bphouse(body, point: "down", ..a)
  } else if name == "house-up" or name == "support" {
    (body, ..a) => bphouse(body, point: "up", ..a)
  } else if name == "box" {
    (body, ..a) => bpbox(body, ..a)
  } else {
    (body, ..a) => bpstep(body, ..a)
  }
}

// Nhãn/tiêu đề: luôn tắt căn đều hai bên để không bị giãn chữ
#let bp-label(body, size: 1em, weight: "medium") = {
  set par(justify: false, leading: 0.5em)
  text(size: size, weight: weight)[#body]
}

// `left` bị tham số cùng tên của bpmap che mất -> giữ lại tham chiếu ở cấp module
// Giữ center để tất cả các block được căn giữa - dọc (must have)
// Có thể phát triển thêm API để căn chữ trái (chưa cần thiết, nice to have)
#let bp-align-left = center

// Coi các giá trị sau là "không có": none, auto, mảng rỗng, và các chuỗi
// "none" / "null" / "~" / "" (trong YAML, `core: none` là CHUỖI "none"
// chứ không phải giá trị rỗng).
#let bp-empty(v) = {
  if v == none or v == auto { return true }
  if type(v) == str { return lower(v).trim() in ("none", "null", "~", "") }
  if type(v) == array { return v.len() == 0 }
  false
}

// Nhãn: trả về none nếu "rỗng"
#let bp-opt(v) = if bp-empty(v) { none } else { v }

// Mảng khối: trả về () nếu "rỗng"; giá trị đơn lẻ được bọc thành mảng 1 phần tử
#let bp-list(v) = {
  if bp-empty(v) { () } else if type(v) == array { v } else { (v,) }
}

#let bp-is-house(name) = name in ("house-down", "house-up", "management", "support")
#let bp-is-chevron(name) = not bp-is-house(name) and name != "box"

// MARK: Helpers: chuẩn hóa item có toạ độ lưới
// Ngoài các khóa của bpstep, mỗi item còn nhận: row, col, span.
//   thiếu `row` -> cùng hàng với item trước (mặc định hàng 1)
//   thiếu `col` -> nối tiếp ô trống kế tiếp của hàng đó
#let bp-place-items(items) = {
  let out = ()
  let prev-row = 1
  let row-end = (:)
  for it in items {
    let d = if type(it) == dictionary { it } else { (:) }
    let base = bp-normalize(it)
    let row = d.at("row", default: prev-row)
    let span = d.at("span", default: 1)
    let key = str(row)
    let col = d.at("col", default: row-end.at(key, default: 1))
    row-end.insert(key, col + span)
    prev-row = row
    out.push((
      body: base.body,
      fill: base.fill,
      text-fill: base.text-fill,
      stroke: base.stroke,
      row: row,
      col: col,
      span: span,
    ))
  }
  out
}

// MARK: Helpers: lưới các hình
// width: bề rộng thực (length) của vùng vẽ; columns: auto = suy ra từ items
#let bp-shape-grid(
  items,
  width: 100%,
  columns: auto,
  // Tên nhóm mốc neo cho `annotate`; none = không cắm mốc
  anchors: none,
  shape: "chevron",
  fill: white,
  gutter: 4pt,
  row-gutter: 5pt,
  notch: 8pt,
  inset: 6pt,
  peak: 22%,
  size: 9.5pt,
  weight: "regular",
  font: auto,
  min-height: 0pt,
) = {
  let placed = bp-place-items(items)
  if placed.len() == 0 { return none }

  let ncols = if columns == auto or columns == none {
    calc.max(..placed.map(p => p.col + p.span - 1))
  } else { columns }
  let nrows = calc.max(..placed.map(p => p.row))

  let cw = (width - gutter * (ncols - 1)) / ncols
  let chev = bp-is-chevron(shape)
  let house = bp-is-house(shape)
  let pad = 2 * inset + (if chev { 2 * notch } else { 0pt })
  let mk = bp-shape-fn(shape)
  let extra-args = if chev { (notch: notch) } else if house { (peak: peak) } else { (:) }

  context {
    // Chiều cao đồng nhất cho mọi hình = hình cao nhất
    let hs = placed.map(p => {
      let w = p.span * cw + (p.span - 1) * gutter - pad
      measure(block(width: w, {
        set text(
          size: size,
          weight: weight,
          hyphenate: false,
          ..(if font != auto { (font: font) } else { (:) }),
        )
        set par(justify: false, leading: 0.5em)
        align(center, p.body)
      })).height
    })
    let th = calc.max(0pt, ..hs) + 2 * inset
    // Mái nhà chiếm thêm `peak` phần trăm chiều cao -> bù lại để chữ không bị ép
    let hh = if house { th / (1 - peak / 100%) } else { th }
    let hh = calc.max(min-height, hh)

    grid(
      columns: (cw,) * ncols,
      rows: (hh,) * nrows,
      column-gutter: gutter,
      row-gutter: row-gutter,
      ..placed.map(p => grid.cell(
        x: p.col - 1,
        y: p.row - 1,
        colspan: p.span,
        mk(
          p.body,
          anchor: if anchors == none { none } else {
            (
              group: anchors,
              id: p.at("id", default: none),
              name: bp-plain(p.body),
              index: p.row * 100 + p.col,
            )
          },
          fill: if p.fill == auto { fill } else { p.fill },
          stroke: p.stroke,
          text-fill: p.text-fill,
          size: size,
          weight: weight,
          font: font,
          inset: inset,
          ..extra-args,
        ),
      )),
    )
  }
}

// MARK: Helpers: một nhóm trong vùng Cốt lõi
// group: (title | group, label-side, fill, shape, columns, steps | items)
#let bp-core-group(
  group,
  width: 100%,
  columns: auto,
  anchors: none,
  theme: bp-themes.bw,
  label-width: 2.6cm,
  pad: 6pt,
  title-size: 9pt,
  shape-args: (:),
) = {
  let title = group.at("title", default: group.at("group", default: none))
  let side = group.at("label-side", default: if title == none { "none" } else { "top" })
  let g-fill = if "fill" in group {
    if group.fill == none { none } else { bp-to-color(group.fill) }
  } else { theme.group }
  let shape = group.at("shape", default: "chevron")
  let items = group.at("steps", default: group.at("items", default: ()))
  let cols = group.at("columns", default: columns)

  let inner-w = width - 2 * pad
  let body = if side == "left" {
    let sw = inner-w - label-width - 6pt
    grid(
      columns: (label-width, sw),
      column-gutter: 6pt,
      align: (left + horizon, left + horizon),
      bp-label(title, size: title-size),
      bp-shape-grid(items, width: sw, columns: cols, shape: shape, fill: theme.shape, anchors: anchors, ..shape-args),
    )
  } else {
    stack(
      dir: ttb,
      spacing: 5pt,
      ..(if side == "top" and title != none {
        (bp-label(title, size: title-size),)
      } else { () }),
      bp-shape-grid(items, width: inner-w, columns: cols, shape: shape, fill: theme.shape, anchors: anchors, ..shape-args),
    )
  }

  block(
    width: width,
    fill: g-fill,
    inset: if g-fill == none { 0pt } else { pad },
    radius: 2pt,
    body,
  )
}

// MARK: Component: bản đồ quy trình
#let bpmap(
  // Tên nhóm mốc neo cho `annotate`; none = không cắm mốc
  anchors: none,
  // Ba nhóm quy trình. `core` là mảng nhóm hoặc mảng item (một nhóm ngầm).
  management: (),
  core: (),
  support: (),
  // Dải dọc hai biên (none = không vẽ)
  left: none,
  right: none,
  // Chỉ hiển thị một/vài khối: "management" | "core" | "support" (hoặc mảng)
  only: none,
  // Ép hiện/ẩn hai dải biên: auto = hiện nếu có `left`/`right` và có vùng Cốt lõi
  bars: auto,
  // Tiêu đề từng dải (none = ẩn)
  management-title: "Quy Trình Quản Lý",
  core-title: "Quy Trình Cốt Lõi",
  support-title: "Quy Trình Hỗ Trợ",
  // Số cột lưới dùng chung cho vùng Cốt lõi (auto = suy ra từ dữ liệu)
  columns: auto,
  // Giao diện
  theme: "bw",
  bar-width: 26pt,
  band-inset: 7pt,
  group-pad: 6pt,
  gutter: 5pt,
  label-width: 2.6cm,
  // Tham số hình học chuyển tiếp cho các khối
  size: 9.5pt,
  title-size: 9pt,
  weight: "regular",
  notch: 8pt,
  inset: 6pt,
  peak: 22%,
  shape-gutter: 4pt,
  row-gutter: 5pt,
  font: auto,
) = context layout(avail => {
  let th = if type(theme) == str { bp-themes.at(theme) } else { theme }

  // --- Chuẩn hóa đầu vào ---
  let keep = if only == none { none } else if type(only) == str { (only,) } else { only }
  let want = k => keep == none or k in keep

  let mgmt-items = if want("management") { bp-list(management) } else { () }
  let core-items = if want("core") { bp-list(core) } else { () }
  let supp-items = if want("support") { bp-list(support) } else { () }
  let left-lbl = bp-opt(left)
  let right-lbl = bp-opt(right)

  let has-core = core-items.len() > 0
  // Không có vùng Cốt lõi thì hai dải biên cũng không còn chỗ bám
  let has-bars = has-core and (if bars == auto {
    left-lbl != none or right-lbl != none
  } else { bars and (left-lbl != none or right-lbl != none) })

  let bw = if has-bars { bar-width } else { 0pt }
  let side-w = if has-bars { bw + gutter } else { 0pt }

  let sargs = (
    size: size,
    weight: weight,
    font: font,
    notch: notch,
    inset: inset,
    peak: peak,
    gutter: shape-gutter,
    row-gutter: row-gutter,
  )

  // Bề rộng vùng giữa và vùng vẽ bên trong
  let mid-w = avail.width - 2 * side-w
  let inner-w = mid-w - 2 * band-inset

  // --- Vùng Cốt lõi ---
  let groups = if has-core and type(core-items.at(0)) == dictionary and (
    "steps" in core-items.at(0) or "items" in core-items.at(0) or "group" in core-items.at(0)
  ) { core-items } else { ((steps: core-items),) }

  let core-body = stack(
    dir: ttb,
    spacing: gutter,
    ..groups.map(g => bp-core-group(
      anchors: anchors,
      g,
      width: inner-w,
      columns: columns,
      theme: th,
      label-width: label-width,
      pad: group-pad,
      title-size: title-size,
      shape-args: sargs,
    )),
  )

  let core-band = if not has-core { none } else { block(
    width: mid-w,
    fill: th.core,
    stroke: 0.8pt + th.line,
    inset: band-inset,
    radius: 2pt,
    stack(
      dir: ttb,
      spacing: 5pt,
      ..(if core-title != none { (bp-label(core-title, size: title-size),) } else { () }),
      core-body,
    ),
  ) }

  // Chiều cao thực của dải Cốt lõi -> kéo dài hai dải dọc cho khớp
  let core-h = if has-core { measure(core-band).height } else { 0pt }

  // --- Dải Quản lý / Hỗ trợ ---
  let band(items, title, shape) = if items.len() == 0 { none } else {
    block(
      width: mid-w,
      fill: th.band,
      stroke: 0.8pt + th.line,
      inset: band-inset,
      radius: 2pt,
      stack(
        dir: ttb,
        spacing: 5pt,
        ..(if title != none { (bp-label(title, size: title-size),) } else { () }),
        bp-shape-grid(items, width: inner-w, shape: shape, fill: th.shape, anchors: anchors, ..sargs),
      ),
    )
  }

  let mgmt = band(mgmt-items, management-title, "house-down")
  let supp = band(supp-items, support-title, "house-up")

  let middle = if not has-core { none } else if has-bars {
      grid(
        columns: (bw, mid-w, bw),
        column-gutter: gutter,
        align: horizon,
        if left-lbl != none {
          bpvbar(
            left-lbl,
            height: core-h,
            width: bw,
            side: "left",
            fill: th.accent,
            text-fill: th.accent-text,
            size: size - 0.5pt,
            font: font,
          )
        } else { none },
        core-band,
        if right-lbl != none {
          bpvbar(
            right-lbl,
            height: core-h,
            width: bw,
            side: "right",
            fill: th.accent,
            text-fill: th.accent-text,
            size: size - 0.5pt,
            font: font,
          )
        } else { none },
      )
  } else { core-band }

  let blocks = ((mgmt, middle, supp)).filter(b => b != none)
  if blocks.len() == 0 { return }

  // `figure` căn giữa nội dung -> ép căn trái để tiêu đề dải không bị lệch
  block(width: 100%, breakable: false, align(bp-align-left, stack(dir: ttb, spacing: gutter, ..blocks)))
})

// MARK: Wrapper: dựng từ dữ liệu đã nạp
// Khóa hiểu được: management, core, support, left, right, caption, label, options
#let bpmap-data(data, ..args) = {
  if type(data) != dictionary { return bpmap(core: data, ..args) }

  let named = data.at("options", default: (:)) + args.named()

  let caption = named.at("caption", default: data.at("caption", default: none))
  let lbl = named.at("label", default: data.at("label", default: none))
  for k in ("caption", "label", "title") {
    if k in named { let _ = named.remove(k) }
  }
  for k in ("management", "core", "support", "left", "right", "only", "bars") {
    if k in data and k not in named { named.insert(k, data.at(k)) }
  }

  let out = if caption != none {
    figure(bpmap(..named), caption: caption, kind: image, supplement: "Hình ảnh")
  } else {
    bpmap(..named)
  }

  if lbl != none { [#out #label(lbl)] } else { out }
}

// MARK: Wrapper: nạp và dựng trong một lệnh
// LƯU Ý: đường dẫn tuyệt đối từ gốc project ("/content/processes/x.yaml").
#let bpmap-file(path, id: none, ..args) = bpmap-data(load-steps(path, id: id), ..args)
