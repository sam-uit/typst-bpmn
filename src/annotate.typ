// /template/components/annotate.typ
// Chú giải đặt chồng lên sơ đồ dựng bằng lưới (bpflow, bpmap), tự tìm chỗ.
//
// Vì sao cần một component riêng, không dùng lại `bpmn-notes`?
//
//   BPMN mang sẵn toạ độ tuyệt đối trong dữ liệu (BPMNDI), nên `bpmn-notes` đọc thẳng
//   từ model là biết mọi shape nằm đâu. `bpflow`/`bpmap` thì ngược lại: vị trí do `grid`
//   của Typst quyết định lúc dàn trang, dữ liệu không hề biết. Nên ở đây phải đi đường
//   khác: mỗi khối tự cắm hai mốc vô hình lúc vẽ, `annotate` truy vấn lại bằng
//   `query(<bp-anchor>)` sau khi trang đã dàn xong, rồi mới suy ra chữ nhật.
//
// Hai component khác nhau ở chỗ *lấy toạ độ từ đâu*; phần quyết định chỗ đặt thì dùng
// chung `noteplace.typ`: cùng một bộ luật, cùng hành vi.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - annotate(body, group: .., notes: (..), ..) : Bọc một sơ đồ, gắn chú giải lên trên.

#import "noteplace.typ": np-rect, np-union, np-anchor, np-solve, np-defaults
#import "bptext.typ": bp-text, bp-flatten

// Ghi lại ở cấp module: tham số cùng tên sẽ che mất bản toàn cục.
#let an-place = place
#let an-figure = figure

// Gom hai mốc góc của cùng một phần tử thành một chữ nhật, đổi sang toạ độ tương đối
// so với gốc của khung.
#let an-rects(marks, ox, oy) = {
  let by-id = (:)
  for m in marks {
    let v = m.value
    // Khoá phải gồm cả tên: bpmap dùng row*100+col làm index nên hai băng khác nhau
    // có thể trùng index, ghép nhầm góc của hai khối thành một chữ nhật vô nghĩa.
    let key = (
      str(v.at("index", default: 0))
        + "|"
        + repr(v.at("id", default: none))
        + "|"
        + v.at("name", default: "")
    )
    let p = m.location().position()
    let e = by-id.at(key, default: (info: v, tl: none, br: none))
    if v.corner == "tl" {
      e.tl = (p.x.pt() - ox, p.y.pt() - oy)
    } else {
      e.br = (p.x.pt() - ox, p.y.pt() - oy)
    }
    by-id.insert(key, e)
  }
  by-id
    .values()
    .filter(e => e.tl != none and e.br != none)
    .map(e => (
      info: e.info,
      rect: np-rect(
        e.tl.at(0),
        e.tl.at(1),
        calc.max(1.0, e.br.at(0) - e.tl.at(0)),
        calc.max(1.0, e.br.at(1) - e.tl.at(1)),
      ),
    ))
}

// Tìm phần tử theo id, theo tên hiển thị, hoặc theo số thứ tự.
#let an-find(items, key) = {
  let hit = items.find(it => it.info.at("id", default: none) == key)
  if hit != none { return hit }
  if type(key) == int {
    return items.find(it => it.info.at("index", default: none) == key)
  }
  // Tên trong dữ liệu là "Tài chính -- Kế toán"; tên đã dựng là "Tài chính – Kế toán".
  // So chuỗi thô sẽ trượt, nên dựng cả hai rồi mới so.
  let k = lower(bp-flatten(bp-text(str(key)))).trim()
  items.find(it => lower(bp-flatten(bp-text(it.info.at("name", default: "")))).trim() == k)
}

// MARK: Component
#let annotate(
  body,
  // Tên nhóm mốc neo: phải trùng tham số `anchors:` đã truyền cho bpflow/bpmap.
  // Mỗi lần dùng một tên khác nhau, nếu không các sơ đồ sẽ nhặt nhầm mốc của nhau.
  group: none,
  // Mỗi chú giải: (node: "id|tên|số thứ tự", body: [...], side: auto|"top".., dx:, dy:,
  //                color:, width:)
  notes: (),
  caption: none,
  label: none,
  supplement: auto,
  note-width: 34mm,
  note-size: 7.5pt,
  note-fill: rgb("#FFFDF2"),
  note-stroke: rgb("#B26A00"),
  note-inset: 4pt,
  gap: 3mm,
  // Nới khung ra ngoài vùng các khối, khi muốn cho phép chú giải tràn vào lề của sơ đồ
  canvas-pad: 0mm,
  weights: np-defaults,
  breakable: false,
  debug: false,
) = {
  if group == none { panic("annotate: cần `group:` trùng với `anchors:` của sơ đồ") }

  let wrapped = block(
    width: 100%,
    breakable: breakable,
    {
      // Mốc gốc của khung: mọi toạ độ truy vấn được sẽ trừ đi điểm này
      an-place(top + left, [#metadata((group: group, id: "__origin__", corner: "tl", index: -1)) <bp-anchor>])
      body

      context {
        let marks = query(<bp-anchor>).filter(m => m.value.at("group", default: none) == group)
        let origin = marks.find(m => m.value.at("id", default: none) == "__origin__")
        if origin == none { return }
        let op = origin.location().position()
        let (ox, oy) = (op.x.pt(), op.y.pt())

        let items = an-rects(
          marks.filter(m => m.value.at("id", default: none) != "__origin__"),
          ox,
          oy,
        )
        if items.len() == 0 { return }

        let obstacles = items.map(it => it.rect)
        let cp = canvas-pad.pt()
        let u = np-union(obstacles)
        let canvas = np-rect(u.x - cp, u.y - cp, u.w + 2 * cp, u.h + 2 * cp)

        // Dựng thẻ trước để biết kích thước, rồi mới giao cho bộ đặt chỗ
        let cards = ()
        let specs = ()
        for nt in notes {
          let target = an-find(items, nt.node)
          if target == none { continue }
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
          cards.push((card: card, color: col, anchor: target.rect))
          specs.push((
            w: cs.width.pt(),
            h: cs.height.pt(),
            anchor: target.rect,
            side: nt.at("side", default: auto),
            fixed: if "dx" in nt or "dy" in nt {
              (nt.at("dx", default: 0mm).pt(), nt.at("dy", default: 0mm).pt())
            } else { none },
          ))
        }
        if specs.len() == 0 { return }

        let rects = np-solve(canvas, obstacles, (), specs, gap: gap.pt(), weights: weights)

        if debug {
          for o in obstacles {
            an-place(top + left, dx: o.x * 1pt, dy: o.y * 1pt,
              rect(width: o.w * 1pt, height: o.h * 1pt, stroke: 0.3pt + rgb("#00A0FF66")))
          }
        }

        for (i, c) in cards.enumerate() {
          let r = rects.at(i)
          let a = c.anchor
          let (ax, ay) = np-anchor(a, r.x + r.w / 2, r.y + r.h / 2)
          let (bx, by) = np-anchor(r, a.x + a.w / 2, a.y + a.h / 2)
          an-place(top + left, dx: ax * 1pt, dy: ay * 1pt, line(
            start: (0pt, 0pt),
            end: ((bx - ax) * 1pt, (by - ay) * 1pt),
            stroke: (paint: c.color, thickness: 0.5pt, dash: "dotted"),
          ))
          an-place(top + left, dx: r.x * 1pt, dy: r.y * 1pt, c.card)
        }
      }
    },
  )

  if caption == none {
    wrapped
  } else {
    let fig = {
      show an-figure: set block(breakable: breakable)
      an-figure(
        wrapped,
        caption: caption,
        kind: image,
        ..(if supplement == auto { (:) } else { (supplement: supplement) }),
      )
    }
    if label == none { fig } else { [#fig #label] }
  }
}
