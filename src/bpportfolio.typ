// src/bpportfolio.typ
// Process Portfolio Matrix: ma trận danh mục quy trình, dùng để *chọn* quy trình
// nào đáng cải tiến trước, theo ba tiêu chí của FBPM2e:
//
//   Importance   quy trình đóng góp bao nhiêu vào mục tiêu chiến lược
//   Health       nó đang chạy tốt tới đâu (thấp = nhiều rối loạn = nhiều chỗ để sửa)
//   Feasibility  sửa nó dễ tới đâu (nguồn lực, quyền hạn, độ phức tạp)
//
// Ba tiêu chí, ba kênh thị giác: vị trí ngang (và màu) cho Health, vị trí dọc cho
// Importance, đường kính cho Feasibility. Đọc hình theo đúng một câu: **quy trình
// đáng chọn nằm ở góc trên bên trái, màu đỏ, và vẽ to.**
//
// Vì sao Health nằm ở trục hoành và tăng dần sang phải, dù "đáng chọn" lại là bên
// trái: đảo trục cho vùng đáng chọn về góc trên bên phải sẽ khiến trục đọc ngược
// (100% ở gốc), và người đọc quen với "trục tăng dần từ gốc" hơn là quen với "góc
// trên bên phải là tốt". Đổi lại phải nói rõ vùng chọn, nên vùng đó được tô nền
// và có nhãn.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// Legend kích thước nằm dọc ở lề phải, đối xứng với nhãn trục tung, và chạy từ dưới
// lên (25% ở đáy, 100% ở đỉnh), cùng chiều với Importance, nên mắt so hai thứ mà
// không phải đổi quy ước giữa chừng.
//
// Bảng chú giải mã (chế độ "tag") là một lưới 5 cột cho mỗi khối:
//
//   ● mã | tên quy trình ......... | Imp | Health | Feas
//        căn trái                      ba cột căn phải
//
// Ba con số căn phải để hàng đơn vị thẳng nhau, đọc dọc một cột là so sánh được
// ngay. `key-columns` là số khối cạnh nhau; nhiều khối thì xếp *theo cột*, tức là
// chạy hết khối trái rồi mới sang khối phải, để thứ tự khai báo không vỡ vụn.
//
// API công khai:
//   - bpportfolio(processes: (..), ..)  : vẽ ma trận.
//   - bpportfolio-data(data, ..)        : dựng từ dict đã nạp (YAML/JSON).
//   - bpf-themes                        : bộ màu dựng sẵn ("camunda", "bw", "aqua", "sap").
//   - bpf-ramps                         : thang màu Health dựng sẵn.
//   - bpf-ramp-at(stops, t)             : lấy màu ở một điểm trên thang.
//
// Lược đồ dữ liệu:
//   caption, label      như mọi component khác
//   options: (..)       mọi tham số của bpportfolio()
//   processes:
//     - name: Xử lý bảo hành
//       importance: 90        # 0..100
//       health: 25            # 0..100, THẤP là xấu
//       feasibility: 70       # 0..100, đường kính bong bóng
//       tag: C4               # nhãn ngắn vẽ trong bong bóng (tuỳ chọn)
//       select: true          # tô đậm, coi là quy trình được chọn
//       side: "left"          # ép nhãn sang một phía: "left" | "right"
//       dx: 4pt               # đẩy nhãn đi, tắt hẳn việc tự chọn phía
//       dy: -3pt
//       color: "#c0392b"      # ghi đè màu

#import "bpstep.typ": bp-to-color, bp-contrast
#import "bpmn-palette.typ": camunda-palette
#import "bptext.typ": bp-text

// MARK: Ba kênh mã hoá
// Ba tiêu chí, ba kênh thị giác độc lập, không cái nào phải chia sẻ kênh với cái nào:
//
//   Importance   -> vị trí dọc   (càng quan trọng càng lên trên)
//   Feasibility  -> đường kính   (càng khả thi càng to)
//   Health       -> vị trí ngang *và* màu (càng thấp càng đỏ, càng cao càng xanh)
//
// Health chiếm hai kênh là cố ý: mã hoá dư (redundant encoding). Trục trả lời "thấp
// bao nhiêu", màu trả lời "có đáng lo không", mắt đọc được câu thứ hai từ xa mà
// không cần dò trục. Vì màu ở đây chỉ nhắc lại trục đã có nhãn, hình không cần thêm
// một chú giải màu riêng.
//
// Hệ quả với `select`: quy trình được chọn KHÔNG đổi màu nền. Đổi là cướp mất kênh
// của Health, và cướp đúng lúc nó đang nói điều quan trọng nhất, quy trình được
// chọn thì gần như luôn là quy trình đỏ nhất. Chọn được thể hiện bằng viền dày và
// chữ đậm.

// Thang màu Health. Dùng thẳng bảng màu Camunda của thư viện, không chế màu mới:
// đỏ (failure) -> cam (warning) -> xanh lá (success) là đúng ba nấc ngữ nghĩa mà
// `semantic-aliases` đã đặt tên.
// Bảng màu Camunda được chế cho *nền hình chữ nhật to*, nên nó rất nhạt. Bong bóng
// 10–30pt thì nhạt tới mức đỏ và xanh nhìn gần như nhau, nhất là ở khoảng giữa. Nên
// tăng bão hoà cho riêng thang này, vẫn đúng hue của bảng màu, chỉ đậm lên đủ để
// đọc được thứ tự ở kích thước nhỏ.
#let _sw(name, sat: 45%) = {
  let c = camunda-palette.at(name)
  (fill: c.fill.saturate(sat), stroke: c.stroke)
}

#let bpf-ramps = (
  signal: (_sw("red"), _sw("orange"), _sw("green")),
  teal: (
    _sw("red"),
    _sw("orange"),
    (fill: rgb("#cfe3ea").saturate(30%), stroke: rgb("#1d7c92")),
  ),
  // Đen trắng: đậm là ốm. In ra vẫn đọc được thứ tự.
  gray: (
    (fill: luma(52%), stroke: luma(15%)),
    (fill: luma(74%), stroke: luma(25%)),
    (fill: luma(93%), stroke: luma(35%)),
  ),
)

// MARK: Themes
#let bpf-themes = (
  // Bảng màu của chính typst-bpmn: mặc định
  camunda: (
    plot: white,
    grid: luma(90%),
    axis: rgb("#22242A"),
    // "Vùng ưu tiên" là một cảnh báo, nên nó lấy swatch cảnh báo (orange/warning)
    // pha loãng: đủ để thấy vùng, không đủ để cãi nhau với bong bóng nằm trong.
    zone: rgb("#FFE0B2").lighten(64%),
    zone-line: rgb("#6B3C00").lighten(35%),
    zone-text: rgb("#6B3C00"),
    ramp: bpf-ramps.signal,
    bubble: luma(88%), // chỉ dùng cho chú giải kích thước
    bubble-line: luma(45%),
    pick-line: rgb("#22242A"),
    text: black,
    muted: luma(40%),
  ),
  // Đen trắng: an toàn khi in
  bw: (
    plot: white,
    grid: luma(90%),
    axis: luma(25%),
    zone: luma(94%),
    zone-line: luma(70%),
    zone-text: luma(40%),
    ramp: bpf-ramps.gray,
    bubble: luma(85%),
    bubble-line: luma(35%),
    pick-line: black,
    text: black,
    muted: luma(40%),
  ),
  aqua: (
    plot: white,
    grid: rgb("#e3edf0"),
    axis: rgb("#1d7c92"),
    zone: rgb("#FFE0B2").lighten(64%),
    zone-line: rgb("#6B3C00").lighten(35%),
    zone-text: rgb("#6B3C00"),
    ramp: bpf-ramps.teal,
    bubble: rgb("#dfeaee"),
    bubble-line: rgb("#1d7c92"),
    pick-line: rgb("#0e4a58"),
    text: black,
    muted: luma(40%),
  ),
  sap: (
    plot: white,
    grid: rgb("#f2dbe7"),
    axis: rgb("#A01050"),
    zone: rgb("#FFE0B2").lighten(64%),
    zone-line: rgb("#6B3C00").lighten(35%),
    zone-text: rgb("#6B3C00"),
    ramp: bpf-ramps.signal,
    bubble: rgb("#f4d3e3"),
    bubble-line: rgb("#A01050"),
    pick-line: rgb("#5e0a2f"),
    text: black,
    muted: luma(40%),
  ),
)

// Lấy màu ở vị trí `t` (0..1) trên thang, nội suy tuyến tính giữa hai nấc kề nhau.
#let bpf-ramp-at(stops, t) = {
  let n = stops.len() - 1
  if n < 1 { return stops.at(0) }
  let x = calc.max(0.0, calc.min(1.0, t)) * n
  let i = calc.min(int(x), n - 1)
  let f = x - i
  let a = stops.at(i)
  let b = stops.at(i + 1)
  // oklab, không phải sRGB: trộn hai pastel trong sRGB cho ra màu bùn ở khoảng giữa
  // thang, đúng chỗ người đọc cần phân biệt "hơi ốm" với "hơi khoẻ".
  (
    fill: color.mix((a.fill, (1 - f) * 100%), (b.fill, f * 100%), space: oklab),
    stroke: color.mix((a.stroke, (1 - f) * 100%), (b.stroke, f * 100%), space: oklab),
  )
}

// MARK: Helpers
#let _num(v, default: 0) = {
  if type(v) == int or type(v) == float { float(v) } else { float(default) }
}

// YAML không có kiểu độ dài: `size: [12.2cm, 8cm]` về tới đây là hai chuỗi. Đọc tay
// thay vì `eval`. Khác với `bp-text`: ở đó eval *là* mục đích (người viết muốn dash
// và math); ở đây eval chỉ là một cách lười để đọc một con số kèm đơn vị.
#let _units = (("cm", 1cm), ("mm", 1mm), ("in", 1in), ("pt", 1pt), ("em", 1em))
#let _len(v, default: 0pt) = {
  if type(v) == length or type(v) == relative or type(v) == ratio { return v }
  if type(v) == int or type(v) == float { return float(v) * 1pt }
  if type(v) != str { return default }
  let s = v.trim()
  for (suffix, unit) in _units {
    if s.ends-with(suffix) {
      let n = float(s.slice(0, s.len() - suffix.len()).trim())
      return n * unit
    }
  }
  float(s) * 1pt
}

// Một mục có thể là dict, hoặc mảng (name, importance, health, feasibility).
#let bpf-normalize(p) = {
  let d = if type(p) == array {
    (
      name: p.at(0, default: ""),
      importance: p.at(1, default: 50),
      health: p.at(2, default: 50),
      feasibility: p.at(3, default: 50),
    )
  } else if type(p) == dictionary { p } else { (name: p) }

  let name = {
    let out = none
    for k in ("name", "text", "title", "label", "process") {
      if out == none and k in d { out = d.at(k) }
    }
    if out == none { "" } else { out }
  }
  (
    name: bp-text(name),
    importance: _num(d.at("importance", default: 50), default: 50),
    health: _num(d.at("health", default: 50), default: 50),
    feasibility: _num(d.at("feasibility", default: 50), default: 50),
    tag: bp-text(d.at("tag", default: none)),
    select: d.at("select", default: false),
    side: d.at("side", default: none),
    dx: d.at("dx", default: none),
    dy: d.at("dy", default: none),
    color: d.at("color", default: none),
    note: bp-text(d.at("note", default: none)),
  )
}

// MARK: bpportfolio
//
// size          : (rộng, cao) của *vùng vẽ*, chưa tính lề trục
// zone          : ngưỡng vùng "cải tiến ngay", (health-max, importance-min)
// bubble        : (nhỏ nhất, lớn nhất) đường kính bong bóng
// axis-labels   : nhãn hai trục
// zone-label    : nhãn vùng chọn; `none` để tắt
// legend        : hiện chú giải kích thước bong bóng
// theme         : tên trong `bpf-themes`, hoặc một dict
#let bpportfolio(
  processes: (),
  size: (12cm, 6.5cm),
  zone: (50, 60),
  bubble: (9pt, 30pt),
  grid-step: 25,
  radius: 2pt,
  labels: "auto",
  label-width: 3.1cm,
  label-gap: 11pt,
  key-columns: 2,
  key-headers: ("Quy trình", "Imp", "Health", "Feas"),
  axis-labels: ("*Health*: chỉ số sức khỏe (%)", "*Importance*: mức độ quan trọng (%)"),
  zone-label: [Vùng ưu tiên cải tiến],
  legend: true,
  legend-label: [*Feasibility*: mức độ khả thi],
  // Các mốc của legend, khai từ trên xuống dưới (lớn -> nhỏ).
  legend-key: (100, 75, 50, 25),
  font: none,
  size-text: 8pt,
  theme: "camunda",
) = {
  let th = if type(theme) == str { bpf-themes.at(theme, default: bpf-themes.camunda) } else { theme }
  let radius = _len(radius, default: 2pt)
  let items = processes.map(bpf-normalize)

  // Tên quy trình thật thường dài; viết thẳng cạnh bong bóng thì hai nhãn ở hai phía
  // đối diện vẫn đâm vào nhau, và không có cách sắp xếp nào cứu được. Chế độ "tag"
  // bỏ hẳn bài toán đó: trong bong bóng chỉ có mã ngắn, tên nằm ở bảng chú giải bên
  // dưới. "auto" chọn giúp: quá bốn quy trình thì dùng tag.
  // Khai `tag:` bằng tay là đã nói rõ ý muốn dùng mã; viết cả mã lẫn tên cạnh nhau
  // là thừa, và làm hai nhãn dài đâm vào nhau ngay.
  let mode = if labels != "auto" { labels } else if (
    items.len() > 4 or items.any(p => p.tag != none)
  ) { "tag" } else { "name" }
  items = items
    .enumerate()
    .map(((i, p)) => if p.tag != none { p } else { p + (tag: if mode == "tag" { "P" + str(i + 1) } else { none }) })

  let (pw, ph) = (_len(size.at(0), default: 12cm), _len(size.at(1), default: 8cm))
  let (r-min, r-max) = (_len(bubble.at(0), default: 9pt), _len(bubble.at(1), default: 30pt))
  let label-width = _len(label-width, default: 3.1cm)
  let label-gap = _len(label-gap, default: 11pt)
  let pad-left = 1.15cm // chỗ cho nhãn trục tung
  let pad-bottom = 1.05cm // chỗ cho nhãn trục hoành
  // Legend kích thước nằm dọc ở lề phải, đối xứng với nhãn trục tung bên trái:
  // một cột bong bóng, rồi tới nhãn xoay dọc. Không có legend thì lề phải chỉ đủ
  // để nhãn "100" của trục hoành không bị cắt.
  let legend-gap = 7pt
  let legend-title-h = 0.42cm
  let pad-right = if legend { r-max + legend-gap + legend-title-h + 4pt } else { 0.2cm }
  let pad-top = 0.2cm

  // Chuyển giá trị 0..100 thành toạ độ trong vùng vẽ. Trục tung lật lại: 100% ở trên.
  let X(v) = pad-left + pw * (v / 100)
  let Y(v) = pad-top + ph * (1 - v / 100)
  let R(f) = r-min + (r-max - r-min) * (f / 100)

  let body = {
    set text(size: size-text, fill: th.text, ..(if font != none { (font: font) } else { (:) }))

    box(width: pad-left + pw + pad-right, height: pad-top + ph + pad-bottom, {
      // --- nền vùng vẽ ---
      place(dx: pad-left, dy: pad-top, rect(width: pw, height: ph, fill: th.plot, stroke: none, radius: radius))

      // --- vùng ưu tiên: health thấp + importance cao ---
      // Bo góc trên-trái theo khung, ba góc còn lại vuông vì chúng cắt vào giữa
      // vùng vẽ chứ không nằm trên viền.
      let (zh, zi) = zone
      place(
        dx: X(0),
        dy: Y(100),
        rect(
          width: X(zh) - X(0),
          height: Y(zi) - Y(100),
          fill: th.zone,
          // Chỉ kẻ hai cạnh *bên trong* vùng vẽ. Hai cạnh kia trùng khít với khung,
          // vẽ thêm chỉ tạo một đường đôi lờ mờ.
          stroke: (
            right: (paint: th.zone-line, thickness: 0.5pt, dash: "dashed"),
            bottom: (paint: th.zone-line, thickness: 0.5pt, dash: "dashed"),
          ),
          radius: (top-left: radius),
        ),
      )
      if zone-label != none {
        place(
          dx: X(0) + 4pt,
          dy: Y(zi) - 1.05em,
          text(size: 0.88em, fill: th.at("zone-text", default: th.muted), style: "italic", bp-text(zone-label)),
        )
      }

      // --- lưới ---
      let n = int(100 / grid-step)
      for i in range(n + 1) {
        let v = i * grid-step
        place(dx: X(v), dy: pad-top, line(length: ph, angle: 90deg, stroke: 0.4pt + th.grid))
        place(dx: pad-left, dy: Y(v), line(length: pw, angle: 0deg, stroke: 0.4pt + th.grid))
        // vạch chia
        place(
          dx: X(v) - 0.5cm,
          dy: pad-top + ph + 3pt,
          box(width: 1cm, align(center, text(size: 0.85em, fill: th.muted, [#v]))),
        )
        place(
          dx: 0pt,
          dy: Y(v) - 0.45em,
          box(width: pad-left - 4pt, align(right, text(size: 0.85em, fill: th.muted, [#v]))),
        )
      }

      // --- khung ---
      place(
        dx: pad-left,
        dy: pad-top,
        rect(width: pw, height: ph, fill: none, stroke: 0.7pt + th.axis, radius: radius),
      )

      // --- nhãn trục ---
      place(
        dx: pad-left,
        dy: pad-top + ph + 0.42cm,
        box(width: pw, align(center, text(size: 0.92em, fill: th.axis, weight: "medium", bp-text(axis-labels.at(0))))),
      )
      // Xoay quanh góc trên-trái: hộp rộng `ph` đổ *lên trên* từ điểm neo, nên điểm
      // neo là đáy vùng vẽ. Tính theo tâm sẽ đẩy hộp chưa xoay ra ngoài trang và
      // bị cắt mất: đã dính một lần.
      place(
        dx: 0pt,
        dy: pad-top + ph,
        rotate(-90deg, origin: top + left, box(
          width: ph,
          align(center, text(size: 0.92em, fill: th.axis, weight: "medium", bp-text(axis-labels.at(1)))),
        )),
      )

      // --- legend kích thước: cột dọc ở lề phải ---
      //
      // Đặt đối xứng với nhãn trục tung, và chạy *từ dưới lên*: 25% ở đáy, 100% ở
      // đỉnh: cùng chiều với Importance, nên mắt so hai thứ mà không phải đổi quy
      // ước giữa chừng.
      //
      // Trị số nằm trong bong bóng khi lọt, rơi xuống dưới khi không. Ngưỡng đo
      // bằng `measure`, không đoán: bề rộng "100%" phụ thuộc font của tài liệu, mà
      // ở cỡ 25% thì đường kính chỉ hơn bề rộng chữ vài point.
      if legend {
        let col-x = pad-left + pw + legend-gap
        let item(v) = context {
          let d = R(v)
          let lbl = text(size: 0.78em, fill: th.muted, [#v%])
          if measure(lbl).width + 6pt <= d {
            circle(radius: d / 2, fill: th.bubble, stroke: 0.7pt + th.bubble-line, lbl)
          } else {
            stack(
              dir: ttb,
              spacing: 1.5pt,
              align(center, circle(radius: d / 2, fill: th.bubble, stroke: 0.7pt + th.bubble-line)),
              align(center, lbl),
            )
          }
        }
        place(
          dx: col-x,
          dy: pad-top,
          box(width: r-max, height: ph, align(center + horizon, stack(
            dir: ttb,
            spacing: 10pt,
            ..legend-key.map(v => align(center, item(v))),
          ))),
        )
        // Xoay cùng chiều với nhãn trục tung (đọc từ dưới lên), không phải chiều
        // ngược lại như trục phụ thường thấy: hai nhãn dọc của cùng một hình mà
        // đọc hai chiều khác nhau thì người đọc phải nghiêng đầu hai lần.
        place(
          dx: col-x + r-max + 2pt,
          dy: pad-top + ph,
          rotate(-90deg, origin: top + left, box(
            width: ph,
            align(center, text(size: 0.92em, fill: th.axis, weight: "medium", bp-text(legend-label))),
          )),
        )
      }

      // --- bong bóng: vẽ cái to trước để cái nhỏ không bị che ---
      let ramp = th.at("ramp", default: none)
      let ordered = items.sorted(key: p => -p.feasibility)
      for p in ordered {
        let d = R(p.feasibility)
        // Màu đến từ Health. `color:` của người viết vẫn thắng.
        let sw = if ramp == none {
          (fill: th.bubble, stroke: th.bubble-line)
        } else { bpf-ramp-at(ramp, p.health / 100) }
        let fill = if p.color != none { bp-to-color(p.color) } else { sw.fill }
        let stroke = if p.select {
          1.4pt + th.pick-line
        } else { 0.7pt + sw.stroke }
        place(
          dx: X(p.health) - d / 2,
          dy: Y(p.importance) - d / 2,
          circle(radius: d / 2, fill: fill, stroke: stroke),
        )
        if p.tag != none {
          place(
            dx: X(p.health) - d / 2,
            dy: Y(p.importance) - 0.5em,
            box(width: d, align(center, text(
              size: 0.8em,
              weight: "bold",
              fill: bp-contrast(fill),
              [#p.tag],
            ))),
          )
        }
      }

      // --- nhãn ---
      // Mặc định đặt bên phải bong bóng, lật sang trái khi sát mép phải. Hai nhãn
      // cùng phía mà quá gần nhau thì đẩy xuống theo thứ tự từ trên xuống, và khi
      // đã đẩy thì kẻ một đường dẫn mảnh, nếu không người đọc gán nhãn nhầm bong bóng.
      let placed = ()
      for side in (if mode == "tag" { () } else { ("left", "right") }) {
        let mine = items
          .enumerate()
          .filter(((i, p)) => {
            let s = if p.side != none { p.side } else if p.health > 68 { "left" } else { "right" }
            s == side and p.dx == none and p.dy == none
          })
          .map(((i, p)) => p)
          .sorted(key: p => p.importance * -1) // từ trên xuống
        let prev = -1e9pt
        for p in mine {
          let want = Y(p.importance)
          let y = if want < prev + label-gap { prev + label-gap } else { want }
          prev = y
          placed.push((p: p, side: side, y: y, want: want))
        }
      }
      // giữ nguyên vị trí tay khai
      for p in (if mode == "tag" { () } else { items }) {
        if p.dx != none or p.dy != none {
          let side = if p.side != none { p.side } else if p.health > 68 { "left" } else { "right" }
          placed.push((p: p, side: side, y: Y(p.importance) + p.dy.or(0pt), want: Y(p.importance)))
        }
      }

      for e in placed {
        let p = e.p
        let d = R(p.feasibility)
        let w = label-width
        let manual = p.dx != none or p.dy != none
        let x = if manual {
          X(p.health) + p.dx.or(0pt)
        } else if e.side == "left" { X(p.health) - d / 2 - 5pt - w } else { X(p.health) + d / 2 + 5pt }

        // đường dẫn khi nhãn bị đẩy khỏi tâm bong bóng
        if not manual and calc.abs((e.y - e.want) / 1pt) > 2 {
          let x0 = if e.side == "left" { X(p.health) - d / 2 } else { X(p.health) + d / 2 }
          let x1 = if e.side == "left" { x + w + 2pt } else { x - 2pt }
          place(dx: x0, dy: e.want, line(end: (x1 - x0, e.y - e.want), stroke: 0.4pt + th.muted))
        }

        place(
          dx: x,
          dy: e.y - 0.62em,
          box(width: w, align(if e.side == "left" { right } else { left }, {
            text(size: 0.92em, weight: if p.select { "bold" } else { "regular" }, p.name)
            if p.note != none {
              linebreak()
              text(size: 0.8em, fill: th.muted, p.note)
            }
          })),
        )
      }
    })
  }

  // --- bảng chú giải mã, chỉ ở chế độ tag ---
  //
  // Năm cột cho mỗi khối: chấm+mã | tên | Imp | Health | Feas. Ba con số căn phải
  // để hàng đơn vị thẳng nhau: đọc dọc một cột số là so sánh được ngay, việc mà
  // "· I 65 · H 70 · F 50" chạy trong dòng văn không làm được.
  //
  // Nhiều khối thì xếp *theo cột*: M01…S04 chạy hết khối trái rồi mới sang khối
  // phải. Xếp theo hàng (M01 M02 / M03 C01 …) làm thứ tự khai báo vỡ vụn.
  let key-table = if mode != "tag" { none } else {
    set text(size: size-text, fill: th.text, ..(if font != none { (font: font) } else { (:) }))

    // Chấm màu + mã, chấm căn giữa theo chiều dọc của dòng.
    //
    // Cách hiển nhiên (`box(baseline: ..)`) là đặt đáy hộp lên baseline rồi đẩy
    // xuống một khoảng. Nhưng khoảng đó phải suy từ chiều cao chữ, mà Typst không
    // cho đọc font metrics: `measure(text("x")).height` trả về chiều cao *khung
    // dòng* (bằng nhau cho "x", "X" và "xy"), không phải x-height. Mọi con số rút
    // ra từ đó đều là số mò, và sẽ sai khi tài liệu đổi font.
    //
    // Nên để `grid` làm: `align: horizon` căn cả hai ô theo tâm hàng, tức là chấm
    // tự căn giữa so với hộp chữ của mã. Không hằng số, không phụ thuộc font.
    let dot-tag(p) = {
      let sw = if th.at("ramp", default: none) == none {
        (fill: th.bubble, stroke: th.bubble-line)
      } else { bpf-ramp-at(th.ramp, p.health / 100) }
      grid(
        columns: (auto, auto),
        column-gutter: 3.5pt,
        align: horizon,
        circle(radius: 2.4pt, fill: sw.fill, stroke: 0.5pt + sw.stroke),
        text(weight: "bold", fill: if p.select { th.pick-line } else { th.muted }, [#p.tag]),
      )
    }
    let num(v) = text(size: 0.92em, [#calc.round(v)])

    let cells(p) = (
      dot-tag(p),
      text(weight: if p.select { "bold" } else { "regular" }, p.name),
      num(p.importance),
      num(p.health),
      num(p.feasibility),
    )
    let blank = ([], [], [], [], [])

    let heads = key-headers.map(h => bp-text(h))
    let head-row = (
      [],
      ..heads.map(h => text(size: 0.85em, fill: th.muted, h)),
    )

    let per = calc.ceil(items.len() / key-columns)
    let rows = range(per)
      .map(r => range(key-columns)
        .map(c => {
          let i = c * per + r
          if i < items.len() { cells(items.at(i)) } else { blank }
        })
        .flatten())
      .flatten()

    grid(
      columns: ((auto, 1fr, auto, auto, auto) * key-columns).flatten(),
      // `figure` căn giữa nội dung của nó, nên phải khai căn chỉnh ở đây, nếu không
      // tên quy trình trôi vào giữa cột và cả bảng mất trục trái.
      align: ((left, left, right, right, right) * key-columns).flatten(),
      // `column-gutter` chỉ có (số cột − 1) khe. Bốn khe trong một khối, cộng một khe
      // rộng giữa hai khối: khe cuối cùng của khối cuối không tồn tại.
      column-gutter: range(key-columns)
        .map(c => (4pt, 7pt, 5pt, 5pt) + (if c + 1 < key-columns { (13pt,) } else { () }))
        .flatten(),
      row-gutter: 2.5pt,
      ..(head-row * key-columns).flatten(),
      // grid.hline(y: 1, stroke: 0.5pt + th.muted.lighten(58%)),
      ..rows,
    )
  }

  let chart = if key-table == none { body } else {
    stack(dir: ttb, spacing: 8pt, body, key-table)
  }

  block(breakable: false, chart)
}

// MARK: Wrapper: dựng từ dữ liệu đã nạp
// Khoá hiểu được: processes, caption, label, options
#let bpportfolio-data(data, ..args) = {
  if type(data) == array { return bpportfolio(processes: data, ..args) }

  let named = data.at("options", default: (:)) + args.named()

  let caption = named.at("caption", default: data.at("caption", default: none))
  let lbl = named.at("label", default: data.at("label", default: none))
  for k in ("caption", "label") {
    if k in named { let _ = named.remove(k) }
  }
  for k in ("processes",) {
    if k in data and k not in named { named.insert(k, data.at(k)) }
  }

  let out = if caption != none {
    figure(bpportfolio(..named), caption: caption, kind: image, supplement: "Hình ảnh")
  } else {
    bpportfolio(..named)
  }

  if lbl != none { [#out #label(lbl)] } else { out }
}
