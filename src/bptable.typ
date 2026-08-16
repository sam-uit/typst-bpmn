// /template/components/bptable.typ
// Business Process Table — Danh mục quy trình nghiệp vụ dưới dạng bảng:
//   mỗi dòng là một quy trình, các cột là Tên / Tác Nhân / Khách Hàng /
//   Kết Quả / Mô Tả Các Bước.
//
// Dữ liệu lấy từ cùng thư mục `content/processes/` với `bpstep` và `bpmap`.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - bptable(processes, ..)  : Bảng danh mục quy trình (không có caption).
//   - bptable-data(data, ..)  : Dựng figure từ dict đã nạp (caption, label).
//   - bptable-file(path, ..)  : Nạp YAML/JSON rồi dựng, một lệnh.

#import "bpstep.typ": load-steps

// MARK: Helpers — nội dung một ô
// Giá trị trong YAML có thể là chuỗi hoặc mảng:
//   - `sep != none`  -> nối các phần tử bằng dấu phân cách (mũi tên cho cột Các Bước)
//   - mảng 1 phần tử -> in thẳng, không cần gạch đầu dòng
//   - mảng nhiều     -> danh sách gạch đầu dòng, thụt lề tối thiểu cho vừa ô hẹp
#let bptable-cell(value, sep: none, indent: 0pt, body-indent: 0.4em) = {
  let items = if type(value) == array { value } else { (value,) }
  let items = items.filter(it => it != none and it != "")
  if items.len() == 0 { return [] }

  if sep != none {
    items.map(it => [#it]).join(sep)
  } else if items.len() == 1 {
    [#items.first()]
  } else {
    set list(indent: indent, body-indent: body-indent, spacing: 0.5em, marker: [--])
    list(..items.map(it => [#it]))
  }
}

// MARK: Component — bảng danh mục quy trình
#let bptable(
  processes,
  // Bề rộng từng cột
  columns: (16%, 20%, 20%, 20%, 24%),
  // Tiêu đề các cột
  headers: ("Tên", "Tác Nhân", "Khách Hàng", "Kết Quả", "Mô Tả Các Bước"),
  // Khóa YAML tương ứng với từng cột (cùng thứ tự với `headers`)
  fields: ("name", "actors", "customers", "outcomes", "steps"),
  // Các cột nối bằng mũi tên thay vì gạch đầu dòng
  flow-fields: ("steps",),
  arrow: [ $->$ ],
  cell-align: left,
  inset: 0.5em,
  size: 10pt,
  // In đậm cột đầu tiên (tên quy trình)
  strong-first: true,
) = {
  if processes.len() == 0 { return }

  let cells = processes
    .map(p => fields
      .enumerate()
      .map(((i, f)) => {
        let cell = bptable-cell(
          p.at(f, default: ()),
          sep: if f in flow-fields { arrow } else { none },
        )
        if strong-first and i == 0 { strong(cell) } else { cell }
      }))
    .flatten()

  set text(size: size)
  // Không cắt một quy trình làm đôi khi bảng tràn trang
  set table.cell(breakable: false)
  table(
    columns: columns,
    align: cell-align,
    inset: inset,
    // table.header tự lặp lại khi bảng tràn sang trang mới
    table.header(..headers.map(h => strong(h))),
    ..cells,
  )
}

// MARK: Wrapper — dựng từ dữ liệu đã nạp
// Khóa hiểu được: processes, caption, label, options (dict tham số của bptable).
// Tham số truyền trực tiếp luôn ghi đè `options` trong file dữ liệu.
#let bptable-data(data, ..args) = {
  let dict = type(data) == dictionary
  let processes = if dict { data.at("processes", default: ()) } else { data }
  let named = (if dict { data.at("options", default: (:)) } else { (:) }) + args.named()

  let caption = named.at("caption", default: if dict { data.at("caption", default: none) } else { none })
  let lbl = named.at("label", default: if dict { data.at("label", default: none) } else { none })
  // Cho phép bảng tràn sang nhiều trang
  let breakable = named.at("breakable", default: true)
  for k in ("caption", "label", "title", "breakable") {
    if k in named { let _ = named.remove(k) }
  }

  let out = if caption != none {
    show figure: set block(breakable: breakable)
    figure(
      bptable(processes, ..named),
      // TODO: parser supports en-dash (--) and em-dash (---)
      caption: caption,
      kind: table,
      supplement: "Bảng",
    )
  } else {
    bptable(processes, ..named)
  }

  if lbl != none { [#out #label(lbl)] } else { out }
}

// MARK: Wrapper — nạp và dựng trong một lệnh
// LƯU Ý: đường dẫn tuyệt đối từ gốc project ("/content/processes/x.yaml").
#let bptable-file(path, id: none, ..args) = bptable-data(load-steps(path, id: id), ..args)
