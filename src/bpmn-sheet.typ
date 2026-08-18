// src/bpmn-sheet.typ
// Trải một mô hình BPMN **nguyên vẹn** ra nhiều trang, kiểu bản đồ gấp.
//
// Vì sao cần: một collaboration Level 3 là hình băng — rộng gấp đôi tới gấp ba chiều
// cao. Ép nó vào bề rộng chữ A4 thì nhãn rơi xuống 2–4pt. Trong chương, lời giải là
// *cắt lát*: `bpmn-lane`, `bpmn-span`, `bpmn-part` — mỗi hình trả lời một câu hỏi. Nhưng
// người đọc vẫn cần một chỗ nhìn thấy **toàn bộ** mô hình, và đó là việc của phụ lục.
//
// Cách làm: vẽ mô hình *một lần* ở tỉ lệ đọc được, rồi cắt thành từng ô cửa sổ, mỗi ô
// một trang. Khác hẳn `bpmn-span`:
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
//      nó, trang 2 là một rừng hộp không ai biết của bộ phận nào. Tắt được bằng
//      `repeat-header: false` khi dải tên chiếm chỗ hơn là giúp được: mô hình mà mỗi
//      lane chỉ có một hai bước thì cứ theo mũi tên vào/ra là biết mình đang ở đâu.
//   3. **Chồng lấn** một dải giữa hai cột (`overlap`, đơn vị BPMN), kèm vạch đứt đánh
//      dấu. Không có nó, một task nằm đúng chỗ cắt bị chẻ đôi và không trang nào đọc được.
//   4. **Mỗi hàng cắt cột theo phần có nội dung của riêng nó.** Một lưới cột dùng chung
//      cho mọi hàng nghe gọn hơn, nhưng hàng dưới của một mô hình thường chỉ có vài hộp
//      ở mép trái — dùng chung lưới thì sinh ra một trang gần như trắng. Tỉ lệ vẫn là
//      một cho cả bản vẽ, nên vẫn so được; chỉ có số cột là khác nhau giữa các hàng.
//   5. **Xoay bản vẽ, không xoay tờ giấy.** Trang vẫn dọc như mọi trang khác của tài
//      liệu; mảnh bản vẽ mới là thứ quay một phần tư vòng, đúng cách `bpmn-figure` tự
//      xoay khi hình quá rộng so với cột chữ. Hai cái lợi, và cái thứ hai mới là cái
//      chính:
//        · Chiều dài của mô hình được chiếu lên chiều *cao* trang (277mm ở A4 thay vì
//          186mm), còn chiều cao mô hình chiếu lên bề ngang — mỗi trang ôm được nhiều
//          hơn theo cả hai chiều so với khi lật ngang tờ giấy.
//        · Tệp PDF không còn trộn hai khổ trang. Trang lật ngang làm hỏng thứ tự đọc
//          khi in hai mặt và làm lệch phần header/footer của tài liệu.
//      Chiều xoay là *thuận* kim đồng hồ, ngược với `sidewaysfigure` của LaTeX, và đó
//      là chỗ duy nhất bộ này đi chệch quy ước cũ. Lý do nằm ở việc nối trang: xoay
//      thuận thì trục x của mô hình chạy *xuống* trang, nên dòng chảy đi hết trang này
//      là sang đầu trang sau — đúng chiều lật giấy. Xoay ngược thì dòng chảy đi từ dưới
//      lên, và trang sau lại bắt đầu ở đáy: đầu trang này nối vào đít trang kia. Chú
//      thích quay cùng bản vẽ, nên xoay tờ giấy ngược kim đồng hồ là đọc được cả hai.
//
// Author: Sam Dinh
// Version: 0.3.0
// License: MIT
//
// API công khai:
//   - bpmn-sheet(src, ..)       : phát ra n trang, mỗi trang một figure đã xoay.
//   - bpmn-sheet-plan(model, ..): chỉ tính toán (lưới, tỉ lệ, cỡ chữ) — không vẽ.
//   - bpmn-sheet-info(src, ..)  : ngân sách trang của một mô hình — cần bao nhiêu
//                                 trang ở mỗi cỡ chữ, và phải cắt bớt bao nhiêu đơn
//                                 vị bề rộng để tròn n trang. Không vẽ gì.

#import "bpmn.typ": bpmn-model
// Đổi tên khi nạp: `compact` cũng là tên tham số của `bpmn-sheet`, và trong thân hàm
// thì tham số che mất hàm.
#import "bpmn-compact.typ": compact as compact-model
#import "bpmn-render.typ": draw-canvas, default-theme
#import "bptext.typ": bp-text

// Bề rộng dải tên bên trái: dải tên pool cộng dải tên lane (nếu pool có lane).
// Suy từ chính bản vẽ chứ không phải hằng số — pool không lane chỉ có một dải.
//
// Đo từ `extent.x`, KHÔNG phải từ mép pool. Khung nhìn cắt dải tên bắt đầu ở gốc
// extent, mà gốc extent lùi ra trước mép pool đúng một khoảng đệm; đo từ mép pool rồi
// áp từ gốc extent thì dải bị hụt đúng khoảng đệm đó, và chữ tên lane — vốn căn giữa
// dải 30 đơn vị của nó — rơi ngay lên đường ghép. Đã dính.
#let _band = 30.0 // bề rộng dải tên pool/lane, khớp `_band` của bpmn-render
#let _header-width(model) = {
  let e = model.meta.extent
  let pools = model.pools.filter(p => "bounds" in p)
  if pools.len() == 0 { return _band }
  let px = calc.min(..pools.map(p => p.bounds.x))
  let lanes = pools.map(p => p.at("lanes", default: ())).flatten().filter(l => "bounds" in l)
  let inner = if lanes.len() == 0 { px } else { calc.min(..lanes.map(l => l.bounds.x)) }
  (inner + _band) - e.x
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
#let _row-has-node(model, y0, y1) = {
  model.nodes.any(n => n.bounds.y < y1 and n.bounds.y + n.bounds.h > y0)
}

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
/// `avail` đo theo **trục của mô hình**, không theo trục tờ giấy: `width` là chỗ dành
/// cho chiều dài mô hình, `height` cho chiều cao mô hình. Vì bản vẽ được xoay một phần
/// tư vòng, `width` lấy từ chiều *cao* trang và `height` lấy từ bề *ngang* trang —
/// người gọi lo việc đổi trục đó, ở đây chỉ có toạ độ BPMN.
///
/// Vì sao phải cắt cả hai chiều: một collaboration L3 cao 1200 đơn vị, mà bề ngang
/// dùng được của một trang A4 dọc chỉ ~186mm. Muốn nhãn đạt 6pt thì cần
/// 1200 × 6/11 = 654pt = 231mm — **rộng hơn cả tờ giấy**. Thêm bao nhiêu trang nối
/// tiếp cũng vô ích: ràng buộc nằm ở chiều cao mô hình.
///
/// Trả về `(cols, rows, pages, bands, u, label-size, header-w, capped)`.
#let bpmn-sheet-plan(
  model,
  avail: (width: 277mm, height: 186mm),
  max-pages: 4,
  min-font: 6pt,
  overlap: 30,
  repeat-header: true,
) = {
  let e = model.meta.extent
  let font-size = 11
  let u-want = min-font / font-size
  let cuts = _band-cuts(model)
  // Hai con số khác nhau, và lẫn chúng là hỏng.
  //   `hdr` — bề rộng dải tên mà *bản vẽ vốn đã có* ở mép trái. Luôn tồn tại, không
  //           phụ thuộc tuỳ chọn nào; nó là một phần của hình.
  //   `hw`  — bề rộng dải tên mà mình *dán thêm* vào các trang sau. Bằng 0 khi tắt.
  // Dùng `hw` cho cả hai việc thì tắt `repeat-header` sẽ kéo mép trái của trang đầu
  // vào tận chỗ có nội dung, xén mất chính dải tên gốc — tắt lặp lại hoá ra xoá luôn
  // bản chính.
  let hdr = _header-width(model)
  let hw = if repeat-header { hdr } else { 0.0 }

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

  // Một hàng = một dải ngang, kèm bề ngang của riêng nó.
  //
  // Trước khi tính bề ngang, gộp những dải *không có phần tử nào* vào dải liền trên.
  // Điển hình là băng black box: message flow chạy tới mép pool để lại một waypoint,
  // đủ để dải đó "có nội dung" theo nghĩa toạ độ, nhưng in ra là một trang chỉ có
  // khung rỗng và một dòng chú thích. Gộp lên trên thì băng vẫn hiện, đúng chỗ nó
  // thuộc về — ngay dưới phần đã gửi thông điệp cho nó.
  let pad = 20.0
  let merge-empty(bounds, maxh) = {
    let out = (bounds.first(),)
    for r in range(bounds.len() - 1) {
      let (y0, y1) = (bounds.at(r), bounds.at(r + 1))
      let empty = not _row-has-node(model, y0, y1)
      if empty and out.len() > 1 and y1 - out.at(out.len() - 2) <= maxh {
        out.at(out.len() - 1) = y1
      } else {
        out.push(y1)
      }
    }
    out
  }
  let layout-for(u) = {
    let maxh = avail.height / u
    let bounds = merge-empty(_pack-rows(cuts, maxh), maxh)
    let out = ()
    for r in range(bounds.len() - 1) {
      let (y0, y1) = (bounds.at(r), bounds.at(r + 1))
      let sp = _row-x-span(model, y0, y1)
      if sp == none or not _row-has-node(model, y0, y1) { continue }
      // Mép trái của hàng: hoặc đúng gốc bản vẽ (khung nhìn tự mang dải tên), hoặc hẳn
      // ra ngoài dải tên (khung nhìn được dán dải tên vào). Rơi vào *giữa* dải tên thì
      // trang in ra tên pool hai lần — một lần ở dải dán, một lần trong phần thân.
      let raw-lo = sp.at(0) - pad
      let lo = if raw-lo < e.x + hdr { e.x } else { raw-lo }
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

  // Rồi nở ngược lại cho *hết* chỗ đang có, miễn không sinh thêm một trang nào.
  //
  // `min-font` là mức sàn, không phải mức trần: một mô hình thấp và ngắn dừng ở đúng
  // 6pt sẽ để trống nửa bề ngang trang, trong khi cùng số trang đó nó có thể vẽ to hơn.
  // Điều kiện dừng là *số trang không đổi* chứ không phải "còn dưới max-pages" — nếu
  // không, một mô hình vốn gọn trong 1 trang sẽ tự phình ra thành 4.
  let target = pages-of(rows)
  let grow = 0
  while grow < 40 and u < 1pt {
    let u2 = calc.min(u * 1.03, 1pt)
    if u2 * tallest-band > avail.height { break }
    let r2 = layout-for(u2)
    if pages-of(r2) > target { break }
    u = u2
    rows = r2
    grow += 1
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

// MARK: bpmn-sheet-info
//
/// Ngân sách trang của một mô hình, không vẽ gì.
///
/// Vì sao có hàm này: Camunda Modeler không có lưới trang như DrawIO, nên trong lúc
/// dựng mô hình không ai biết mình đang tiêu bao nhiêu tờ A4. Kết quả là bản vẽ hay
/// rộng hơn mức cần, và chỉ lộ ra khi đã đem vào tài liệu. Đây là chỗ trả lời trước:
/// ở mỗi cỡ chữ thì hết mấy trang, và phải bớt bao nhiêu đơn vị bề rộng để tròn n trang.
///
/// Số "bớt bao nhiêu" là thứ mang về Modeler dùng được: một task cỡ 100 đơn vị, một
/// khoảng thở giữa hai bước cỡ 40--60, nên "bớt 250" đọc ra là "kéo hai ba bước lại
/// gần nhau" chứ không phải một con số trừu tượng.
///
/// Trả về:
///   extent      (w, h) của bản vẽ, đơn vị BPMN
///   sizes       mỗi cỡ chữ một dòng: (font, cols, rows, pages, label-size, capped)
///   width-fit   ép mọi pool/lane vào một bề ngang trang: (u, label-size, pages)
///   trim        với n = 1..4 cột: cần bớt bao nhiêu đơn vị bề rộng để vừa n trang
///               (âm nghĩa là còn thừa chỗ)
#let bpmn-sheet-info(
  src,
  avail: (width: 277mm, height: 178mm),
  sizes: (6pt, 7pt, 8pt),
  max-pages: 4,
  overlap: 30,
  repeat-header: true,
  compact: none,
) = {
  let model = bpmn-model(src)
  if compact != none and compact != false {
    model = compact-model(model, opts: if type(compact) == dictionary { compact } else { (:) })
  }
  let e = model.meta.extent
  let hdr = _header-width(model)
  let hw = if repeat-header { hdr } else { 0.0 }

  let rows = sizes.map(f => {
    let p = bpmn-sheet-plan(
      model,
      avail: avail,
      max-pages: max-pages,
      min-font: f,
      overlap: overlap,
      repeat-header: repeat-header,
    )
    (font: f, cols: p.cols, rows: p.rows, pages: p.pages, label-size: p.label-size, capped: p.capped)
  })

  // Mọi lane trên một bề ngang: tỉ lệ do chiều cao mô hình quyết, không phải cỡ chữ.
  let u-fit = avail.height / e.h
  let width-fit = (
    u: u-fit,
    label-size: 11 * u-fit,
    pages: e.w * u-fit / avail.width,
  )

  // Sức chứa theo bề rộng khi đã chốt một tỉ lệ: cột đầu ôm trọn một tờ, mỗi cột sau
  // mất phần dải tên dán lại và phần chồng lấn.
  let capacity(u, n) = {
    let tile = avail.width / u
    tile + (n - 1) * calc.max(1.0, tile - hw - overlap)
  }
  let u-ref = if rows.len() == 0 { u-fit } else { rows.first().label-size / 11 }
  let trim = range(1, 5).map(n => (n: n, units: e.w - capacity(u-ref, n)))

  (extent: (w: e.w, h: e.h), header-w: hdr, sizes: rows, width-fit: width-fit, trim: trim, u-ref: u-ref)
}

// MARK: bpmn-sheet
//
// src         model đã nạp, `yaml(..)`, hoặc `xml("..bpmn")` — nạp thẳng .bpmn được
// caption     dùng chung mọi trang; thứ tự và vị trí được nối vào cuối
// label       chỉ gắn vào trang ĐẦU, để `@nhãn` trong chương trỏ tới chỗ bắt đầu
// max-pages   trần số trang; vượt thì thu tỉ lệ thay vì trải thêm
// min-font    cỡ chữ nhắm tới; `debug: true` cho biết có đạt không
// overlap     dải chồng lấn giữa hai cột, tính bằng đơn vị BPMN
// repeat-header  dán lại dải tên pool/lane vào mép mỗi trang sau trang đầu
// compact     gấp các dải trống lại trước khi trải (xem bpmn-compact). `none` là mặc
//             định và là điều đúng cho phụ lục: phụ lục hứa chiếu *nguyên bản*, mà
//             compact có đụng vào toạ độ. Bật khi mô hình rộng rãi quá mức cần thiết
//             — hình và chữ giữ nguyên kích thước, chỉ khoảng trống nhỏ lại.
//
//             Đáng nói: với mô hình vẽ tay trong Camunda Modeler thì `compact: true`
//             (mặc định `axis: "x"`) gần như không được gì — 0--2% bề rộng, vì các
//             bước đã nằm sát nhau theo chiều ngang. Chỗ có mỡ là chiều *dọc*: lane
//             cao gấp mấy lần hàng phần tử nằm trong nó. `compact: (axis: "both")`
//             lấy lại 25--30% chiều cao trên sáu mô hình L3 của Hồng Hà, đủ để gộp
//             lưới 2 hàng thành 1 và bớt hẳn một trang.
// turn        chiều xoay bản vẽ. "cw" (mặc định) cho trục x chạy xuống trang, để các
//             trang nối nhau đúng chiều lật giấy; "ccw" theo quy ước sidewaysfigure
// chrome      giữ header/footer/số trang của tài liệu; `false` để nhường chỗ cho hình
#let bpmn-sheet(
  src,
  caption: none,
  label: none,
  max-pages: 4,
  min-font: 6pt,
  overlap: 30,
  repeat-header: true,
  compact: none,
  turn: "cw",
  chrome: true,
  margin: (x: 12mm, y: 10mm),
  theme: default-theme,
  supplement: auto,
  kind: image,
  // (thứ tự, tổng, cột, hàng, số cột, số hàng) — vị trí chỉ nói ra khi lưới chia theo
  // cả hai chiều; "1/4" một mình không cho biết mảnh này nằm ở đâu trong bản vẽ.
  part-format: (i, n, c, r, cols, rows) => {
    if n <= 1 { return [] }
    // Số cột khác nhau giữa các hàng, nên phải xét riêng từng chiều: một hàng chỉ có
    // một cột vẫn cần biết nó là hàng trên hay hàng dưới.
    let ngang = if cols <= 1 { () } else if c == 0 { ("trái",) } else if c + 1 == cols {
      ("phải",)
    } else { ("giữa",) }
    let doc = if rows <= 1 { () } else if r == 0 { ("trên",) } else if r + 1 == rows {
      ("dưới",)
    } else { ("giữa",) }
    let vt = (doc + ngang).join(" ")
    if vt == none { [ (#i/#n)] } else { [ (#i/#n -- #vt)] }
  },
  seam: true,
  debug: false,
) = {
  let model = bpmn-model(src)
  if compact != none and compact != false {
    model = compact-model(model, opts: if type(compact) == dictionary { compact } else { (:) })
  }
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
    // Đổi trục: bản vẽ xoay một phần tư vòng, nên chiều *dài* mô hình ăn vào chiều cao
    // trang, còn chiều *cao* mô hình ăn vào bề ngang trang. Chú thích quay cùng hình
    // nên nó cũng nằm dọc theo bề ngang trang — trừ vào cùng ngân sách đó.
    let (mx, my) = (margin.at("x", default: 12mm), margin.at("y", default: 10mm))
    let avail-w = page.height - 2 * my
    let cap-h = if cap == none { 0pt } else {
      measure(box(width: avail-w, cap)).height + 1.6 * text.size
    }
    let avail = (width: avail-w, height: page.width - 2 * mx - cap-h)

    let plan = bpmn-sheet-plan(
      model,
      avail: avail,
      max-pages: max-pages,
      min-font: min-font,
      overlap: overlap,
      repeat-header: repeat-header,
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
        // Nhãn phải gắn vào chính `figure`, không gắn ngoài: cái ở ngoài cùng là một
        // `rotate`, mà `@nhãn` trỏ vào `rotate` sẽ báo "cannot reference rotate".
        let tagged = if i == 0 and label != none { [#fig#label] } else { fig }

        // Xoay cả cụm hình-và-chú-thích như một khối. Chú thích để ngang trong khi hình
        // nằm dọc sẽ ăn hai lần vào bề ngang trang: một lần cho chính nó, một lần cho
        // dải mà phép xoay không dùng tới.
        let turned = rotate(
          if turn == "cw" { 90deg } else { -90deg },
          reflow: true,
          box(width: w, tagged),
        )
        // `chrome: false` trả lại chỗ của header/footer cho hình. Số trang cũng tắt
        // theo — một trang không có header thì số trang mồ côi ở giữa lề trông như lỗi.
        let bare = if chrome { (:) } else {
          (header: none, footer: none, numbering: none, background: none, foreground: none)
        }
        // `v(1fr)` hai đầu: mảnh ngắn hơn khổ giấy thì nằm giữa trang chứ không treo ở
        // mép trên với một khoảng trắng dài bên dưới.
        page(margin: margin, ..bare, {
          v(1fr)
          align(center, turned)
          v(1fr)
        })
        i += 1
      }
    }
  }
}
