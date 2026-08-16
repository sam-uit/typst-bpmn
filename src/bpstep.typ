// /template/components/bpstep.typ
// Business Process Step — trực quan hóa chuỗi các bước của một quy trình
// bằng các khối mũi tên (chevron) vẽ trực tiếp bằng Typst visualize.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - bpstep(body, ..)      : Một khối chevron đơn lẻ.
//   - bpflow(steps, ..)     : Chuỗi các bước (tự động xuống dòng).
//   - bpflow-figure(..)     : bpflow bọc trong figure (có caption, vào Danh Sách Hình Ảnh).
//   - load-steps(path)      : Đọc steps từ .yaml / .json / .csv (đường dẫn tuyệt đối "/content/...").
//   - bp-palettes           : Từ điển các bảng màu dựng sẵn.

// MARK: Palettes
// Mỗi palette là một mảng màu, được lặp vòng nếu số bước nhiều hơn số màu.
#import "bptext.typ": bp-text, bp-smart, bp-flatten, bp-same-text

#let bp-palettes = (
  // Bảng màu mặc định, kiểu Google Slides / Office SmartArt
  pastel: (
    rgb("#f2f2f2"),
    rgb("#ffffff"),
    rgb("#cfe2f3"),
    rgb("#d9ead3"),
    rgb("#fce5cd"),
    rgb("#fff2cc"),
    rgb("#f4cccc"),
    rgb("#e6d7f0"),
    rgb("#d0e0e3"),
  ),
  // Đơn sắc xanh dương, đậm dần
  blue: (
    rgb("#eaf2fb"),
    rgb("#d6e6f7"),
    rgb("#c2daf3"),
    rgb("#adceef"),
    rgb("#99c2eb"),
    rgb("#84b6e7"),
    rgb("#70aae3"),
    rgb("#5b9edf"),
  ),
  // Đơn sắc xanh ngọc
  teal: (
    rgb("#e6f4f3"),
    rgb("#cdeae7"),
    rgb("#b3dfdb"),
    rgb("#9ad5cf"),
    rgb("#80cac3"),
    rgb("#67c0b7"),
    rgb("#4db5ab"),
  ),
  // Trung tính (in trắng đen vẫn rõ)
  mono: (
    rgb("#ffffff"),
    rgb("#f2f2f2"),
    rgb("#e6e6e6"),
    rgb("#d9d9d9"),
    rgb("#cccccc"),
    rgb("#bfbfbf"),
    rgb("#b3b3b3"),
  ),
  // Ấm: vàng -> cam -> đỏ
  warm: (
    rgb("#fff8e1"),
    rgb("#ffecb3"),
    rgb("#ffe082"),
    rgb("#ffd54f"),
    rgb("#ffb74d"),
    rgb("#ff8a65"),
    rgb("#e57373"),
  ),
)

// MARK: Helpers — màu
// Sinh dải màu tự động bằng cách xoay tông (hue) trong không gian OKLCH.
// Cho ra n màu pastel, độ sáng đồng đều -> chữ đen luôn đọc được.
#let bp-auto-colors(n, start-hue: 210deg, spread: 300deg, lightness: 90%, chroma: 0.055) = {
  if n <= 0 { return () }
  range(n).map(i => oklch(
    lightness,
    chroma,
    start-hue + spread * (i / calc.max(n, 1)),
  ))
}

// Độ sáng tương đối của một màu (0 = đen, 1 = trắng), dùng để chọn màu chữ.
#let bp-luminance(c) = {
  let (r, g, b) = c.rgb().components(alpha: false)
  let f = v => {
    let x = v / 100%
    if x <= 0.03928 { x / 12.92 } else { calc.pow((x + 0.055) / 1.055, 2.4) }
  }
  0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
}

// Chọn màu chữ tương phản với nền.
#let bp-contrast(c, dark: black, light: white) = {
  if bp-luminance(c) > 0.45 { dark } else { light }
}

// Màu viền mặc định: đậm hơn nền một chút.
#let bp-border(c) = {
  if bp-luminance(c) > 0.92 { luma(60%) } else { c.darken(35%).saturate(20%) }
}

// MARK: Helpers — chuẩn hóa dữ liệu
// Một "step" có thể là:
//   - string / content                        -> chỉ có nhãn
//   - dict: (text|title|label|name, color|fill, text-color, stroke, note)
// Trả về dict chuẩn: (body, fill, text-fill, stroke, note)
//
// `mode` quyết định chuỗi được gửi tới engine thế nào — xem `bptext.typ`. Mặc định
// "markup", vì dữ liệu ở đây do chính người viết tài liệu gõ: họ muốn "2--3" ra
// en-dash và "$->$" ra mũi tên.
#let bp-normalize(step, mode: "markup") = {
  if type(step) == dictionary {
    let keys = ("text", "title", "label", "name", "step", "body")
    let body = none
    for k in keys {
      if body == none and k in step { body = step.at(k) }
    }
    (
      body: if body == none { [] } else { bp-text(body, mode: mode) },
      fill: if "color" in step { step.color } else if "fill" in step { step.fill } else { auto },
      text-fill: if "text-color" in step { step.text-color } else if "text-fill" in step {
        step.text-fill
      } else { auto },
      stroke: if "stroke" in step { step.stroke } else { auto },
      note: if "note" in step { bp-text(step.note, mode: mode) } else { none },
      id: if "id" in step { step.id } else { none },
    )
  } else if type(step) == array {
    // Hàng từ CSV: (nhãn,) hoặc (nhãn, màu)
    (
      body: bp-text(step.at(0, default: ""), mode: mode),
      fill: if step.len() > 1 and step.at(1) != "" { step.at(1) } else { auto },
      text-fill: auto,
      stroke: auto,
      note: none,
      id: none,
    )
  } else {
    (body: bp-text(step, mode: mode), fill: auto, text-fill: auto, stroke: auto, note: none, id: none)
  }
}

// Rút văn bản thuần của một bước, để `annotate` neo được theo tên thay vì theo id.
// Đi đệ quy qua content (sequence, styled, box...) để lấy được cả nhãn nhiều mảnh.
#let bp-plain = bp-flatten

// Ép về màu: chấp nhận chuỗi hex ("#cfe2f3") hoặc color.
#let bp-to-color(c) = if type(c) == str { rgb(c) } else { c }

// MARK: Loader
// Đọc một quy trình từ file dữ liệu trong `content/processes/`.
//
// LƯU Ý QUAN TRỌNG: luôn dùng đường dẫn tuyệt đối tính từ gốc project
// ("/content/processes/x.yaml"), vì đường dẫn tương đối sẽ được Typst tính
// theo vị trí của FILE NÀY chứ không phải file gọi nó.
//
// YAML/JSON hỗ trợ 3 dạng:
//   1) Mảng ở cấp cao nhất:      - Bước 1
//                                - Bước 2
//   2) Một quy trình:            title: ...
//                                caption: ...
//                                steps: [...]
//   3) Nhiều quy trình / file:   processes:
//                                  ql-khuyen-mai:
//                                    title: ...
//                                    steps: [...]
//      -> chọn bằng: load-steps("/content/processes/x.yaml", id: "ql-khuyen-mai")
#let load-steps(path, id: none) = {
  let raw = if path.ends-with(".yaml") or path.ends-with(".yml") {
    yaml(path)
  } else if path.ends-with(".json") {
    json(path)
  } else if path.ends-with(".csv") {
    csv(path)
  } else {
    panic("bpstep: không hỗ trợ định dạng của " + path)
  }

  let data = if type(raw) == dictionary {
    raw
  } else if type(raw) == array and path.ends-with(".csv") {
    // Bỏ dòng header nếu có
    let rows = raw
    if rows.len() > 0 and lower(rows.at(0).at(0, default: "")).trim() in ("step", "bước", "buoc", "title") {
      rows = rows.slice(1)
    }
    (steps: rows)
  } else {
    (steps: raw)
  }

  // Chọn một quy trình cụ thể trong file nhiều quy trình
  if id != none {
    let pool = data.at("processes", default: data)
    if type(pool) == dictionary and id in pool {
      data = pool.at(id)
    } else if type(pool) == array {
      let hit = pool.filter(p => type(p) == dictionary and p.at("id", default: none) == id)
      if hit.len() == 0 { panic("bpstep: không tìm thấy quy trình '" + id + "' trong " + path) }
      data = hit.first()
    } else {
      panic("bpstep: không tìm thấy quy trình '" + id + "' trong " + path)
    }
  }

  data
}

// MARK: Component — một bước đơn lẻ
// Vẽ khối chevron (mũi tên) với nội dung căn giữa.
// `notch` là độ sâu của mũi nhọn; `flat-start`/`flat-end` cắt phẳng đầu/đuôi.
// MARK: Mốc neo cho chú giải
// Sơ đồ BPMN có toạ độ tuyệt đối trong dữ liệu; bpstep/bpmap thì không — vị trí do `grid`
// của Typst quyết định lúc dàn trang. Nên mỗi khối tự cắm hai mốc vô hình (góc trên-trái và
// góc dưới-phải) mang theo metadata; `annotate` truy vấn lại bằng `query(<bp-anchor>)` rồi
// suy ra chữ nhật của khối. Mốc rỗng và đặt bằng `place` nên không ảnh hưởng bố cục.
//
// `anchor` là dict (group, id, name) hoặc `none` để tắt.
#let bp-anchor-marks(anchor) = {
  if anchor == none { return }
  place(top + left, [#metadata(anchor + (corner: "tl")) <bp-anchor>])
  // Dùng dx/dy 100% chứ không dùng `place(bottom + right, ..)`: căn theo `bottom` khiến
  // container đòi trọn chiều cao trang, một cạm bẫy quen thuộc của Typst.
  place(top + left, dx: 100%, dy: 100%, [#metadata(anchor + (corner: "br")) <bp-anchor>])
}

#let bpstep(
  body,
  // Cắm mốc để component chú giải neo vào; xem bp-anchor-marks
  anchor: none,
  fill: white,
  stroke: auto,
  text-fill: auto,
  notch: 8pt,
  radius: 2pt,
  inset: 6pt,
  flat-start: false,
  flat-end: false,
  width: 100%,
  height: 100%,
  weight: "bold",
  size: 10pt,
  font: auto,
) = {
  let bg = bp-to-color(fill)
  let bd = if stroke == auto { 1pt + bp-border(bg) } else { stroke }
  let fg = if text-fill == auto { bp-contrast(bg) } else { bp-to-color(text-fill) }

  // Đỉnh của đa giác, dùng toạ độ tương đối để tự co giãn theo ô lưới.
  let pts = (
    (0pt, 0%),
    (if flat-end { 100% } else { 100% - notch }, 0%),
    (100%, 50%),
    (if flat-end { 100% } else { 100% - notch }, 100%),
    (0pt, 100%),
  )
  // Khuyết ở cạnh trái (để khớp với mũi nhọn của bước trước)
  let pts = if flat-start { pts } else { pts + ((notch, 50%),) }

  block(
    width: width,
    height: height,
    radius: radius,
    clip: false,
    {
      bp-anchor-marks(anchor)
      // Nền: hình chevron vẽ bằng visualize
      place(top + left, polygon(fill: bg, stroke: bd, ..pts))
      // Nội dung: căn giữa, chừa chỗ cho mũi nhọn hai bên
      block(
        width: 100%,
        height: 100%,
        inset: (
          left: inset + (if flat-start { 0pt } else { notch }),
          right: inset + (if flat-end { 0pt } else { notch }),
          y: inset,
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
    },
  )
}

// MARK: Component — chuỗi các bước
#let bpflow(
  steps,
  // Số bước tối đa trên một hàng; auto = tất cả trên một hàng.
  per-row: 6,
  // Bảng màu: tên trong bp-palettes, một mảng màu, hoặc "auto" (xoay tông).
  palette: "pastel",
  // Ép màu cho bước đầu / bước cuối (auto = theo palette).
  start-color: auto,
  end-color: auto,
  // Hình học
  notch: 8pt,
  gutter: 3pt,
  row-gutter: 6pt,
  inset: 6pt,
  radius: 2pt,
  flat-start: false,
  flat-end: false,
  // Chữ
  size: 10pt,
  weight: "bold",
  font: auto,
  // Đánh số bước: none | "B" | "Bước " | hàm i => content
  numbering: none,
  // Khung ngoài + tiêu đề (như sơ đồ mẫu)
  title: none,
  frame: true,
  frame-fill: white,
  frame-stroke: 0.8pt + luma(60%),
  // Chiều cao tối thiểu của mỗi khối
  min-height: 0pt,
  // Tên nhóm mốc neo cho `annotate`; none = không cắm mốc.
  // Mỗi bước có id = `id` trong dữ liệu, hoặc nhãn số thứ tự ("B3"), hoặc số thứ tự.
  anchors: none,
) = {
  let items = steps.map(bp-normalize)
  let n = items.len()
  if n == 0 { return }

  // --- Bảng màu ---
  let base = if palette == "auto" or palette == auto {
    bp-auto-colors(n)
  } else if type(palette) == str {
    if palette in bp-palettes { bp-palettes.at(palette) } else {
      panic("bpstep: không có palette '" + palette + "'")
    }
  } else if type(palette) == array {
    palette.map(bp-to-color)
  } else {
    bp-palettes.pastel
  }

  let colors = range(n).map(i => {
    let c = items.at(i).fill
    if c != auto {
      bp-to-color(c)
    } else if i == 0 and start-color != auto {
      bp-to-color(start-color)
    } else if i == n - 1 and end-color != auto {
      bp-to-color(end-color)
    } else {
      base.at(calc.rem(i, base.len()))
    }
  })

  // --- Nhãn số thứ tự ---
  let label-of = i => {
    if numbering == none {
      none
    } else if type(numbering) == function {
      numbering(i + 1)
    } else {
      text(size: 0.8em, weight: "regular")[#numbering#(i + 1)]
    }
  }

  // Nội dung hoàn chỉnh của một bước (nhãn + tiêu đề)
  let content-of = i => {
    let it = items.at(i)
    let lbl = label-of(i)
    if lbl == none { it.body } else {
      stack(dir: ttb, spacing: 1em,
        lbl,
        // v(1fr),
        it.body,
        v(1fr),
      )
    }
  }

  // Mốc neo: ưu tiên `id` trong dữ liệu, rồi nhãn số thứ tự ("B3"), cuối cùng là số thứ tự.
  // `name` giữ nguyên văn bản của bước để `annotate` neo được theo tên, khỏi phải nhớ id.
  let anchor-of = i => {
    if anchors == none { return none }
    let it = items.at(i)
    let id = it.at("id", default: none)
    let id = if id != none { id } else if type(numbering) == str and numbering != "" {
      numbering + str(i + 1)
    } else { str(i + 1) }
    (group: anchors, id: id, name: bp-plain(it.body), index: i + 1)
  }

  let cols = if per-row == auto or per-row == none { n } else { calc.min(per-row, n) }
  let rows = calc.ceil(n / cols)

  let diagram = context layout(avail => {
    // Bề rộng một cột
    let col-w = (avail.width - gutter * (cols - 1)) / cols
    // Bề rộng vùng chữ bên trong (trừ inset và mũi nhọn hai bên)
    let text-w = col-w - 2 * inset - 2 * notch

    // Chiều cao đồng nhất cho mọi khối = khối cao nhất
    let heights = range(n).map(i => measure(
      block(width: text-w, {
        set text(
          size: size,
          weight: weight,
          hyphenate: false,
          ..(if font != auto { (font: font) } else { (:) }),
        )
        set par(justify: false, leading: 0.5em)
        align(center, content-of(i))
      }),
    ).height)
    let h = calc.max(min-height, ..heights) + 2 * inset

    stack(
      dir: ttb,
      spacing: row-gutter,
      ..range(rows).map(r => {
        let lo = r * cols
        let hi = calc.min(lo + cols, n)
        grid(
          columns: (col-w,) * cols,
          column-gutter: gutter,
          rows: (h,),
          ..range(lo, hi).map(i => bpstep(
            content-of(i),
            anchor: anchor-of(i),
            fill: colors.at(i),
            stroke: items.at(i).stroke,
            text-fill: items.at(i).text-fill,
            notch: notch,
            radius: radius,
            inset: inset,
            flat-start: flat-start and i == 0,
            flat-end: flat-end and i == n - 1,
            size: size,
            weight: weight,
            font: font,
          )),
        )
      }),
    )
  })

  if frame {
    block(
      width: 100%,
      fill: frame-fill,
      stroke: frame-stroke,
      inset: 8pt,
      radius: 4pt,
      breakable: false,
      {
        if title != none {
          block(
            width: 100%,
            fill: luma(96%),
            stroke: 0.8pt + luma(60%),
            inset: 5pt,
            radius: 4pt,
            below: 8pt,
            align(center, text(style: "normal", size: 0.95em)[#title]),
          )
        }
        diagram
      },
    )
  } else {
    block(width: 100%, breakable: false, diagram)
  }
}

// MARK: Wrapper — bpflow trong figure (có caption + vào Danh Sách Hình Ảnh)
#let bpflow-figure(steps, caption: none, ..args) = figure(
  bpflow(steps, ..args),
  caption: caption,
  kind: image,
  supplement: "Hình ảnh",
)

// MARK: Wrapper — dựng thẳng từ dữ liệu đã nạp
// data: kết quả của load-steps(), hoặc bất kỳ dict nào có khóa `steps`.
// Các khóa được hiểu: steps, title, caption, label, options (dict tham số của bpflow).
// Tham số truyền trực tiếp luôn ghi đè `options` trong file dữ liệu.
#let bpflow-data(data, ..args) = {
  let dict = type(data) == dictionary
  let steps = if dict { data.at("steps", default: ()) } else { data }
  let opts = if dict { data.at("options", default: (:)) } else { (:) }
  let named = opts + args.named()

  let title = named.at("title", default: if dict { data.at("title", default: none) } else { none })
  let caption = named.at("caption", default: if dict { data.at("caption", default: none) } else { none })
  let lbl = named.at("label", default: if dict { data.at("label", default: none) } else { none })
  // Loại các khóa không phải tham số của bpflow
  for k in ("caption", "label") {
    if k in named { let _ = named.remove(k) }
  }
  named.insert("title", title)

  let out = if caption != none {
    figure(bpflow(steps, ..named), caption: caption, kind: image, supplement: "Hình ảnh")
  } else {
    bpflow(steps, ..named)
  }

  if lbl != none { [#out #label(lbl)] } else { out }
}

// MARK: Wrapper — nạp và dựng trong một lệnh
// bpflow-file("/content/processes/ql-khuyen-mai.yaml")
#let bpflow-file(path, id: none, ..args) = bpflow-data(load-steps(path, id: id), ..args)
