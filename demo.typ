#import "/src/bpmn.typ": *

#set page(paper: "a4", margin: 18mm, numbering: "1")
#set text(font: "Lora", size: 10pt, lang: "vi")
#set par(justify: true, leading: 0.62em)
#show heading: set block(above: 1.3em, below: 0.7em)
#show raw: set text(font: "DejaVu Sans Mono", size: 0.85em)

#let M = yaml("/models/b04-btvn01.yaml")
#let T = default-theme + (font: "Lora")

#align(center)[
  #text(size: 17pt, weight: "bold")[BPMN 2.0 trong Typst] \
  #v(2pt)
  #text(size: 9pt)[`b04-btvn01.bpmn` · Camunda Modeler 5.49 · #M.nodes.len() nodes, #M.flows.len() flows]
]
#v(6pt)

Toạ độ lấy trực tiếp từ BPMNDI của modeler, nên hình vẽ trung thành với bản gốc.
Ba công cụ để đưa một sơ đồ rộng vào khổ A4, theo thứ tự nên dùng: cắt lát theo
`view:`, nén khoảng trắng bằng `compact:`, và cuối cùng mới đến xoay trang.

= 1. Nén khoảng trắng

`compact:` không thu nhỏ hình — nó chỉ bỏ bớt những dải trống. Kích thước shape và
nhãn giữ nguyên, nên khi scale vừa bề ngang trang, chữ *to ra*.

#let stat(vw, cp) = {
  let i = bpmn-info(M, view: vw, compact: cp, theme: T, width: 174mm)
  [#calc.round(i.extent.w) × #calc.round(i.extent.h) u, nhãn #calc.round(i.label-size / 1pt, digits: 2)pt]
}

#table(
  columns: (auto, 1fr, auto),
  stroke: none,
  inset: (x: 0pt, y: 3pt),
  align: (left, left, right),
  table.hline(),
  [*Thiết lập*], [*Ý nghĩa*], [*Kết quả \@174mm*],
  table.hline(stroke: 0.4pt),
  [không nén], [DI nguyên bản của Camunda], stat(none, none),
  [`compact: true`], [nén trục x], stat(none, true),
  [`(axis: "both")`], [nén cả hai trục], stat(none, (axis: "both")),
  [`(axis: "both", min-gap: 20)`], [nén mạnh hơn], stat(none, (axis: "both", min-gap: 20)),
  table.hline(),
)

#bpmn-figure(M, compact: (axis: "both"), theme: T, debug: true,
  caption: [Toàn cảnh sau khi nén cả hai trục. Cạnh vuông vẫn vuông, không có
    phần tử nào chồng lên nhau — phép biến đổi là ánh xạ đơn điệu từng đoạn.])

#pagebreak()

= 2. Cắt lát theo pool, giữ đối tác làm black box

Khi chỉ hiển thị một pool, các participant còn lại *không* bị xoá. Chúng thu lại
thành một dải rỗng mang tên mình, và message flow được nối lại vào cạnh dải đó.
Đây đúng là quy ước black-box của BPMN: "đối tác này có tồn tại, nhưng ruột của
nó không phải việc của bạn". Tắt bằng `view: (pool: ..., blackbox: false)`.

#bpmn-figure(M, view: (pool: "Thí Sinh"), compact: true, theme: T,
  caption: [Góc nhìn của thí sinh. Cả 5 message flow sang *Nhà Trường* đều còn,
    kể cả chiều gửi và chiều nhận.])

#bpmn-figure(M, view: (pool: "Thí Sinh", blackbox: false), compact: true, theme: T,
  caption: [Cùng lát cắt, `blackbox: false` — sạch hơn nhưng mất hẳn phần
    tương tác với đối tác.])

#bpmn-figure(M, view: (pool: "Nhà Trường"), compact: true, theme: T,
  caption: [Góc nhìn của nhà trường, hai lane giữ nguyên.])

#pagebreak()

= 3. Cắt lát theo lane

#bpmn-figure(M, view: (lane: "Hội Đồng Học Thuật"), compact: true, theme: T,
  debug: true, caption: [Chỉ lane Hội Đồng Học Thuật — nhãn đã đủ lớn để đọc thoải mái.])

#bpmn-figure(M, view: (lane: "Phòng Tuyển Sinh"), compact: true, theme: T,
  caption: [Lane Phòng Tuyển Sinh.])

= 4. Chủ đề in đen trắng

#bpmn-figure(M, view: (lane: "Phòng Tuyển Sinh"), compact: true,
  theme: grayscale-theme + (font: "Lora"),
  caption: [`grayscale-theme` bỏ màu của bpmn.io để in đen trắng.])

#pagebreak()

= 5. Đọc thẳng từ `.bpmn`, không cần bước build

#bpmn-figure(xml("/samples/b04-btvn01.bpmn"), view: (pool: "Thí Sinh"), compact: true, theme: T,
  caption: [Cùng một lát cắt nhưng nạp trực tiếp bằng `xml()`. Hai bộ parser cho
    kết quả giống hệt nhau.])

= 6. YAML viết tay, không có toạ độ

Bỏ hết `bounds`/`waypoints` và cho mỗi node một `row`/`col`; phần còn lại do
`bpmn-grid.typ` lo — kể cả định tuyến vuông góc.

#bpmn-figure(yaml("/examples/leave-request.yaml"), theme: T, fit: "width",
  caption: [Layout lưới, không có một toạ độ nào trong file YAML.])
