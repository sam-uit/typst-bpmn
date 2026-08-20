// Smoke test cho họ component vẽ quy trình, chạy: `just smoke`.
//
// ## Nó kiểm cái gì, và cố tình không kiểm cái gì
//
// `bpstep`, `bpmap`, `orgchart`, `bptable`, `bpportfolio` và `whywhy` cộng lại là
// 2721 dòng, 39% của `src/`, và cho tới bản này chúng **không có một dòng kiểm nào**.
// Lý do không phải là lười: chúng được migrate từ repo báo cáo sang, nơi thứ được
// kiểm là bản PDF cuối cùng, nên mỗi component chỉ từng nhìn thấy đúng một file dữ
// liệu thật.
//
// Đó cũng là chỗ chúng dễ vỡ nhất, nên bài kiểm này đi theo **hình dạng dữ liệu**
// chứ không theo nội dung: rỗng, một phần tử, nhiều phần tử, nhãn dài, thiếu khoá
// tuỳ chọn, và chuỗi có `--` với `#` để đường `bp-text` cũng được đi qua. Dữ liệu ở
// `examples/family-fixtures.yaml`.
//
// Nó **không** phải golden manifest. Nó không bắt được đổi màu, đổi khoảng cách hay
// lệch căn chỉnh; muốn thế thì cần một `*-info()` cho từng component, và đó là việc
// riêng đã ghi trong `docs/roadmap.md`. Cái nó bắt được, và bắt ngay lập tức, là
// component *gãy hẳn*: đổi tên tham số, đổi khoá dữ liệu mong đợi, hoặc `panic` trên
// một hình dạng dữ liệu mà tác giả không nghĩ tới. Với sáu file chưa có gì canh thì
// đó là bước đầu tiên đáng giá nhất.
//
// Cách nó khẳng định: dựng từng ca rồi `measure` kết quả. Không so số đo với một giá
// trị mong đợi, vì số đo phụ thuộc font và bài kiểm phải chạy được trên máy khác.
// Chỉ đòi hai điều: dựng xong không nổ, và ra một khối có kích thước hữu hạn khác 0
// (trừ những ca cố ý rỗng, được đánh dấu `empty: true`).

#import "/src/lib.typ": *

#set page(width: 400mm, height: auto, margin: 10mm)
#set text(size: 9pt)

#let FX = yaml("/examples/family-fixtures.yaml")

// (tên ca, nội dung, có được phép rỗng không)
#let cases = (
  ("bpstep/empty", bpflow-data(FX.bpstep.empty), true),
  ("bpstep/one", bpflow-data(FX.bpstep.one), false),
  ("bpstep/many", bpflow-data(FX.bpstep.many), false),
  ("bpstep/csv-rows", bpflow-data(FX.bpstep.at("csv-rows")), false),
  ("bpstep/dashes", bpflow-data(FX.bpstep.dashes), false),

  ("bpmap/minimal", bpmap-data(FX.bpmap.minimal), false),
  ("bpmap/full", bpmap-data(FX.bpmap.full), false),
  ("bpmap/only-core", bpmap-data(FX.bpmap.at("only-core")), false),

  ("orgchart/leaf", orgchart-data(FX.orgchart.leaf), false),
  ("orgchart/three-levels", orgchart-data(FX.orgchart.at("three-levels")), false),

  ("bptable/empty", bptable-data(FX.bptable.empty), true),
  ("bptable/two", bptable-data(FX.bptable.two), false),

  ("bpportfolio/one", bpportfolio-data(FX.bpportfolio.one), false),
  ("bpportfolio/spread", bpportfolio-data(FX.bpportfolio.spread), false),
  ("bpportfolio/defaults", bpportfolio-data(FX.bpportfolio.defaults), false),

  ("whywhy/one-level", whywhy(FX.whywhy.at("one-level")), false),
  ("whywhy/chain", whywhy(FX.whywhy.chain), false),
)

// `whywhy-notes` trả về dữ liệu chứ không phải content, nên nó được khẳng định riêng:
// đây là đường mà một sơ đồ BPMN đọc để lấy các ô chú giải, và nó im lặng trả về mảng
// rỗng khi khoá `node` bị đổi tên. Ba tầng, hai tầng có `node`, nên phải ra hai ô.
#let notes = whywhy-notes(FX.whywhy.chain)

#context {
  let bad = ()
  for (name, body, may-be-empty) in cases {
    let m = measure(block(width: 260mm, body))
    let empty = m.width == 0pt or m.height == 0pt
    if empty and not may-be-empty {
      bad.push(name + ": dựng ra một khối rỗng")
    } else if not empty and may-be-empty {
      bad.push(name + ": dữ liệu rỗng mà vẫn vẽ ra thứ gì đó")
    }
  }
  if notes.len() != 2 {
    bad.push("whywhy-notes: cần 2 ô (hai tầng có `node`), nhận " + str(notes.len()))
  }
  if bad.len() > 0 {
    panic("smoke: " + str(bad.len()) + " ca hỏng\n  " + bad.join("\n  "))
  }
  [#metadata((cases: cases.len(), notes: notes.len())) <smoke>]
  [*smoke: #cases.len() ca dựng được, `whywhy-notes` trả #notes.len() ô.*]
}

// Phần dưới đây được vẽ ra thật, để `just smoke` mở ra nhìn được khi cần. Bài kiểm
// đã xong ở khối trên; đây chỉ là cái để mắt xác nhận.
#for (name, body, _) in cases {
  block(above: 8mm, below: 2mm, text(fill: rgb("#888"), size: 7pt, raw(name)))
  block(width: 100%, body)
}
