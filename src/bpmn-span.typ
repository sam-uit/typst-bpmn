// /template/components/bpmn-span.typ
// Cắt sơ đồ BPMN theo CHIỀU DỌC — một đoạn quy trình, từ phần tử nào tới phần tử nào.
//
// `bpmn-figure` đã cắt được theo chiều đối tượng (`view: (pool:)`, `(lane:)`) — tức là
// theo *ai làm*. Component này cắt theo chiều còn lại: theo *đoạn nào của dòng chảy*.
//
//   #bpmn-span(M, from: "StartEvent_NhuCau", to: "Gateway_KetQuaDamPhan")
//
// Cách làm: **không** vẽ lại và **không** phóng to canvas. Chỉ tính ra tập phần tử nằm
// giữa hai mốc rồi giao cho `bpmn-slice` của typst-bpmn, thứ vốn đã giữ nguyên DI, giữ
// khung pool/lane, giữ black box của các bên còn trao đổi thông điệp, và có sẵn `pad`.
// Nhờ đi qua cùng một cửa, mọi thứ khác (`compact`, `fit`, `bpmn-notes`) chạy y như cũ.
//
// HỢP ĐỒNG, phát biểu rõ vì đã từng ngầm hiểu sai:
//
//   **Sequence flow quyết định BIÊN của đoạn. Mọi thứ gắn vào phần nằm trong biên thì
//   đi theo.**
//
// "Đi theo" gồm: message flow, đối tác ở đầu kia của message flow (dưới dạng hộp đen),
// data object, comment, association, và group nào bao trùm phần đã giữ.
//
// Vì sao phải nói ra: tập id ở đây tính bằng cách đi theo *sequence flow*, và đó là định
// nghĩa đúng của "đoạn từ A tới B". Nhưng nếu lát cắt chỉ gồm đúng tập đó thì nó đúng về
// đồ thị mà mất sạch bối cảnh: người đọc thấy một chuỗi task trôi lơ lửng, không còn đối
// tác nào, không còn ghi chú nào. Nó thôi là bản phóng to của cùng một hình. Phần "đi
// theo" được `bpmn-slice` lo, xem lượt hai trong đó.
//
// Vì sao "giữa hai mốc" là giao của hai tập, chứ không phải đường đi ngắn nhất: một quy
// trình thật có nhiều nhánh song hành: đường ngắn nhất chỉ lấy được một nhánh và bỏ mất
// phần rẽ. Lấy *tới được từ `from`* giao với *tới được `to`* thì mọi nhánh giữa hai mốc
// đều nằm trong, kể cả nhánh vòng.
//
// Author: Sam Dinh
// Version: 0.1.0
// License: MIT
//
// API công khai:
//   - bpmn-span-ids(model, from:, to:, ..) : Danh sách id giữa hai mốc (dùng lại được).
//   - bpmn-span-model(src, from:, to:, ..) : Model đã cắt, để đưa cho bpmn-notes.
//   - bpmn-span(src, from:, to:, ..)       : Figure của đoạn đó.

#import "bpmn.typ": bpmn-model, bpmn-slice, bpmn-figure, compact, default-theme
#import "bpmn-note.typ": bpmn-notes

#let bs-figure = figure

// Danh sách kề theo chiều xuôi.
#let bs-adj(model) = {
  let adj = (:)
  for f in model.at("flows", default: ()) {
    if f.at("kind", default: "sequence") != "sequence" { continue }
    adj.insert(f.source, adj.at(f.source, default: ()) + (f.target,))
  }
  adj
}

// Cạnh quay lui (vòng rework), tìm bằng DFS lặp — Typst không cho closure sửa biến bắt
// ngoài nên phải tự giữ ngăn xếp.
//
// Vì sao phải loại: một vòng rework nối cuối về đầu làm mọi node "tới được" mọi node.
// Không loại thì `from: <bắt đầu>, to: <một cổng ở giữa>` trả về gần như cả sơ đồ —
// đúng về mặt đồ thị, vô dụng về mặt đọc hiểu.
#let bs-back-edges(model) = {
  let adj = bs-adj(model)
  let color = (:)                 // 0 = chưa thăm, 1 = đang trên ngăn xếp, 2 = xong
  let back = ()
  // Duyệt từ sự kiện bắt đầu trước, để cạnh bị đánh dấu "quay lui" đúng là cạnh rework
  let starts = model.nodes
    .filter(n => n.at("kind", default: "") == "event" and n.at("event", default: "") == "start")
    .map(n => n.id)
  let roots = starts + model.nodes.map(n => n.id).filter(i => i not in starts)

  for root in roots {
    if color.at(root, default: 0) != 0 { continue }
    color.insert(root, 1)
    let stack = ((root, 0),)
    while stack.len() > 0 {
      let (u, i) = stack.last()
      let kids = adj.at(u, default: ())
      if i < kids.len() {
        stack.at(stack.len() - 1) = (u, i + 1)
        let v = kids.at(i)
        let c = color.at(v, default: 0)
        if c == 1 {
          back.push(u + "\u{0}" + v)
        } else if c == 0 {
          color.insert(v, 1)
          stack.push((v, 0))
        }
      } else {
        color.insert(u, 2)
        stack = stack.slice(0, stack.len() - 1)
      }
    }
  }
  back
}

// Tập node tới được từ `start`, đi theo chiều `forward` (hoặc ngược lại), bỏ cạnh quay lui.
#let bs-reach(model, start, forward: true, back: ()) = {
  let adj = (:)
  for f in model.at("flows", default: ()) {
    if f.at("kind", default: "sequence") != "sequence" { continue }
    if (f.source + "\u{0}" + f.target) in back { continue }
    let (a, b) = if forward { (f.source, f.target) } else { (f.target, f.source) }
    adj.insert(a, adj.at(a, default: ()) + (b,))
  }
  let seen = (start,)
  let queue = (start,)
  while queue.len() > 0 {
    let u = queue.first()
    queue = queue.slice(1)
    for v in adj.at(u, default: ()) {
      if v not in seen {
        seen.push(v)
        queue.push(v)
      }
    }
  }
  seen
}

/// Id của mọi phần tử nằm giữa `from` và `to`.
///
/// - from, to: id phần tử. Bỏ trống `from` = tính từ mọi sự kiện bắt đầu; bỏ trống `to`
///   = tính tới mọi sự kiện kết thúc.
/// - extra: thêm id vào tập kết quả (`include` là từ khoá của Typst nên không dùng được).
/// - exclude: bỏ id khỏi tập kết quả.
/// - lane: chỉ giữ phần tử của một lane.
/// - cycles: mặc định bỏ qua cạnh quay lui khi tính "giữa hai mốc".
#let bpmn-span-ids(
  model,
  from: none,
  to: none,
  extra: (),
  exclude: (),
  lane: none,
  // `true` = đi cả cạnh quay lui; hầu như luôn kéo về gần trọn sơ đồ, chỉ dùng khi
  // thật sự muốn thấy toàn bộ vùng ảnh hưởng của một vòng lặp
  cycles: false,
) = {
  let ends = i => model.nodes.filter(n => (
    n.at("kind", default: "") == "event" and n.at("event", default: "") == i
  )).map(n => n.id)

  let heads = if from == none { ends("start") } else { (from,) }
  let tails = if to == none { ends("end") } else { (to,) }

  let back = if cycles { () } else { bs-back-edges(model) }
  let fwd = ()
  for h in heads { fwd += bs-reach(model, h, forward: true, back: back) }
  let bwd = ()
  for t in tails { bwd += bs-reach(model, t, forward: false, back: back) }

  let ids = model.nodes.map(n => n.id).filter(id => id in fwd and id in bwd)
  let ids = ids + extra.filter(id => id not in ids)
  let ids = ids.filter(id => id not in exclude)
  if lane == none { return ids }

  let keep = model.nodes.filter(n => (
    n.at("lane", default: none) == lane or n.at("name", default: "") == lane
  )).map(n => n.id)
  // `lane` nhận cả id lẫn tên hiển thị; nếu tra theo node không ra thì tra bảng lane
  let keep = if keep.len() > 0 { keep } else {
    let lids = ()
    for p in model.pools {
      for l in p.at("lanes", default: ()) {
        if l.id == lane or l.at("name", default: "") == lane { lids.push(l.id) }
      }
    }
    model.nodes.filter(n => n.at("lane", default: none) in lids).map(n => n.id)
  }
  ids.filter(id => id in keep)
}

// Bỏ các lane rỗng ở hai biên của pool.
//
// `bpmn-slice` giữ nguyên khung pool/lane, đúng khi cắt theo lane. Nhưng cắt theo đoạn
// thì thường chỉ chạm vào một hai lane, và những dải rỗng còn lại ăn mất chiều cao —
// mà chiều cao mất đi là cỡ chữ mất đi khi co vừa bề rộng trang.
//
// Chỉ bỏ từ hai biên vào: một lane rỗng nằm GIỮA hai lane có nội dung thì phải giữ, bỏ đi
// sẽ tạo khoảng hụt giữa các dải.
#let bs-trim-lanes(model) = {
  let used = model.nodes.map(n => n.at("lane", default: none))
  let pools = model.pools.map(p => {
    let lanes = p.at("lanes", default: ())
    if lanes.len() == 0 { return p }
    let keep = lanes.map(l => l.id in used)
    if keep.all(k => not k) { return p }
    let lo = keep.position(k => k)
    let hi = lanes.len() - 1 - keep.rev().position(k => k)
    let kept = lanes.slice(lo, hi + 1)
    let y0 = calc.min(..kept.map(l => l.bounds.y))
    let y1 = calc.max(..kept.map(l => l.bounds.y + l.bounds.h))
    p + (lanes: kept, bounds: p.bounds + (y: y0, h: y1 - y0))
  })

  // Bỏ bớt dải thì khung phải co theo, nếu không sẽ thừa một mảng trắng ở dưới.
  // Chỉ đụng tới trục dọc; trục ngang giữ nguyên vì lát cắt không đổi bề ngang.
  let boxes = pools.map(p => p.bounds) + model.nodes.map(n => n.bounds)
  if boxes.len() == 0 { return model + (pools: pools) }
  let e = model.meta.extent
  // Lề dọc mà `bpmn-slice` đã chừa, giữ y nguyên như vậy
  let old = model.pools.map(p => p.bounds) + model.nodes.map(n => n.bounds)
  let pad-top = calc.min(..old.map(b => b.y)) - e.y
  let pad-bot = (e.y + e.h) - calc.max(..old.map(b => b.y + b.h))
  let y0 = calc.min(..boxes.map(b => b.y)) - pad-top
  let y1 = calc.max(..boxes.map(b => b.y + b.h)) + pad-bot
  model + (
    pools: pools,
    meta: model.meta + (extent: (x: e.x, y: y0, w: e.w, h: y1 - y0)),
  )
}

/// Model đã cắt theo đoạn — dùng khi cần đưa cho component khác thay vì dựng figure ngay.
///
/// `bpmn-notes` nhận `src` là một model, nên chú giải chạy trên đoạn cắt dọc như sau:
///
///   #bpmn-notes(bpmn-span-model(M, from: "A", to: "B"), view: none, notes: (..))
#let bpmn-span-model(
  src,
  from: none,
  to: none,
  extra: (),
  exclude: (),
  lane: none,
  cycles: false,
  trim-lanes: true,
  pad: 24,
) = {
  let model = bpmn-model(src)
  let ids = bpmn-span-ids(model, from: from, to: to, extra: extra,
                          exclude: exclude, lane: lane, cycles: cycles)
  if ids.len() == 0 {
    panic("bpmn-span: không có phần tử nào giữa `" + repr(from) + "` và `" + repr(to) + "`")
  }
  let view = (nodes: ids) + (if lane == none { (:) } else { (lane: lane) })
  let sliced = bpmn-slice(model, view, pad: pad)
  if trim-lanes { bs-trim-lanes(sliced) } else { sliced }
}

// MARK: Component
#let bpmn-span(
  src,
  from: none,
  to: none,
  extra: (),
  exclude: (),
  lane: none,
  cycles: false,
  // Khai `notes:` thì dựng bằng `bpmn-notes` thay vì `bpmn-figure` — cùng một cửa,
  // chú giải chỉ là một tuỳ chọn của lát cắt. `fit:` không dùng được cùng `notes:`.
  notes: (),
  // Bỏ các dải lane rỗng ở hai biên — dải rỗng ăn chiều cao, mà chiều cao là cỡ chữ
  trim-lanes: true,
  // Khoảng thở quanh đoạn, tính bằng đơn vị BPMN — cùng bản chất với lề của sơ đồ gốc
  pad: 24,
  // Nén cả hai trục: cắt theo đoạn hay để lại khoảng rỗng dọc bên trong lane, mà chiều
  // cao thừa là cỡ chữ mất đi khi co vừa bề rộng trang
  compact: (axis: "both"),
  fit: "width",
  theme: default-theme,
  caption: none,
  label: none,
  supplement: "Hình ảnh",
  ..args,
) = {
  let m = bpmn-span-model(src, from: from, to: to, extra: extra, exclude: exclude,
                          lane: lane, cycles: cycles, trim-lanes: trim-lanes, pad: pad)
  if notes.len() == 0 {
    bpmn-figure(m, compact: compact, fit: fit, theme: theme, caption: caption,
                label: label, supplement: supplement, ..args)
  } else {
    bpmn-notes(m, view: none, compact: compact, theme: theme, caption: caption,
               label: label, supplement: supplement, notes: notes, ..args)
  }
}
