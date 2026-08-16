# Dùng typst-bpmn trong một tài liệu

Ba quyết định, đã chốt:

| Câu hỏi | Quyết định |
| --- | --- |
| Thư viện nằm ở đâu | **Package Typst local** — `@local/typst-bpmn:<ver>` |
| Kiểu đường dẫn | **Tuyệt đối từ gốc tài liệu** cho cả import lẫn model |
| Đường đi của model | **Cả hai** `.bpmn` và `.yaml` đều commit vào tài liệu |

## Vì sao là package chứ không phải vendor

Trước đây sáu file `.typ` được chép thẳng vào `template/components/` của báo cáo. Rẻ,
nhưng nó làm hai thứ khác nhau nằm chung một `git log`: sửa nội dung báo cáo và sửa thư
viện vẽ trông giống hệt nhau khi đọc lịch sử. Với một báo cáo thì chịu được; với một
thư viện còn dùng tiếp sau môn học thì không.

Package local giải quyết đúng chỗ đó: một số version trong dòng `#import`, một kho cài
đặt, và hai lịch sử tách rời. Cái giá là tài liệu cần một bước cài — nhưng đó là một
lệnh, và nó tái lập được.

## Cài lần đầu

```bash
cd <typst-bpmn> && just install-lib
```

`install-lib` chép `typst.toml` và `src/` vào
`$XDG_DATA_HOME/typst/packages/local/typst-bpmn/<ver>`. Nó chỉ phụ thuộc `just lint-src`
— biên dịch mọi file trong `src/` — nên **không** cần `samples/`, `models/`, hay repo
`bpmn-generator` nằm cạnh. Cài được ngay sau khi clone.

Rồi thêm một dòng import vào file template trung tâm của tài liệu (`template/lib.typ`
hoặc tương đương), để mọi chương dùng được mà không phải khai lại:

```typ
#import "@local/typst-bpmn:0.6.1": *
```

**Ghim version trong dòng import.** Nâng version bên thư viện thì phải sửa dòng này —
cố ý, vì một tài liệu đã nộp phải dựng lại được y hệt.

## Sửa thư viện trong lúc viết tài liệu

```bash
cd <typst-bpmn> && just link-dev     # kho local trỏ symlink thẳng vào repo
```

Từ đó sửa `src/*.typ` là tài liệu thấy ngay, không phải cài lại. **Chạy lại
`just install-lib` trước khi nộp** — symlink chỉ tồn tại trên máy bạn.
`just unlink-lib` gỡ hẳn.

## Một ràng buộc của Typst phải nhớ

**Package chỉ đọc được file nằm trong chính nó.** Đường dẫn `/content/...` bên trong
package resolve theo gốc *của package*, không phải gốc tài liệu — nên một hàm `*-file()`
do package cung cấp sẽ báo không tìm thấy file khi tài liệu gọi.

Nên ranh giới là: **việc đọc file xảy ra ở tầng tài liệu.** Package nhận dữ liệu đã nạp
(`bpflow-data`, `bpmap-data`, `orgchart-data`, `bptable-data`, `whywhy`), còn tài liệu
giữ một hàm `load-data` và vài shim `*-file` gọi nó:

```typ
#let load-data(path, id: none) = { /* yaml() / json() / csv() ở tầng tài liệu */ }
#let bpflow-file(path, id: none, ..args) = bpflow-data(load-data(path, id: id), ..args)
```

Thêm component mới có nạp file thì đặt điểm vào `*-data` ở package và shim `*-file` ở
tài liệu, đừng làm ngược.

## Bố trí trong repo tài liệu

```
template/lib.typ                #import "@local/typst-bpmn:<ver>" + các shim *-file
content/processes/
  admission.bpmn                sửa file này trong Camunda Modeler
  admission.yaml                bpmn2yaml sinh ra; vẫn commit
justfile                        recipe `bpmn` gọi bpmn2yaml
```

`bpmn2yaml` thuộc repo [bpmn-generator](https://github.com/sam-uit/bpmn-generator), không
thuộc repo này — ranh giới giữa hai repo là **chiều đi của dữ liệu**:

```
brief.yaml ──► .bpmn         bpmn-generator   (soạn thảo)
.bpmn ──► .yaml ──► figure    typst-bpmn      (kết xuất)
```

Recipe cho justfile của tài liệu:

```just
bpmn:
    @for f in content/processes/*.bpmn; do \
        uv run bpmn2yaml "$f" -o "${f%.bpmn}.yaml" --strict; \
    done
```

## Dùng trong một chương

```typ
#let admission = yaml("/content/processes/admission.yaml")

#bpmn-figure(
  admission,
  view: (pool: "Thí Sinh"),
  compact: true,
  caption: [Quy trình tuyển sinh, góc nhìn của thí sinh],
  label: <fig-admission-student>,
)

Như @fig-admission-student cho thấy, ...
```

Đường dẫn tuyệt đối từ gốc nghĩa là file chương di chuyển được mà không phải sửa gì.
Thứ **không** tuỳ chọn: dùng tham số **`label:` chứ không phải `<lbl>` đặt sau** — xem
[README](../README.md#referencing-a-figure).

## Khớp với kiểu chữ của tài liệu

Component mặc định dùng DejaVu Sans. Truyền font của tài liệu một lần, ở `lib.typ`:

```typ
#let bpmn-theme = default-theme + (font: "Lora")
```

rồi truyền `theme: bpmn-theme` ở mỗi lần gọi, hoặc bọc `bpmn-figure` trong một helper
mỏng của tài liệu để nó tự truyền.

`font-size` tính bằng **đơn vị BPMN, không phải point** — nó co giãn theo sơ đồ. Cứ để
11 trừ khi chữ thân bài lớn bất thường.

## Vừa trang

Thứ tự nên với tới, và vì sao: xem
[README](../README.md#fitting-a-wide-diagram-onto-a4). Với A4 bề rộng chữ 174mm:

- Cả collaboration rơi vào khoảng 4pt. Quá nhỏ. Cắt đi.
- Một pool, đã nén: 4,5–5pt. Đọc được khi in, chật khi xem màn hình.
- Một lane, đã nén: 7pt+. Thoải mái.

`bpmn-info(M, view: .., compact: .., width: 174mm).label-size` cho con số **trước** khi
chốt bố cục — đáng kiểm một lần cho mỗi sơ đồ, hơn là nhìn PDF đoán.

### Hình xoay chiếm trọn một trang

`fit: "auto"` sẽ xoay một hình mà nhãn của nó rơi xuống dưới `min-font`, và hình xoay
được tính theo trọn chiều cao trang — nên nó không thể ở chung trang với đoạn văn giới
thiệu nó. Trong một chương thì thường đọc rất tệ: một trang chữ chỉ có một dòng, rồi
mới tới sơ đồ.

Với lát cắt chỉ hơi nhỏ, ghim phẳng và chấp nhận cỡ chữ:

```typ
#bpmn-figure(admission, view: (pool: "Thí Sinh"), compact: true,
  fit: "width",              // ở nguyên dòng, không xoay
  theme: bpmn-theme, caption: [...], label: <fig-student>)
```

Nguyên tắc: xoay *cả collaboration* (nó cần chỗ), giữ *lát cắt một pool hoặc một lane*
nằm phẳng. `debug: true` cho biết nó đã chọn chế độ nào.

## Sửa thư viện thì làm gì

1. Sửa ở đây, trong typst-bpmn.
2. `just check` — hai bộ phân tích khớp nhau, golden manifest không đổi hoặc đã duyệt lại.
3. `just conformance` nếu có ký hiệu đổi hình — và **nhìn** nó.
4. `just install-lib`, rồi nâng version trong dòng `#import` của tài liệu nếu có đổi.

`just check` cần `samples/`, `models/` và repo `bpmn-generator` nằm cạnh; `just
install-lib` thì không. Đó là lý do hai thứ tách nhau.
