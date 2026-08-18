// src/turnicon.typ
// Biểu tượng "xoay tờ giấy" cho các trang gấp của `bpmn-sheet`.
//
// Vì sao cần: một tờ gấp in ra là trang A4 *dọc* như mọi trang khác, nhưng bản vẽ nằm
// ngang trên đó. Câu hướng dẫn viết bằng chữ — "xoay tờ giấy 90 độ ngược chiều kim
// đồng hồ" — đúng nhưng đọc xong vẫn phải dịch sang động tác, mà người đọc thì đang
// cầm tờ giấy trên tay. Điện thoại đã giải quyết chuyện này từ lâu bằng đúng một hình:
// khung màn hình dọc, hai mũi tên vòng quanh. Không cần chú giải, không phụ thuộc ngôn
// ngữ, và nhìn một cái là tay làm theo.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - sheet-turn-icon(turn: "cw", size: 1.6em, mark: auto, ..) : biểu tượng xoay giấy.

// Điểm trên vòng tròn tâm (cx, cy), bán kính r, tại góc `a`.
//
// Trục y của Typst hướng *xuống*, nên công thức lượng giác thông thường sẽ cho một
// vòng quay ngược với cái mắt nhìn thấy. Lật dấu của thành phần y ngay tại đây, một
// lần, để mọi chỗ còn lại trong file đọc theo nghĩa thị giác: góc tăng dần = quay
// *ngược* chiều kim đồng hồ trên trang giấy.
#let _ring(cx, cy, r, a) = (cx + r * calc.cos(a), cy - r * calc.sin(a))

/// Biểu tượng hướng dẫn xoay tờ giấy để đọc một trang gấp.
///
/// `turn` nhận **đúng giá trị đã truyền cho `bpmn-sheet`** — tức chiều bản vẽ đã bị
/// xoay đi, không phải chiều người đọc phải xoay tờ giấy. Hai chiều đó ngược nhau, và
/// đó chính là lý do tham số này không hỏi chiều xoay giấy: bắt người gọi tự đảo là
/// bắt họ đảo sai, mà mũi tên chỉ nhầm chiều thì tệ hơn hẳn không có mũi tên.
///
///   #bpmn-sheet(.., turn: "cw")     -> #sheet-turn-icon(turn: "cw")   mũi tên ngược kim đồng hồ
///
/// `mark` là chữ in trong thân tờ giấy. Mặc định `auto`: in "A4" khi biểu tượng đủ lớn
/// để hai chữ đó còn đọc được (từ khoảng 26pt trở lên), bỏ qua khi không — vì một vệt
/// mờ trong biểu tượng đọc ra thành vết bẩn chứ không thành thông tin. Truyền thẳng
/// một chuỗi để ép in, hoặc `none` để tắt hẳn.
///
/// `size` là cạnh của khung vuông chứa biểu tượng. Mặc định theo `em` để nó co giãn
/// cùng cỡ chữ của đoạn văn đặt nó — biểu tượng này gần như luôn nằm xen trong một
/// dòng chữ hoặc đầu một khối ghi chú.
#let sheet-turn-icon(
  turn: "cw",
  size: 1.6em,
  paint: auto,
  paper: none,
  mark: auto,
  thickness: auto,
) = context {
  let s = size.to-absolute()
  let paint = if paint == auto { text.fill } else { paint }
  let t = if thickness == auto { s * 0.055 } else { thickness }

  // Bản vẽ xoay theo chiều kim đồng hồ => người đọc xoay tờ giấy ngược lại.
  let ccw = turn != "ccw"

  let r = 0.42
  let head-len = 0.13
  let head-half = 0.062
  // Cắt ngắn cung đúng bằng chiều dài đầu mũi tên, nếu không nét vẽ chọc ra khỏi đỉnh.
  // Suy ra từ `head-len`, không gõ thẳng số đo: dây cung dài L trên đường tròn bán kính
  // r chắn một góc 2·asin(L / 2r). Gõ thẳng "18deg" cũng ra đúng con số này hôm nay,
  // nhưng sau này chỉnh `r` hay `head-len` thì phần cắt lệch đi mà không có gì báo —
  // cùng một lý do `marker-loop` suy góc thay vì gõ. Xem docs/curved-arrows.md.
  let trim = 2 * calc.asin(head-len / (2 * r))

  let arc(a0, a1) = {
    let n = 14
    let pts = range(n + 1).map(i => _ring(0.5, 0.5, r, a0 + (a1 - a0) * i / n))
    let xy(p) = (p.at(0) * s, p.at(1) * s)
    place(curve(
      stroke: (paint: paint, thickness: t, cap: "round"),
      curve.move(xy(pts.first())),
      ..pts.slice(1).map(p => curve.line(xy(p))),
    ))
  }

  let head(a) = {
    let (px, py) = _ring(0.5, 0.5, r, a)
    let d = if ccw { 1.0 } else { -1.0 }
    // Tiếp tuyến của vòng tròn tại `a`, theo chiều quay đang vẽ.
    let (tx, ty) = (-calc.sin(a) * d, -calc.cos(a) * d)
    let (nx, ny) = (-ty, tx)
    let xy(x, y) = (x * s, y * s)
    place(curve(
      fill: paint,
      stroke: none,
      curve.move(xy(px, py)),
      curve.line(xy(px - tx * head-len + nx * head-half, py - ty * head-len + ny * head-half)),
      curve.line(xy(px - tx * head-len - nx * head-half, py - ty * head-len - ny * head-half)),
      curve.close(),
    ))
  }

  // Hai cung đối xứng trên/dưới, chừa hai bên cho tờ giấy thò ra — cùng bố cục với
  // biểu tượng xoay màn hình của điện thoại, và cũng là lý do nó đọc được ngay.
  let spans = ((35deg, 145deg), (215deg, 325deg))

  // Biểu tượng này gần như luôn nằm xen trong một dòng chữ, mà một hộp vuông cao 1,6em
  // đặt trên đường cơ sở thì nhô hẳn lên trên dòng. Hạ nó xuống sao cho *tâm* biểu
  // tượng trùng với giữa chiều cao chữ thường — cùng chỗ mắt đặt khi đọc dòng đó.
  let em = 1em.to-absolute()
  box(width: s, height: s, baseline: s / 2 - 0.25 * em, {
    // Tờ giấy: tỉ lệ A4 dọc (1 : √2), bo góc nhẹ cho ra hình một tờ giấy chứ không
    // phải một cái ô.
    let pw = 0.30
    let ph = pw * 1.414
    place(
      dx: (0.5 - pw / 2) * s,
      dy: (0.5 - ph / 2) * s,
      rect(
        width: pw * s,
        height: ph * s,
        radius: 0.045 * s,
        fill: paper,
        // Viền tờ giấy mảnh hơn mũi tên. Hai nét này nói hai chuyện khác nhau: mũi tên
        // là *chỉ dẫn*, tờ giấy là *vật được chỉ dẫn*. Vẽ bằng nhau thì hình thành ba
        // nét cùng trọng lượng chen nhau trong một ô vuông, và mắt không biết đọc cái
        // nào trước.
        stroke: (paint: paint, thickness: t * 0.62),
      ),
    )
    // Chữ "A4" trong thân giấy: nói rõ hình chữ nhật kia là *tờ giấy*, không phải màn
    // hình điện thoại — biểu tượng này mượn bố cục của icon xoay màn hình, nên không có
    // gì phân biệt thì người đọc mặc định hiểu theo cái quen hơn.
    // `auto`: chỉ in khi còn đọc được. Ngưỡng ~4pt — dưới đó hai chữ thành một vệt
    // mờ, mà một vệt mờ trong biểu tượng đọc ra thành vết bẩn chứ không thành thông
    // tin. Nhờ vậy cùng một lời gọi dùng được cả ở cỡ ghi chú lẫn cỡ xen dòng.
    let mark = if mark == auto {
      if 0.145 * s >= 4pt { "A4" } else { none }
    } else { mark }
    if mark != none and mark != "" {
      place(
        dx: (0.5 - pw / 2) * s,
        dy: (0.5 - ph / 2) * s,
        box(width: pw * s, height: ph * s, align(center + horizon,
          text(size: 0.145 * s, fill: paint, weight: "medium", tracking: 0.008 * s, mark))),
      )
    }
    for (a0, a1) in spans {
      if ccw { arc(a0, a1 - trim); head(a1) } else { arc(a0 + trim, a1); head(a0) }
    }
  })
}
