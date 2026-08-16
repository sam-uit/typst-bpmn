// src/bpmn-sheet.typ
// Trải một mô hình BPMN **nguyên vẹn** ra nhiều trang, kiểu bản đồ gấp.
//
// Vì sao cần: một collaboration Level 3 là hình băng — rộng gấp đôi tới gấp ba chiều
// cao. Ép nó vào bề rộng chữ A4 thì nhãn rơi xuống 2–4pt. Trong chương, lời giải là
// *cắt lát*: `bpmn-lane`, `bpmn-span`, `bpmn-part` — mỗi hình trả lời một câu hỏi. Nhưng
// người đọc vẫn cần một chỗ nhìn thấy **toàn bộ** mô hình, và đó là việc của phụ lục.
//
// Cách làm: vẽ mô hình *một lần* ở tỉ lệ đọc được, rồi cắt thành từng ô cửa sổ, mỗi ô
// một trang xoay ngang. Khác hẳn `bpmn-span`:
//
//   bpmn-span   cắt theo **ngữ nghĩa** — từ id tới id, mô hình được dựng lại cho lát cắt.
//   bpmn-sheet  cắt theo **hình học** — cùng một bản vẽ, mỗi trang là một khung nhìn.
//
// Hệ quả của cách cắt hình học, và là lý do chọn nó cho phụ lục: mọi trang **cùng một tỉ
// lệ**, các dải lane thẳng hàng từ trang này sang trang kia, và cạnh nào bắc qua chỗ cắt
// thì vẫn liền — nó chỉ chạy ra khỏi mép trang rồi vào lại ở trang sau. Cắt ngữ nghĩa
// không giữ được ba thứ đó: mỗi lát tự co giãn theo nội dung của nó.
//
// Ba quyết định làm cho việc ghép trang không thành trò xếp hình:
//
//   1. **Cắt ngang tại biên pool**, không tại điểm chia đều. Chia đều một mô hình cao
//      1200 đơn vị thành hai hàng 600 sẽ xẻ đôi một lane — mất hoặc phần tên, hoặc phần
//      hình; và nếu nửa dưới chỉ có một dải black box thì một trang gần như trống.
//      Biên pool là chỗ bản vẽ *vốn đã* có đường kẻ.
//   2. **Lặp lại dải tên** ở mọi cột sau cột đầu, như khoá cột của bảng tính. Không có
//      nó, trang 2 là một rừng hộp không ai biết của bộ phận nào.
//   3. **Chồng lấn** một dải giữa hai cột (`overlap`, đơn vị BPMN), kèm vạch đứt đánh
//      dấu. Không có nó, một task nằm đúng chỗ cắt bị chẻ đôi và không trang nào đọc được.
//   4. **Mỗi hàng cắt cột theo phần có nội dung của riêng nó.** Một lưới cột dùng chung
//      cho mọi hàng nghe gọn hơn, nhưng hàng dưới của một mô hình thường chỉ có vài hộp
//      ở mép trái — dùng chung lưới thì sinh ra một trang gần như trắng. Tỉ lệ vẫn là
//      một cho cả bản vẽ, nên vẫn so được; chỉ có số cột là khác nhau giữa các hàng.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - bpmn-sheet(src, ..)       : phát ra n trang xoay ngang, mỗi trang một figure.
//   - bpmn-sheet-plan(model, ..): chỉ tính toán (lưới, tỉ lệ, cỡ chữ) — không vẽ.

#import "bpmn.typ": bpmn-model
#import "bpmn-render.typ": draw-canvas, default-theme
#import "bptext.typ": bp-text

// Bề rộng dải tên bên trái: dải tên pool cộng dải tên lane (nếu pool có lane).
// Suy từ chính bản vẽ chứ không phải hằng số — pool không lane chỉ có một dải.
#let _header-width(model) = {
  let pools = model.pools.filter(p => "bounds" in p)
  if pools.len() == 0 { return 30.0 }
  let px = calc.min(..pools.map(p => p.bounds.x))
  let lanes = pools.map(p => p.at("lanes", default: ())).flatten().filter(l => "bounds" in l)
  if lanes.len() == 0 { return 30.0 }
  let lx = calc.min(..lanes.map(l => l.bounds.x))
  (lx - px) + 30.0
}

// Mọi đường ngang mà bản vẽ *vốn đã* có: biên trên/dưới của từng pool và từng lane.
// Đây là tập chỗ cắt hợp lệ — cắt ở đâu khác là xẻ đôi một dải.
#let _band-cuts(model) = {
  let ys = ()
  for p in model.pools {
    if "bounds" in p { ys.push(p.bounds.y); ys.push(p.bounds.y + p.bounds.h) }
    for l in p.at("lanes", default: ()) {
      if "bounds" in l { ys.push(l.bounds.y); ys.push(l.bounds.y + l.bounds.h) }
    }
  }
  ys.dedup().sorted()
}

// Gom các dải liền nhau thành hàng, mỗi hàng cao không quá `maxh`.
//
// Tham lam từ trên xuống, không tối ưu hoá gì thêm: mục tiêu là *ít hàng*, và tham lam
// đã cho số hàng nhỏ nhất khi các chỗ cắt là cố định. Cách chia "cân bằng" (làm dải cao
// nhất thấp nhất có thể) nghe hợp lý hơn nhưng lại tách pool black box mỏng ra thành
// hàng riêng — một trang gần như trống.
#let _pack-rows(cuts, maxh) = {
  let bounds = (cuts.first(),)
  let i = 0
  while i < cuts.len() - 1 {
    let start = bounds.last()
    let j = i
    // lấn tới chỗ cắt xa nhất còn nằm trong `maxh`; luôn nhận ít nhất một dải
    while j + 1 < cuts.len() and (cuts.at(j + 1) - start <= maxh or j == i) { j += 1 }
    bounds.push(cuts.at(j))
    i = j
  }
  bounds
}

// Bề ngang phần *có nội dung* của một dải ngang [y0, y1).
//
// Vì sao cần: chia hàng theo biên pool là đúng về hình, nhưng nội dung không trải đều
// theo chiều dọc. Ở nhiều mô hình, hàng dưới chỉ có hai ba hộp nằm sát mép trái; lấy
// trọn bề ngang của bản vẽ cho hàng đó là in ra một trang trắng có chú thích.
//
// Trả `none` khi dải hoàn toàn rỗng — hàng đó không đáng một trang.
#let _row-x-span(model, y0, y1) = {
  // Closure không sửa được biến bên ngoài, nên gom hộp trước rồi mới trải thành toạ độ.
  let hit(b) = b.y < y1 and b.y + b.h > y0
  let boxes = ()
  boxes += model.nodes.map(n => n.bounds).filter(hit)
  boxes += model.nodes.filter(n => "label" in n).map(n => n.label).filter(hit)
  boxes += model.flows.filter(f => "label" in f).map(f => f.label).filter(hit)
  let xs = boxes.map(b => (b.x, b.x + b.w)).flatten()
  // `flatten` là đệ quy, mà waypoint tự nó là một cặp — nên lấy hoành độ *trước* khi trải.
  xs += model.flows
    .map(f => f
      .at("waypoints", default: ())
      .filter(w => w.at(1) >= y0 and w.at(1) <= y1)
      .map(w => w.at(0)))
    .flatten()
  if xs.len() == 0 { none } else { (calc.min(..xs), calc.max(..xs)) }
}

/// Tính kế hoạch trải trang mà không vẽ gì.
///
/// Vì sao phải cắt cả hai chiều: một collaboration L3 cao 1200 đơn vị, mà chiều cao
/// dùng được của một trang A4 xoay ngang chỉ ~178mm. Muốn nhãn đạt 6pt thì cần
/// 1200 × 6/11 = 654pt = 231mm — **cao hơn cả tờ giấy**. Thêm bao nhiêu trang ngang
/// cũng vô ích: ràng buộc nằm ở chiều dọc.
///
/// Trả về `(cols, rows, pages, row-bounds, x-starts, u, label-size, header-w, capped)`.
#let bpmn-sheet-plan(
  model,
  avail: (width: 257mm, height: 178mm),
  max-pages: 4,
  min-font: 6pt,
  overlap: 30,
  header: true,
) = {
  let e = model.meta.extent
  let font-size = 11
  let u-want = min-font / font-size
  let cuts = _band-cuts(model)
  let hw = if header { _header-width(model) } else { 0.0 }

  // Một dải không chia nhỏ hơn được nữa, nên dải cao nhất đặt trần cứng cho tỉ lệ.
  let tallest-band = calc.max(..range(cuts.len() - 1).map(j => cuts.at(j + 1) - cuts.at(j)))
  let u = calc.min(u-want, avail.height / tallest-band)

  // Với một tỉ lệ cho trước: cột đầu chỉ mang sẵn dải tên khi nó bắt đầu từ mép trái
  // của bản vẽ; mọi cột khác phải chừa chỗ lặp lại dải đó.
  //
  // Đếm số cột theo kiểu tham lam, rồi *chia đều lại*. Chỉ tham lam thôi thì cột cuối
  // thường chỉ còn một mẩu: hai cột đầy và một cột chứa đúng hai cái hộp. Chia đều cho
  // ba cột bằng nhau đọc dễ hơn hẳn, và không tốn thêm trang nào.
  let cols-for(u, lo, hi) = {
    let tile = avail.width / u
    let n = 1
    let end = lo + (if lo > e.x { calc.max(1.0, tile - hw) } else { tile })
    while end < hi and n < 40 {
      end = end - overlap + calc.max(1.0, tile - hw)
      n += 1
    }
    let step = (hi - lo) / n
    range(n).map(k => (
      x0: if k == 0 { lo } else { lo + k * step - overlap },
      x1: if k + 1 == n { hi } else { lo + (k + 1) * step },
    ))
  }

  // Một hàng = một dải ngang, kèm bề ngang của riêng nó. Hàng rỗng bị bỏ hẳn.
  let pad = 20.0
  let layout-for(u) = {
    let bounds = _pack-rows(cuts, avail.height / u)
    let out = ()
    for r in range(bounds.len() - 1) {
      let (y0, y1) = (bounds.at(r), bounds.at(r + 1))
      let sp = _row-x-span(model, y0, y1)
      if sp == none { continue }
      // Mép trái của hàng: hoặc đúng gốc bản vẽ (khung nhìn tự mang dải tên), hoặc hẳn
      // ra ngoài dải tên (khung nhìn được dán dải tên vào). Rơi vào *giữa* dải tên thì
      // trang in ra tên pool hai lần — một lần ở dải dán, một lần trong phần thân.
      let raw-lo = sp.at(0) - pad
      let lo = if raw-lo < e.x + hw { e.x } else { raw-lo }
      let hi = calc.min(e.x + e.w, sp.at(1) + pad)
      out.push((y0: y0, y1: y1, lo: lo, hi: hi, xs: cols-for(u, lo, hi)))
    }
    out
  }
  let pages-of(rows) = rows.map(r => r.xs.len()).sum(default: 0)

  // Thu tỉ lệ dần cho tới khi lọt trần trang. Thu tỉ lệ làm *cả hai* chiều bớt trang,
  // nên vòng lặp chắc chắn dừng.
  let rows = layout-for(u)
  let guard = 0
  while pages-of(rows) > max-pages and guard < 60 {
    u = u * 0.94
    rows = layout-for(u)
    guard += 1
  }

  (
    cols: calc.max(1, ..rows.map(r => r.xs.len())),
    rows: rows.len(),
    pages: pages-of(rows),
    bands: rows,
    u: u,
    label-size: font-size * u,
    header-w: hw,
    capped: u < u-want,
  )
}

// MARK: bpmn-sheet
//
// src         model đã nạp, `yaml(..)`, hoặc `xml("..bpmn")` — nạp thẳng .bpmn được
// caption     dùng chung mọi trang; thứ tự và vị trí được nối vào cuối
// label       chỉ gắn vào trang ĐẦU, để `@nhãn` trong chương trỏ tới chỗ bắt đầu
// max-pages   trần số trang; vượt thì thu tỉ lệ thay vì trải thêm
// min-font    cỡ chữ nhắm tới; `debug: true` cho biết có đạt không
// overlap     dải chồng lấn giữa hai cột, tính bằng đơn vị BPMN
// header      lặp lại dải tên pool/lane ở các cột sau
#let bpmn-sheet(
  src,
  caption: none,
  label: none,
  max-pages: 4,
  min-font: 6pt,
  overlap: 30,
  header: true,
  margin: (x: 12mm, y: 10mm),
  theme: default-theme,
  supplement: auto,
  kind: image,
  // (thứ tự, tổng, cột, hàng, số cột, số hàng) — vị trí chỉ nói ra khi lưới chia theo
  // cả hai chiều; "1/4" một mình không cho biết mảnh này nằm ở đâu trong bản vẽ.
  part-format: (i, n, c, r, cols, rows) => {
    if n <= 1 { [] } else if rows <= 1 or cols <= 1 { [ (#i/#n)] } else {
      let ngang = if c == 0 { "trái" } else if c + 1 == cols { "phải" } else { "giữa" }
      let doc = if r == 0 { "trên" } else if r + 1 == rows { "dưới" } else { "giữa" }
      [ (#i/#n — #doc #ngang)]
    }
  },
  seam: true,
  debug: false,
) = {
  let model = bpmn-model(src)
  let e = model.meta.extent

  let cap = caption
  if cap == none {
    let m = model.meta
    let t = m.at("caption", default: m.at("title", default: ""))
    if t != "" { cap = bp-text(t) }
  }

  // Không dùng `layout`: `pagebreak` bị cấm trong container, mà mỗi ô phải là một
  // trang riêng. `context` đọc khổ giấy rồi phát ra n lệnh `page()` — mỗi lệnh mở
  // đúng một trang, khỏi cần ngắt trang thủ công.
  context {
    // Trang xoay ngang: bề rộng lấy từ chiều cao khổ gốc và ngược lại.
    let (mx, my) = (margin.at("x", default: 12mm), margin.at("y", default: 10mm))
    let avail-w = page.height - 2 * mx
    let cap-h = if cap == none { 0pt } else {
      measure(box(width: avail-w, cap)).height + 1.6 * text.size
    }
    let avail = (width: avail-w, height: page.width - 2 * my - cap-h)

    let plan = bpmn-sheet-plan(
      model,
      avail: avail,
      max-pages: max-pages,
      min-font: min-font,
      overlap: overlap,
      header: header,
    )

    // Vẽ MỘT lần ở tỉ lệ đã chốt; mỗi trang chỉ là một khung nhìn lên bản vẽ đó.
    let sheet = draw-canvas(model, plan.u, theme)
    let seam-stroke = (
      paint: theme.at("label", default: black).lighten(50%),
      thickness: 0.5pt,
      dash: "dashed",
    )
    // `draw-canvas` đã dịch bản vẽ về gốc extent, nên khung nhìn phải trừ đi gốc đó.
    // Quên trừ thì mọi ô lệch sang phải đúng `e.x` đơn vị và dải tên bị cắt cụt — lỗi
    // im lặng, vì hình vẫn ra hình, chỉ là thiếu mất phần lề trái.
    let win(x0, w-u, y0, h-u) = box(
      width: w-u * plan.u,
      height: h-u * plan.u,
      clip: true,
      place(dx: -(x0 - e.x) * plan.u, dy: -(y0 - e.y) * plan.u, sheet),
    )

    let i = 0
    for (ri, band) in plan.bands.enumerate() {
      let y0 = band.y0
      let h-u = band.y1 - y0
      let h = h-u * plan.u
      let ncols = band.xs.len()

      for c in range(ncols) {
        let x0 = band.xs.at(c).x0
        let avail-u = avail.width / plan.u
        // Dải tên chỉ thừa khi khung nhìn đã bắt đầu từ đúng mép trái của bản vẽ.
        let strip-w = if x0 <= e.x { 0.0 } else { plan.header-w }
        let body-w = calc.min(avail-u - strip-w, band.xs.at(c).x1 - x0)
        let w = (strip-w + body-w) * plan.u

        // Cột sau cột đầu: dán lại dải tên pool/lane vào mép trái, như khoá cột của
        // bảng tính. Đây là hai khung nhìn lên *cùng một* bản vẽ, nên tên và hộp chắc
        // chắn cùng tỉ lệ và cùng hàng.
        let strip = if strip-w <= 0 { none } else { win(e.x, plan.header-w, y0, h-u) }
        let content = win(x0, body-w, y0, h-u)
        let x-body = strip-w * plan.u

        let marks = {
          if seam and c > 0 {
            place(dx: x-body + overlap * plan.u, line(length: h, angle: 90deg, stroke: seam-stroke))
          }
          if seam and c + 1 < ncols {
            place(dx: w - overlap * plan.u, line(length: h, angle: 90deg, stroke: seam-stroke))
          }
          // Mối nối giữa dải tên và phần thân: kẻ đặc, vì đó là chỗ bản vẽ bị ghép lại.
          if strip != none {
            place(dx: x-body, line(
              length: h,
              angle: 90deg,
              stroke: 0.5pt + theme.at("pool-stroke", default: black),
            ))
          }
        }

        let note = if debug {
          align(right, text(size: 6pt, fill: rgb("#b00"), [
            #(i + 1)/#plan.pages · hàng #(ri + 1)/#plan.rows, cột #(c + 1)/#ncols ·
            nhãn #calc.round(plan.label-size / 1pt, digits: 2)pt ·
            x #calc.round(x0)–#calc.round(x0 + body-w) / #calc.round(e.w) ·
            y #calc.round(y0)–#calc.round(y0 + h-u)
          ]))
        }
        let c-txt = if cap == none { none } else {
          cap + part-format(i + 1, plan.pages, c, ri, ncols, plan.rows)
        }
        let fig = figure(
          // Cả dải tên lẫn phần thân đều phải `place`. Để dải tên chảy theo dòng rồi
          // mới `place` phần thân thì `place` lấy mốc là vị trí *sau* dải tên, và cả
          // trang trượt đi — đã dính.
          align(center, box(width: w, height: h, {
            if strip != none { place(dx: 0pt, dy: 0pt, strip) }
            place(dx: x-body, dy: 0pt, content)
            marks
          })) + note,
          caption: c-txt,
          kind: kind,
          supplement: supplement,
        )
        // `v(1fr)` hai đầu: một dải ngang thấp hơn khổ giấy thì nằm giữa trang chứ không
        // treo ở mép trên với một khoảng trắng dài bên dưới chú thích.
        page(flipped: true, margin: margin, {
          v(1fr)
          if i == 0 and label != none { [#fig#label] } else { fig }
          v(1fr)
        })
        i += 1
      }
    }
  }
}
