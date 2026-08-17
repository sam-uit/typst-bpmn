// /template/components/whywhy.typ
// Why-Why (5 Whys) — chuỗi truy vấn nguyên nhân gốc rễ, dựng từ một file dữ liệu.
//
// Lý do component này tồn tại không phải là phần trình bày — một danh sách lồng nhau
// viết tay cũng ra đúng chừng đó chữ. Lý do là **cùng một chuỗi đang được dùng ở hai
// chỗ**: danh sách trong văn bản, và các ô chú giải trên sơ đồ BPMN. Hai bản chép tay
// thì sớm muộn lệch nhau. Ở đây chỉ có một file, hai cách đọc.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - whywhy(data, ..)        : Dựng phần trình bày từ dict đã nạp.
//   - whywhy-file(path, ..)   : Nạp YAML/JSON rồi dựng, một lệnh.
//   - whywhy-notes(data, ..)  : Trả về mảng `notes:` để đưa cho `bpmn-lane`/`bpmn-part`/
//                               `bpmn-span` (hoặc `bpmn-notes`). Gộp các tầng liền nhau
//                               cùng `node` thành một ô.
//   - ww-load(path)           : Chỉ nạp dữ liệu, không dựng.
//
// Lược đồ dữ liệu (xem `content/analysis/wh-ch03-bao-hanh.yaml`):
//
//   problem: <câu mô tả vấn đề>
//   whys:
//     - ask:     <câu hỏi "Tại sao ...?">
//       because: <câu trả lời>
//       node:    <id phần tử BPMN>     # tuỳ chọn — chỉ cần khi muốn có chú giải
//       note:    <câu rút gọn cho ô chú giải>   # tuỳ chọn — bỏ trống thì lấy `because`
//       side/dx/dy/color/width:                # tuỳ chọn — ép chỗ đặt của riêng ô này
//   root: <nguyên nhân gốc rễ>          # tuỳ chọn — bỏ trống thì lấy `because` cuối

// MARK: Nạp dữ liệu
#import "bptext.typ": bp-text

#let ww-load(path) = {
  let raw = if path.ends-with(".yaml") or path.ends-with(".yml") {
    yaml(path)
  } else if path.ends-with(".json") {
    json(path)
  } else {
    panic("whywhy: chỉ đọc được .yaml/.yml/.json, nhận: " + path)
  }
  if type(raw) != dictionary {
    panic("whywhy: file dữ liệu phải là một dict có khoá `whys`")
  }
  if "whys" not in raw {
    panic("whywhy: thiếu khoá `whys` trong " + path)
  }
  raw
}

// Chấp nhận cả dict đã nạp lẫn đường dẫn, để chỗ gọi không phải nhớ dùng hàm nào.
#let ww-data(src) = if type(src) == str { ww-load(src) } else { src }

// MARK: Nhãn tầng
// Một tầng là "Why 3"; nhiều tầng liền nhau gộp lại là "Why 2–3".
//
// Gạch nối viết thẳng bằng ký tự en-dash, không phải "--". Chuỗi này do *code* dựng
// nên nó không bao giờ đi qua bộ phân tích cú pháp của Typst, mà "--" -> en-dash là
// việc của bộ phân tích. Viết "--" ở đây thì in ra đúng hai dấu gạch — và đó là lỗi
// im lặng, vì phần thân của ô chú giải (do người viết gõ, có qua `bp-text`) lại ra
// en-dash thật, nên hai nửa của cùng một ô hiện hai kiểu gạch khác nhau.
#let ww-label(from, to, word: "Why") = {
  if from == to { word + " " + str(from) } else {
    word + " " + str(from) + "\u{2013}" + str(to)
  }
}

// MARK: Trình bày — danh sách lồng
// Giữ đúng hình dạng đang dùng ở chương 3: một mục "Vấn đề", bên dưới là n cặp
// câu hỏi -> nguyên nhân. Đổi cách vẽ (bảng, chuỗi mũi tên) thì sửa ở đây, mọi chỗ
// dùng được hưởng theo — đó là điểm của việc tách dữ liệu ra.
#let whywhy(
  src,
  // Nhãn của mỗi tầng; đổi khi tài liệu viết bằng ngôn ngữ khác
  word: "Why",
  problem-label: [*Vấn đề:*],
  root-label: [*Nguyên nhân gốc rễ:*],
  // Hiện dòng kết luận cuối. `auto` = hiện nếu dữ liệu khai `root`.
  show-root: auto,
  spacing: 0.5em,
) = {
  let data = ww-data(src)
  let whys = data.at("whys", default: ())
  let root = data.at("root", default: none)
  let with-root = if show-root == auto { root != none } else { show-root }

  set list(spacing: spacing, marker: ([--], [•]))

  list(
    list.item[
      #problem-label #bp-text(data.at("problem", default: ""))
      #list(
        ..whys
          .enumerate()
          .map(((i, w)) => list.item[
            #emph(ww-label(i + 1, i + 1, word: word) + ":") #w.at("ask", default: "")
            #list(list.item[#bp-text(w.at("because", default: ""))])
          ]),
      )
    ],
  )

  // `block` chứ không phải nội dung trần: một dòng trần sẽ dính vào đoạn văn ngay sau
  // component, làm kết luận trông như phần mở đầu của đoạn kế tiếp.
  if with-root and root != none {
    block(above: 0.6em, below: 0.6em)[#root-label #root]
  }
}

#let whywhy-file(path, ..args) = whywhy(ww-load(path), ..args)

// MARK: Chú giải cho sơ đồ BPMN
// Một phần tử chỉ nên mang một ô chú giải, mà nhiều tầng nguyên nhân thường dồn vào
// cùng một phần tử. Nên: các tầng **liền nhau** cùng `node` được gộp thành một ô,
// nhãn ghi khoảng ("Why 2--3"). Tầng không khai `node` thì bỏ qua — nó vẫn nằm trong
// danh sách phân tích, chỉ là không neo được vào sơ đồ.
//
// `note` thắng `because` vì ô chú giải hẹp: câu trong văn bản thường quá dài để đặt
// cạnh một shape. Khi gộp nhiều tầng, lấy `note` đầu tiên có khai trong nhóm.
#let whywhy-notes(
  src,
  word: "Why",
  // Chèn thêm khoá cho mọi ô: (side: "top"), (color: red), (width: 40mm)...
  ..extra,
) = {
  let data = ww-data(src)
  let whys = data.at("whys", default: ())
  let common = extra.named()

  // Khoá đặt chỗ được phép khai ngay trong file dữ liệu, cho từng tầng một.
  //
  // Vì sao để ở đó chứ không ở chỗ gọi: `..extra` áp cho *mọi* ô, mà thường chỉ một ô
  // cần ép. Mà ô nào cần ép thì lý do nằm ở chính nội dung nó — "câu này dài, đặt lên
  // trên kẻo che nhãn của sự kiện hẹn giờ" — nên nó thuộc về file phân tích, cạnh câu
  // chữ, chứ không phải nằm rải trong chương.
  let placement = ("side", "dx", "dy", "color", "width")
  let pick(w) = {
    let out = (:)
    for k in placement { if k in w { out.insert(k, w.at(k)) } }
    out
  }

  // Gom thành các nhóm liền kề cùng node
  let groups = ()
  for (i, w) in whys.enumerate() {
    let node = w.at("node", default: none)
    if node == none { continue }
    let text = w.at("note", default: none)
    if groups.len() > 0 and groups.last().node == node and groups.last().to == i {
      let g = groups.last()
      groups.at(groups.len() - 1) = (
        node: node,
        from: g.from,
        to: i + 1,
        text: if g.text != none { g.text } else { text },
        because: g.because,
        place: g.place,
      )
    } else {
      groups.push((
        node: node,
        from: i,
        to: i + 1,
        text: text,
        because: w.at("because", default: ""),
        // Gộp nhiều tầng thì lấy khoá đặt chỗ của tầng đầu — ô là một, chỗ đặt cũng
        // phải là một.
        place: pick(w),
      ))
    }
  }

  // `common` trước, `g.place` sau: khoá của từng tầng thắng khoá áp cho cả bộ.
  groups.map(g => (
    node: g.node,
    body: [#strong(ww-label(g.from + 1, g.to, word: word) + ":") #{
      bp-text(if g.text != none { g.text } else { g.because })
    }],
  ) + common + g.place)
}
