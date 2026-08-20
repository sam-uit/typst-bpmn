// /template/components/noteplace.typ
// Bộ đặt chỗ cho chú giải: luật quần thể kiểu boids, dùng chung cho mọi loại sơ đồ.
//
// Bài toán: có một khung hình, một mớ vật cản (shape của sơ đồ), và vài ô chú giải cần
// neo vào một vật cản nào đó. Đặt chúng ở đâu?
//
// Cách làm: KHÔNG viết toạ độ cho từng ô, cũng KHÔNG viết if/else cho từng tình huống.
// Mỗi ô là một cá thể "dummy"; ta chỉ viết vài luật áp chung cho cả quần thể, và trật tự
// nổi lên từ tương tác giữa các luật, đúng tinh thần mô hình boids của Craig Reynolds.
//
//   1. Containment: không ra khỏi khung. Trọng số áp đảo, coi như điều kiện loại.
//   2. Avoidance  : tránh vật cản cứng (shape, nhãn) và mềm (nét nối).
//   3. Separation : các ô chú giải tránh đè lên nhau.
//   4. Cohesion   : trong các chỗ hợp lệ, chọn chỗ gần vật neo nhất.
//   5. Alignment  : điểm ngang nhau thì ưu tiên cùng một phía, cho cả trang có nhịp.
//
// Hệ quả tự nhiên: vật neo sát mép dưới thì ô nhảy lên trên, sát mép phải thì nhảy sang
// trái, hai ô cùng nhắm một chỗ thì ô sau né sang bên. Không có dòng if nào cho các ca đó.
//
// Mọi phép tính dùng float đơn vị pt: Typst không nhân được hai `length`, mà tính diện
// tích chồng lấn thì phải nhân.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - np-rect(x, y, w, h)                : Dựng một chữ nhật (float pt).
//   - np-overlap(a, b)                   : Diện tích giao nhau.
//   - np-anchor(rect, px, py)            : Điểm trên viền gần một điểm cho trước nhất.
//   - np-defaults                        : Trọng số mặc định.
//   - np-solve(..)                       : Giải bài toán đặt chỗ, trả về mảng chữ nhật.

#let np-rect(x, y, w, h) = (x: x, y: y, w: w, h: h)

#let np-overlap(a, b) = {
  let dx = calc.max(0.0, calc.min(a.x + a.w, b.x + b.w) - calc.max(a.x, b.x))
  let dy = calc.max(0.0, calc.min(a.y + a.h, b.y + b.h) - calc.max(a.y, b.y))
  dx * dy
}

#let np-sum-overlap(r, rects) = {
  let s = 0.0
  for o in rects { s += np-overlap(r, o) }
  s
}

#let np-anchor(r, px, py) = (
  calc.max(r.x, calc.min(r.x + r.w, px)),
  calc.max(r.y, calc.min(r.y + r.h, py)),
)

#let np-union(rects) = {
  if rects.len() == 0 { return none }
  let x0 = calc.min(..rects.map(r => r.x))
  let y0 = calc.min(..rects.map(r => r.y))
  let x1 = calc.max(..rects.map(r => r.x + r.w))
  let y1 = calc.max(..rects.map(r => r.y + r.h))
  np-rect(x0, y0, x1 - x0, y1 - y0)
}

// `out` cố tình lớn hơn hẳn phần còn lại: ra khỏi khung là điều kiện loại, không phải một
// khoản trừ điểm có thể bù bằng ưu điểm khác. Để nó ngang hàng thì ô sẽ chọn "ra ngoài một
// tí" thay vì "đè lên shape": đã mắc đúng lỗi này một lần.
#let np-defaults = (
  out: 5000.0,
  shape: 34.0,
  edge: 6.0,
  peer: 46.0,
  near: 0.016,
  side: 0.6,
  detach: 4.0,
  // Luật 6: Distinctness. Phạt đường dẫn nằm đúng phương ngang hoặc phương dọc.
  //
  // Cung BPMN chạy vuông góc, chỉ ngang và dọc. Ô chú giải đặt thẳng dưới một node thì
  // đường dẫn của nó cũng dọc, và nó biến mất vào đúng cái cung đi ra từ node đó,
  // người đọc không còn biết ô đang nói về ai. Đường chéo không trùng phương với thứ gì
  // trong bản vẽ, nên nó luôn đọc được. Đặt 0 để tắt.
  skew: 9.0,
)

#let np-sides = ("bottom", "top", "right", "left")

// Bốn góc. Cùng khoảng hở như bốn phía, nhưng lệch cả hai trục nên đường dẫn ra chừng
// 45 độ. Xếp sau bốn phía trong thứ tự ưu tiên: sát cạnh vẫn dễ đọc hơn nếu chỗ đó
// trống và đường dẫn không đụng cung nào.
#let np-diagonals = ("bottom-right", "bottom-left", "top-right", "top-left")

// Toạ độ góc trên-trái của ô, theo phía + độ lệch dọc theo cạnh + khoảng hở.
#let np-corner(a, nw, nh, side, off, g) = {
  let cx = a.x + a.w / 2
  let cy = a.y + a.h / 2
  if side == "bottom" {
    (cx + off - nw / 2, a.y + a.h + g)
  } else if side == "top" {
    (cx + off - nw / 2, a.y - g - nh)
  } else if side == "right" {
    (a.x + a.w + g, cy + off - nh / 2)
  } else if side == "left" {
    (a.x - g - nw, cy + off - nh / 2)
  } else {
    // Bốn góc: `off` trượt dọc theo chính đường chéo, chia đều cho hai trục.
    let d = off * 0.7
    let dx = if side.ends-with("right") { a.x + a.w + g + d } else { a.x - g - nw - d }
    let dy = if side.starts-with("bottom") { a.y + a.h + g + d } else { a.y - g - nh - d }
    (dx, dy)
  }
}

/// Giải bài toán đặt chỗ.
///
/// - canvas: khung được phép dùng (đã trừ mép trong)
/// - hard: vật cản cứng (shape, nhãn)
/// - soft: vật cản mềm (nét nối)
/// - items: mảng (w, h, anchor, side, fixed) với
///     w, h   : kích thước ô chú giải (float pt)
///     anchor : chữ nhật của vật được neo vào
///     side   : `auto` = để luật chọn; hoặc một trong np-sides
///     fixed  : `none`, hoặc (dx, dy) tính từ vị trí mặc định của `side`
/// - gap: khoảng hở tối thiểu (float pt)
///
/// Trả về mảng chữ nhật, cùng thứ tự với `items`. Ô đặt trước trở thành vật cản của ô sau,
/// nên thứ tự khai báo có ý nghĩa: khai ô quan trọng trước.
#let np-solve(
  canvas,
  hard,
  soft,
  items,
  gap: 8.0,
  weights: np-defaults,
  grid: (11, 8),
  // Cho phép đặt ô ở bốn góc của vật neo, và phạt đường dẫn thẳng phương. Tắt thì quay
  // về đúng bốn phía như trước.
  diagonal: true,
) = {
  let placed = ()
  let out = ()
  for it in items {
    let (nw, nh, a) = (it.w, it.h, it.anchor)
    let side = it.at("side", default: auto)
    let fixed = it.at("fixed", default: none)

    if fixed != none {
      // Luật 0: người viết chỉ định thì máy không bàn.
      let (bx, by) = np-corner(a, nw, nh, if side == auto { "bottom" } else { side }, 0.0, gap)
      let r = np-rect(bx + fixed.at(0), by + fixed.at(1), nw, nh)
      placed.push(r)
      out.push(r)
      continue
    }

    let try-sides = if side != auto { (side,) } else if diagonal {
      np-sides + np-diagonals
    } else { np-sides }

    // Ứng viên hạng nhất: các ô sát ngay vật neo, theo từng phía.
    let cands = ()
    for (rank, s) in try-sides.enumerate() {
      let along = if s in ("bottom", "top") {
        (0.0, -nw * 0.55, nw * 0.55, -nw * 1.15, nw * 1.15)
      } else if s in ("right", "left") {
        (0.0, -nh * 0.75, nh * 0.75)
      } else {
        (0.0, nh * 0.5, nh * 1.1)
      }
      for off in along {
        for gm in (1.0, 2.0, 3.6) {
          let (bx, by) = np-corner(a, nw, nh, s, off, gap * gm)
          cands.push((r: np-rect(bx, by, nw, nh), bias: weights.side * rank))
        }
      }
    }

    // Ứng viên hạng hai: quét một lưới thô khắp khung. Khi quanh vật neo không còn chỗ,
    // ô chú giải vẫn tìm được một khoảng trắng thật sự ở nơi khác và nối về bằng đường
    // dẫn: thay vì trèo ra ngoài khung.
    if side == auto {
      let (nx, ny) = grid
      let sx = calc.max(0.0, canvas.w - nw)
      let sy = calc.max(0.0, canvas.h - nh)
      for i in range(nx) {
        for j in range(ny) {
          cands.push((
            r: np-rect(canvas.x + sx * i / (nx - 1), canvas.y + sy * j / (ny - 1), nw, nh),
            bias: weights.detach,
          ))
        }
      }
    }

    let area = calc.max(1.0, nw * nh)
    let acx = a.x + a.w / 2
    let acy = a.y + a.h / 2
    let best = none
    let best-score = 0.0
    for c in cands {
      let r = c.r
      let s = weights.out * (area - np-overlap(r, canvas)) / area // 1. Containment
      s += weights.shape * np-sum-overlap(r, hard) / area // 2. Avoidance (cứng)
      s += weights.edge * np-sum-overlap(r, soft) / area //    Avoidance (mềm)
      s += weights.peer * np-sum-overlap(r, placed) / area // 3. Separation
      let dcx = r.x + nw / 2 - acx
      let dcy = r.y + nh / 2 - acy
      s += weights.near * calc.sqrt(dcx * dcx + dcy * dcy) // 4. Cohesion
      s += c.bias //                                          5. Alignment

      // 6. Distinctness: đo trên chính đoạn thẳng sẽ được vẽ, không phải trên tâm hai
      // hình, vì đường dẫn nối *cạnh gần nhau nhất*. `ortho` bằng 1 khi đoạn nằm đúng
      // phương ngang hoặc dọc, bằng 0 khi đúng 45 độ.
      let sk = weights.at("skew", default: 0.0)
      if sk > 0 {
        let (lax, lay) = np-anchor(a, r.x + nw / 2, r.y + nh / 2)
        let (lbx, lby) = np-anchor(r, acx, acy)
        let (ex, ey) = (calc.abs(lbx - lax), calc.abs(lby - lay))
        if ex + ey > 0.5 {
          s += sk * calc.abs(ex - ey) / (ex + ey)
        }
      }
      if best == none or s < best-score {
        best = r
        best-score = s
      }
    }
    placed.push(best)
    out.push(best)
  }
  out
}
