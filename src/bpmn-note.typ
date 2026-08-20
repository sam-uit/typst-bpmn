// /template/components/bpmn-note.typ
// Chú giải đặt chồng lên sơ đồ BPMN, tự tìm chỗ trống.
//
// `bpmn-figure` vẽ đúng những gì Camunda Modeler thấy, không có chỗ cho lời bình của
// người phân tích. Component này vẽ lại cùng một lát cắt rồi dùng `place` để gắn các ô
// chú giải neo vào từng node, kèm đường dẫn nối.
//
// Chỗ đặt ô chú giải KHÔNG do người viết tính tay. Mỗi ô là một cá thể trong một quần
// thể chịu chung vài luật, theo tinh thần mô hình boids của Craig Reynolds: bản thân ô
// chú giải là "dummy", trật tự nổi lên từ các luật chứ không từ toạ độ chỉ định sẵn.
//
//   1. Containment: không được ra khỏi khung sơ đồ. Ô chú giải chỉ dùng không gian
//      *bên trong* kích thước sơ đồ, không mượn lề của figure.
//   2. Avoidance  : tránh đè lên shape, lên nhãn của shape, và (nhẹ hơn) lên nét vẽ
//      của các dòng chảy.
//   3. Separation : các ô chú giải tránh đè lên nhau.
//   4. Cohesion   : trong các chỗ hợp lệ, chọn chỗ gần node được chú giải nhất.
//   5. Alignment  : khi điểm số ngang nhau thì ưu tiên cùng một phía (dưới → trên →
//      phải → trái) để cả trang trông có nhịp.
//   6. Distinctness: đường dẫn tránh nằm đúng phương ngang hoặc dọc. Cung BPMN chạy
//      vuông góc; một đường dẫn dọc kẻ ngay dưới node sẽ biến mất vào chính cái cung
//      đi ra từ node đó. Vì luật này mà bốn *góc* cũng là chỗ đặt hợp lệ, không chỉ
//      bốn phía. Tắt bằng `diagonal: false`.
//
// Hệ quả tự nhiên: node sát mép dưới thì ô chú giải nhảy lên trên, node sát mép phải thì
// ô nhảy sang trái: không cần khai báo gì thêm.
//
// Người viết vẫn thắng máy: khai `side` thì chỉ tìm trong phía đó, khai thêm `dx`/`dy`
// thì đặt đúng chỗ được chỉ định và bỏ qua toàn bộ phần tìm kiếm.
//
// Author: Sam Dinh
// Version: 0.2.0
// License: MIT
//
// API công khai:
//   - bpmn-notes(src, notes: (..), ..) : Sơ đồ kèm chú giải, trả về figure.

#import "bpmn.typ": bpmn-model, bpmn-slice, bpmn-at, compact, default-theme
#import "noteplace.typ": np-rect, np-anchor, np-solve, np-defaults

// Ghi lại ở cấp module: tham số cùng tên sẽ che mất bản toàn cục.
#let bn-place = place
#let bn-figure = figure
#let bn-compact = compact

// Tìm node theo id hoặc theo tên hiển thị.
#let bn-find(model, key) = {
  let hit = model.nodes.find(n => n.id == key)
  if hit != none { return hit }
  model.nodes.find(n => n.at("name", default: "") == key)
}

// MARK: Component
#let bpmn-notes(
  src,
  // Mỗi chú giải: (node: "id|tên", body: [...], side: auto|"top"|"bottom"|"left"|"right",
  //                dx: 0mm, dy: 0mm, color: none, width: none)
  //   - không khai gì  -> tự tìm chỗ theo 5 luật ở đầu file
  //   - khai `side`    -> chỉ tìm trong phía đó
  //   - khai `dx`/`dy` -> đặt đúng chỗ chỉ định, không tìm kiếm
  notes: (),
  view: none,
  compact: true,
  theme: default-theme,
  caption: none,
  label: none,
  // `auto` = để show-set rule của template quyết định (trong báo cáo này là "Hình ảnh")
  supplement: auto,
  // Bề rộng ô chú giải; số nhỏ giữ chú giải gọn để còn chỗ trống mà len vào
  note-width: 34mm,
  note-size: 7.5pt,
  note-fill: rgb("#FFFDF2"),
  note-stroke: rgb("#B26A00"),
  note-inset: 4pt,
  // Khoảng hở tối thiểu giữa node và ô chú giải
  gap: 3mm,
  // Chừa mép trong khung sơ đồ, để ô chú giải không dính vào đường viền
  edge-pad: 1.2mm,
  // Trọng số của các luật (chỉnh khi một sơ đồ cụ thể cần ưu tiên khác).
  // `out` cố tình lớn hơn hẳn phần còn lại: ra khỏi khung là điều kiện loại, không phải
  // một khoản trừ điểm có thể bù bằng ưu điểm khác.
  weights: np-defaults,
  // Cho ô chú giải đặt được ở bốn góc của vật neo, và phạt đường dẫn nằm đúng phương
  // ngang/dọc. Xem luật 6 trong noteplace.typ. Tắt thì quay về đúng bốn phía.
  diagonal: true,
  breakable: false,
  debug: false,
) = {
  let comp = compact
  let m = {
    let base = bpmn-slice(bpmn-model(src), view)
    if comp == none or comp == false { base } else {
      bn-compact(base, opts: if type(comp) == dictionary { comp } else { (:) })
    }
  }
  let e = m.meta.extent

  let body = layout(avail => {
    let cw = avail.width
    let u = cw / e.w
    let ch = e.h * u
    // pt trên một đơn vị BPMN: đổi hết sang float để tính diện tích chồng lấn
    let U = u.pt()
    let W = cw.pt()
    let H = ch.pt()
    let px(v) = (v - e.x) * U
    let py(v) = (v - e.y) * U
    let box-of(b) = np-rect(px(b.x), py(b.y), b.w * U, b.h * U)

    // --- Luật 2: những gì phải tránh -------------------------------------
    // Cứng: shape và nhãn của shape. Mềm: nét vẽ của dòng chảy (đè lên vẫn đọc được).
    let hard = ()
    let soft = ()
    for p in m.pools {
      let b = p.bounds
      // Dải tiêu đề bên trái của pool/lane, chỗ có chữ dựng đứng
      hard.push(np-rect(px(b.x), py(b.y), calc.min(30.0, b.w) * U, b.h * U))
      for l in p.at("lanes", default: ()) {
        let lb = l.bounds
        hard.push(np-rect(px(lb.x), py(lb.y), calc.min(30.0, lb.w) * U, lb.h * U))
      }
    }
    for n in m.nodes {
      hard.push(box-of(n.bounds))
      let lb = n.at("label", default: none)
      if lb != none { hard.push(box-of(lb)) }
    }
    for f in m.at("flows", default: ()) {
      let lb = f.at("label", default: none)
      if lb != none { hard.push(box-of(lb)) }
      let wps = f.at("waypoints", default: ())
      for i in range(calc.max(0, wps.len() - 1)) {
        let a = wps.at(i)
        let b = wps.at(i + 1)
        let (ax, ay) = (a.at(0), a.at(1))
        let (bx, by) = (b.at(0), b.at(1))
        soft.push(np-rect(
          px(calc.min(ax, bx)) - 1.0,
          py(calc.min(ay, by)) - 1.0,
          calc.abs(bx - ax) * U + 2.0,
          calc.abs(by - ay) * U + 2.0,
        ))
      }
    }

    let ep = edge-pad.pt()
    let canvas = np-rect(ep, ep, W - 2 * ep, H - 2 * ep)

    // --- Dựng thẻ chú giải, rồi giao toạ độ cho bộ đặt chỗ dùng chung ---
    let cards = ()
    let specs = ()
    for nt in notes {
      let n = bn-find(m, nt.node)
      if n == none { continue }
      let col = nt.at("color", default: note-stroke)
      let card = block(
        width: nt.at("width", default: note-width),
        fill: note-fill,
        stroke: 0.5pt + col,
        radius: 2pt,
        inset: note-inset,
        text(size: note-size, fill: col.darken(20%), nt.body),
      )
      let cs = measure(card)
      let nb = box-of(n.bounds)
      cards.push((card: card, color: col, anchor: nb))
      specs.push((
        w: cs.width.pt(),
        h: cs.height.pt(),
        anchor: nb,
        side: nt.at("side", default: auto),
        fixed: if "dx" in nt or "dy" in nt {
          (nt.at("dx", default: 0mm).pt(), nt.at("dy", default: 0mm).pt())
        } else { none },
      ))
    }

    let rects = np-solve(
      canvas, hard, soft, specs,
      gap: gap.pt(), weights: weights, diagonal: diagonal,
    )

    block(width: cw, height: ch, {
      bn-place(top + left, bpmn-at(m, cw, theme: theme))

      if debug {
        for o in hard {
          bn-place(top + left, dx: o.x * 1pt, dy: o.y * 1pt,
            rect(width: o.w * 1pt, height: o.h * 1pt, stroke: 0.3pt + rgb("#00A0FF33")))
        }
      }

      for (i, c) in cards.enumerate() {
        let r = rects.at(i)
        let a = c.anchor
        // Nối cạnh gần nhau nhất của hai hình chữ nhật
        let (ax, ay) = np-anchor(a, r.x + r.w / 2, r.y + r.h / 2)
        let (bx, by) = np-anchor(r, a.x + a.w / 2, a.y + a.h / 2)
        bn-place(top + left, dx: ax * 1pt, dy: ay * 1pt, line(
          start: (0pt, 0pt),
          end: ((bx - ax) * 1pt, (by - ay) * 1pt),
          stroke: (paint: c.color, thickness: 0.5pt, dash: "dotted"),
        ))
        bn-place(top + left, dx: r.x * 1pt, dy: r.y * 1pt, c.card)
      }
    })
  })

  if caption == none {
    body
  } else {
    let fig = {
      show bn-figure: set block(breakable: breakable)
      bn-figure(
        body,
        caption: caption,
        kind: image,
        ..(if supplement == auto { (:) } else { (supplement: supplement) }),
      )
    }
    if label == none { fig } else { [#fig #label] }
  }
}
