// src/bptext.typ
// Chuỗi trong file dữ liệu -> content của Typst.
//
// Vấn đề: `[Chương 2--3]` viết trong tài liệu ra "Chương 2–3", nhưng cùng chuỗi đó
// nằm trong YAML rồi chèn bằng `#s` thì ra đúng "Chương 2--3" — hai gạch nối, y
// nguyên. Không phải lỗi: `--` -> en-dash là việc của *bộ phân tích cú pháp* Typst,
// mà một `str` thì không đi qua bộ phân tích nào cả.
//
// Nên tầng dữ liệu phải nói rõ nó gửi cái gì cho engine. Ba chế độ:
//
//   "markup"  eval như markup Typst. Được dash, được `$->$`, được `*đậm*`,
//             `_nghiêng_`, `#link(..)`. Đây là mặc định.
//   "smart"   chỉ thay ký hiệu typography, không eval. Tuyệt đối an toàn.
//   "raw"     giữ nguyên chuỗi.
//
// Bốn cái bẫy của "markup", phải biết trước khi dùng:
//
//   1. `#` mở một biểu thức code. "kho #1" ra "kho 1" — dấu thăng *biến mất im
//      lặng*, không báo lỗi. Muốn dấu thăng thật thì viết `\#`.
//   2. `~` là *dấu cách không ngắt*, không phải dấu ngã. "≈70 đơn" viết "~70 đơn"
//      sẽ ra " 70 đơn" — mất luôn nghĩa "xấp xỉ". Viết `\~`, hoặc dùng thẳng ký tự
//      "≈" cho rõ.
//   3. Trong math, một dãy nhiều chữ cái là *một biến*, không phải chữ. `$CTE$`
//      làm hỏng build với "unknown variable: CTE". Viết `$"CTE"$` hoặc `$C T E$`.
//   4. Đậm là `*một sao*`, không phải `**hai sao**` như Markdown. Hai sao chỉ ra
//      chữ thường kèm một cảnh báo "no text within stars".
//
// Ba trong bốn cái trên *hỏng im lặng*. Đó là lý do `bp-text` không phải mặc định
// cho mọi nguồn — xem `mode` dưới đây.
//
// Typst không có try/catch, nên chế độ "markup" không thể tự bắt lỗi rồi lui về
// chuỗi thô. Đó là lý do "smart" tồn tại: nhãn lấy từ Camunda Modeler là do người
// khác gõ, cho một công cụ khác, và không ai ở đó nghĩ mình đang viết Typst.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT

// Thay ký hiệu typography mà không eval. Thứ tự quan trọng: `---` phải xét trước
// `--`, nếu không em-dash bị cắt thành en-dash cộng một gạch nối.
#let bp-smart(s) = {
  if type(s) != str { return s }
  s
    .replace("---", "\u{2014}") // em dash
    .replace("--", "\u{2013}") // en dash
    .replace("...", "\u{2026}") // ellipsis
}

/// Chuyển một giá trị của tầng dữ liệu thành content.
///
/// Chỉ đụng vào `str`; content, số, `none` đi thẳng qua. Chuỗi rỗng cũng đi thẳng,
/// vì `eval("")` trả về content rỗng và làm hỏng mọi phép kiểm `== ""` phía sau.
///
/// `scope` là các tên mà chuỗi được phép gọi. `eval` mặc định chạy trong phạm vi
/// **rỗng**: chỉ có sẵn thứ dựng trong Typst, không có một định nghĩa nào của tài liệu.
/// Nên `#impact(level: 1)[High]` viết trong YAML sẽ báo "unknown variable: impact" cho
/// tới khi chỗ gọi truyền `scope: (impact: impact)`.
///
/// Mở phạm vi có nghĩa là tầng dữ liệu gọi được code của tài liệu, và đó là điều muốn:
/// một ô bảng nói "mức tác động cao" thì nên nói bằng đúng component vẽ nhãn mức tác
/// động, chứ không phải bằng một chữ "(High)" gõ tay. Nhưng nó cũng có nghĩa là chỉ nên
/// mở đúng những tên cần mở — đừng đổ cả module vào.
#let bp-text(v, mode: "markup", scope: (:)) = {
  if type(v) != str or v == "" { return v }
  if mode == "raw" { return v }
  if mode == "smart" { return bp-smart(v) }
  eval(v, mode: "markup", scope: scope)
}

/// Rút văn bản thuần từ content — dùng để so khớp nhãn sau khi đã dựng.
///
/// Cần vì `annotate` và `bpmap` neo theo *tên*, mà tên trong dữ liệu là "Chương 2--3"
/// còn tên đã dựng là "Chương 2–3". So hai chuỗi thô sẽ trượt; so bản đã dựng của cả
/// hai thì khớp.
#let bp-flatten(body) = {
  if body == none { return "" }
  if type(body) == str { return body }
  if type(body) != content { return str(body) }
  if body.has("text") { return body.text }
  if body.has("children") { return body.children.map(bp-flatten).join("") }
  if body.has("body") { return bp-flatten(body.body) }
  ""
}

/// So khớp hai nhãn bất kể chúng ở dạng thô hay đã dựng.
#let bp-same-text(a, b, mode: "markup", scope: (:)) = {
  let f(v) = bp-flatten(bp-text(v, mode: mode, scope: scope)).trim()
  f(a) == f(b)
}
