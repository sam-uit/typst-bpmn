# Changelogs

Mỗi version được tag ghi một mục ở đây, mới nhất lên trước. Mục viết theo lối giải thích: cái gì đổi, vì sao cần, và cái gì đã cân nhắc rồi bỏ. Nó không phải danh sách commit; `git log` đã làm việc đó rồi.

Đánh số: **minor** cho một component hoặc một khả năng mới, **patch** cho sửa lỗi và mở rộng một component đã có. Version phải khớp ba chỗ: `typst.toml`, dòng `#import` trong tài liệu của thư viện, và `template/pkg.typ` bên phía báo cáo.

## v0.17.1

**CONTRIBUTING.md, and English as a rule**

The conventions this repository follows were, until now, held in one person's head and in a memory file outside the repository. A clone did not carry them, so the first thing a second reader would do is guess, and guess differently in each file. [`CONTRIBUTING.md`](../CONTRIBUTING.md) writes them down: language, naming, punctuation, Markdown source, changelog, dependencies, and what to run before committing.

Each rule carries the reason it is a rule. That is deliberate. A convention with no stated reason reads as taste, and taste is negotiable at three in the morning when something needs to ship; a convention whose cost is written next to it is not.

**English only**, from 2026-08-20, for documentation, comments, docstrings, panic messages, `just` recipe descriptions and commit messages. This library started inside a Vietnamese-language report and most of its prose is still Vietnamese, so the rule as written applies to everything **newly** written, and the existing backlog is scheduled for one planned pass. Translating a file here and a file there while doing other work was considered and rejected: a half-translated file costs the reader more than a consistently Vietnamese one, and a translation pass mixed into a behaviour change makes the behaviour change unreviewable.

**Dependencies must be stated** is the rule with real teeth. `bpmn2yaml` comes from another repository, the version number has to agree in three places across two repositories, and neither fact is visible from inside a single file. `just version-check` already guards the part a machine can guard; the document covers the rest.

Version bumped to 0.17.1 in `typst.toml`, `README.md` and `docs/integration.md` together, which is exactly what `just version-check` exists to enforce. That recipe now scans `CONTRIBUTING.md` as well: it is a document that teaches the import line, so it is a document that can state the wrong version.

## v0.17.0

**LICENSE, CI, và lớp kiểm đầu tiên cho họ component**

Ba việc còn lại từ bản đánh giá độ vững, cộng một việc anh đã làm ở phía mình.

**`tests/smoke.typ`.** `bpstep`, `bpmap`, `orgchart`, `bptable`, `bpportfolio` và `whywhy` cộng lại là 2721 dòng, 39% của `src/`, và cho tới bản này chúng không có một dòng kiểm nào. Không phải vì lười: chúng được migrate từ repo báo cáo sang, nơi thứ được kiểm là bản PDF cuối cùng, nên mỗi component chỉ từng nhìn thấy đúng một file dữ liệu thật.

Bài kiểm vì vậy đi theo **hình dạng dữ liệu** chứ không theo nội dung: rỗng, một phần tử, nhiều phần tử, nhãn dài, thiếu khoá tuỳ chọn, và chuỗi có `--` với `#` để đường `bp-text` cũng được đi qua. 17 ca, dữ liệu ở `examples/family-fixtures.yaml`.

Nó khẳng định đúng hai điều: dựng xong không nổ, và ra một khối có kích thước hữu hạn khác 0, trừ những ca cố ý rỗng. Không so số đo với giá trị mong đợi, vì số đo phụ thuộc font và bài kiểm phải chạy được trên máy khác. Nói thẳng phạm vi: **đây không phải golden manifest**, nó không thấy được đổi màu, đổi khoảng cách hay lệch căn chỉnh. Cái nó thấy ngay là component gãy hẳn, tức là đúng thứ một lần refactor gây ra. Với sáu file chưa có gì canh thì đó là bước đầu tiên đáng giá nhất, và bước tiếp theo đã ghi trong [`roadmap.md`](roadmap.md).

Không cần `models/`, nên nó chạy được ngay trên một bản clone sạch. Đã vào `just check`.

**CI.** `.github/workflows/check.yml` chạy `just check` và `just lint` trên mỗi push và mỗi pull request. Trước đây cổng kiểm chỉ chạy khi có người nhớ chạy. Nó chạy được ở đây là nhờ `samples/b04-btvn01.bpmn` đã nằm trong repo: dựng thử một bản clone chỉ gồm file `git ls-files` liệt kê thì cả bốn lớp cộng `demo.typ` đều dựng được.

`bpmn2yaml` được **ghim theo tag** chứ không lấy nhánh mặc định, cùng lý do với `template/pkg.typ` bên báo cáo: đổi bộ chuyển đổi thì golden manifest có thể trôi, và chuyện đó phải là một quyết định.

**LICENSE.** `typst.toml` khai `license = "MIT"` từ v0.6.0 mà repo không có file giấy phép nào. Không sao khi còn dùng nội bộ, nhưng đó là điều kiện bắt buộc để đưa lên Typst Universe.

**`exclude` của typst.toml** thêm `.github`, bỏ `plan.md` đã xoá.

Và hai cái tên ma cuối cùng: `bpmn-lane` với `bpmn-part` còn nằm trong docstring của `whywhy.typ`.

## v0.16.5

**`just version-check`, và số version trong tài liệu đã đứng yên chín bản**

README và `docs/integration.md` vẫn viết `#import "@local/typst-bpmn:0.7.5"` trong khi package đã ở 0.16.4. Đó là dòng **đầu tiên** người dùng chép, và nó sai chín lần phát hành minor liền.

Quy ước của repo là "version phải khớp ba chỗ: `typst.toml`, dòng `#import` trong tài liệu, và `template/pkg.typ` bên báo cáo". Một quy ước không có gì kiểm thì nó là một lời hứa, không phải một luật. Nay có `just version-check`, và nó là điều kiện của cả `just check` lẫn `just install-lib`, tức là không cài được một bản mà tài liệu của nó nói sai số.

## v0.16.4

**Quy ước viết áp cho code base, và hai lỗi lộ ra trong lúc quét**

249 chỗ dùng em-dash trong `src/`, `tests/` và `justfile`. Cùng ba luật đã dùng cho `docs/` ở v0.16.3, thay theo nghĩa chứ không máy móc thành dấu phẩy.

19 chỗ **không** phải chú thích, và đó là phần đáng chú ý. `bpmn-sheet` in nhãn trang `"(1/3 — Phòng Marketing)"`, tức là chữ đi thẳng vào PDF của báo cáo, nên luật bị vi phạm ở chỗ nhìn thấy được nhất. Còn lại là ba thông điệp `panic`, ba dòng `echo` của justfile, và mười hai chuỗi văn bản của `tests/conformance.typ` vốn được in lên chính tờ đối chiếu.

Hai lỗi lộ ra trong lúc quét:

**`models/` có hai file mồ côi.** `just convert` chỉ quét `samples/`, mà `tests/agreement.typ` và `tests/conformance.typ` lại cần `models/vertical-pools.yaml` và `models/leading-comment.yaml`, vốn sinh ra từ `tests/fixtures/`. Không lệnh nào dựng lại được hai file đó, nên `just clean-all` là mất vĩnh viễn và `just check` hỏng cho tới khi chép tay lại. Vòng lặp nay quét cả hai nguồn; đã kiểm cả ba fixture đi qua `bpmn2yaml --strict` sạch.

**`bpmn-lane` và `bpmn-part` không tồn tại.** Chú thích đầu `bpmn-sheet.typ` giới thiệu chúng như anh em của `bpmn-span`. Cách cắt theo lane thật sự là `bpmn-figure(view: (lane: ..))`. Cùng hai cái tên này còn nằm trong một gợi ý mà `bpmn-brief` in ra cho người dùng bên repo bpmn-generator, đã sửa ở đó tại v0.5.1.

Và `typst.toml` còn một em-dash trong `description`, tức là nó nằm trong siêu dữ liệu của chính package.

## v0.16.3

**Tài liệu: chuẩn hoá cách viết, dựng lại changelog, và roadmap nói đúng trạng thái**

Bản chỉ có tài liệu, nhưng vẫn tăng version, vì `template/pkg.typ` bên báo cáo ghim theo số này.

**Quy ước viết.** Hai luật áp cho toàn bộ `docs/` và README. *Một đoạn là một dòng*: bỏ mọi lần xuống dòng thủ công giữa đoạn, vì xuống dòng giữa đoạn làm `git diff` báo cả đoạn đã đổi khi chỉ đổi một chữ, và làm mọi thao tác tìm/thay bằng script trượt qua chuỗi bị cắt ngang dòng. *Không em-dash*: 84 chỗ, thay theo nghĩa chứ không máy móc, nối hai mệnh đề độc lập thì thành chấm phẩy, mở một lời giải thích thì thành hai chấm, kẹp một cụm chen ngang thì thành dấu ngoặc đơn.

**Changelog.** File này vốn rỗng trong khi repo đã có 37 tag. Những dải bản vá liên tiếp cùng một chủ đề được gộp làm một mục, vì đọc từng bản vá một thì mất mạch.

**Roadmap.** Nó vẫn ghi Phase 1 là "current focus" trong khi tiêu chí thoát đã đạt từ v0.6.0, và không nhắc gì tới chín component vốn giờ chiếm phần lớn package. Nay có bảng trạng thái ở đầu, Phase 1 đóng lại kèm bốn việc còn mở, và một mục mới cho họ component. Điều đáng nói nhất từ mục đó: **chúng không có lớp test nào của riêng chúng**, `just check` chỉ phủ đường BPMN, nên sửa `bpstep` hay `bpportfolio` là kiểm bằng cách nhìn PDF và nhớ.

## v0.16.2

**Loop marker theo đúng chiều BPMN**

BPMN vẽ ký hiệu vòng lặp **ngược chiều kim đồng hồ với khe hở nằm dưới đáy**: đuôi bắt đầu quanh 5h30, cung đi đường dài, mũi dừng quanh 7h. Bản cũ chạy thuận chiều kim đồng hồ với khe hở ở đỉnh, tức là đúng hình đó lật qua trục ngang. Đúng hình dạng, sai phát biểu, và đọc ra thành ký hiệu "reload" chứ không phải vòng lặp.

Hai việc tách riêng vì chúng độc lập. **Chiều tay**: đo `y` xuống dưới thay vì lên trên; phép lật đổi chiều tay nên ↻ thành ↺ mà không phải đụng tới `sweep`. **Chỗ khe hở**: thêm `phase` vào trong `P` để lăn cả hình quanh vòng tròn, `phase = 0` cho đuôi ở 4h30 và mũi ở 6h, `-30deg` đẩy cả hai thêm một giờ về đúng đặc tả. Mọi điểm phải thấy cùng một `phase`, kể cả bán kính mà đáy mũi tên mở ra theo; sót chỗ đó thì mũi tên bị xiên.

Kèm theo, canh giữa giờ đo từ vệt mực thật thay vì giải tay. Công thức đóng cũ `cy = (size - t/2 + hw) / 2` chỉ đúng khi khe hở nằm trên một trục, vì nó giả định đầu mũi tên là điểm cực một phía và nét trần là phía kia. Có `phase` thì cả hai giả định đều sai.

## v0.16.1

**Điểm rơi message flow theo hình học, và khoảng trắng giữa hai hộp đen**

Hai tật của lát cắt hộp đen, cùng nằm trong khối tái định tuyến của `bpmn-slice`.

**Message flow lệch khỏi tâm không dự đoán được.** Độ lệch tính bằng chỉ số của flow trong mảng, `(calc.rem(fi, 3) - 1) * 7`, không dính gì tới hình học. Hai phần ba số flow bị đẩy khỏi tâm dù không đụng ai, và lệch chỗ nào thì đổi mỗi khi tập flow đổi. Bản sửa hộp đen ở v0.16.0 làm số flow tăng lên nên chuyện này mới lộ rõ. Nay các điểm rơi được nhóm theo `(toạ độ, phía)` và chỉ nhóm nhiều hơn một thành viên mới bị tách, đối xứng quanh toạ độ chung, bước `min(14, extent / (n + 1))` để cả chùm nằm trên cạnh node. Đo trên sáu mô hình L3 của báo cáo: cả 27 message flow đều về đúng tâm, không mô hình nào có va chạm thật.

**Hai dải hộp đen cạnh nhau dính thành một khối.** Các dải được xếp sát nhau đúng `blackbox-height`, nên hai đối tác cùng một phía in ra thành một khối xám chia đôi bởi một đường kẻ, đọc ra thành một pool hai lane. Nay xếp theo bước `blackbox-height + blackbox-gap`, và thứ tự các dải theo vị trí gốc của participant chứ không theo thứ tự gặp trong mảng message flow.

Bộ test cũ không canh được gì cho hai chỗ này: mọi lát cắt trong đó chỉ sinh một dải, và không mô hình nào có hai flow trùng chỗ, nên manifest không đổi một dòng sau khi sửa. Thêm `tests/fixtures/two-blackboxes.bpmn` để lần sau nó canh thật.

## v0.16.0

**`bpmn-span` mang theo bối cảnh, và hợp đồng được viết ra thành lời**

`bpmn-span` cắt theo sequence flow, nhưng nó chỉ giữ đúng những node tính được, nên message flow, đối tác hộp đen, data object, annotation và group bao quanh đều rơi mất. Lát cắt trông sạch mà đọc sai, vì nó bỏ đi đúng phần nói rằng bước này trao đổi với ai.

Hai chỗ sửa. **Message flow neo vào participant**: một participant không có `processRef` thì message flow neo thẳng vào chính nó chứ không vào node nào bên trong, mà `pool-of` chỉ ánh xạ id node, nên tra không thấy và cả đối tác lẫn flow biến mất. Đây là mảnh còn sót của việc nhận diện hộp đen ở v0.13.0. **Lượt nhặt thứ hai**: sau khi có tập node theo sequence flow, nhặt thêm data object và annotation nối tới bằng association, và group nào bao trùm tâm của một node đã giữ.

Hợp đồng nay viết thành lời trong docstring: sequence flow quyết định *biên* của đoạn, mọi thứ gắn vào những phần tử trong đoạn thì đi theo. Có bàn đổi tên thành `bpmn-part` và đã bỏ: cái sai không nằm ở tên mà ở hợp đồng chưa được phát biểu, đổi tên chỉ làm cái tên mờ đi đúng bằng mức độ mờ của hợp đồng.

Đo được: lát cắt theo pool trên sáu mô hình L3 phục hồi **10 hộp đen và 27 message flow**, số node không đổi.

## v0.15.0

**`bpmn-sheet` nhận `view:` và `turn: none`**

`view:` cắt phần tử *trước* khi cắt trang, nên một tờ gấp có thể chỉ trải một pool thay vì cả collaboration. `turn: none` bỏ hẳn phép xoay, cho khổ giấy vốn đã nằm ngang: slide 16:9 thì cả `"cw"` lẫn `"ccw"` đều không giúp gì, mà đó lại là chỗ cần trải sơ đồ nhất.

## v0.14.1

**`docs/curved-arrows.md`**

Ghi lại cách dựng mũi tên cong trong Typst thuần: lấy mẫu cung thành polyline với Δ ≤ 8°, suy bước góc của đầu mũi tên từ `Δ = 2·asin(L / 2r)`, dừng nét đúng ở góc đáy, đặt cạnh đáy dọc theo pháp tuyến, bo góc bằng nét cùng màu với `join: "round"`, và canh giữa theo vệt mực chứ không theo hình học.

Kèm theo, `turnicon` bỏ hằng số `trim: 18deg` gõ tay. Nó đúng bằng 17,81° suy ra được, nhưng đúng cho *một* cặp `(r, head-len)`; đổi bán kính là nó sai âm thầm.

## v0.14.0

**`sheet-turn-icon`**

Biểu tượng "xoay tờ giấy" cho các trang gấp: một hình chữ nhật đại diện trang A4 và hai cung bán nguyệt chỉ hướng xoay. Viền giấy mảnh hơn mũi tên để mũi tên là thứ mắt bắt trước, và chữ "A4" chỉ in khi còn đủ chỗ.

## v0.13.0

**Hộp đen được nhận diện ở tầng parser, và tên lặp lại trên mỗi trang gấp**

Ba việc, cùng một gốc: một participant không mở ra thì nó là hộp đen, và hộp đen thì không chứa node nào.

**Parser chưa bao giờ đánh dấu hộp đen.** Cả sáu mô hình L3 vẽ đối tác rỗng thành pool có dải tiêu đề. Sai về phát biểu, vì dải tiêu đề hứa hẹn lane và nội dung mà đối tác không có, và không đọc được, vì hộp đen cao khoảng 60 đơn vị mà dải chiếm mất một nửa. Nay parser đọc hai dấu hiệu của đặc tả: không có `processRef`, hoặc `isExpanded="false"` trên shape DI.

**`bpmn-sheet` xoá im lặng các băng hộp đen.** Bộ lập kế hoạch hàng hỏi "hàng này có node nào không?", mà câu đó sai với mọi băng hộp đen theo định nghĩa. Đối tác biến mất và message flow tới chúng kết thúc giữa không trung. Phép thử đổi thành "có node **hoặc** có băng hộp đen"; sáu tờ gấp đi từ 19 lên 21 trang.

**Tên hộp đen lặp lại trên mỗi trang.** Tên nằm giữa hộp, nên trên một tờ gấp thì tâm rơi vào đúng một trang và mọi trang khác được một dải xám không tên. Nay tên được bóc khỏi bản vẽ chung và căn giữa lại theo phần hộp mà trang đó thật sự nhìn thấy.

## v0.12.0

**Thứ tự chồng lớp, và group vẽ đúng nét gạch-chấm**

Typst không có z-index, thứ tự vẽ *chính là* thứ tự chồng lớp, nên `draw-canvas` phải nói ra. Sáu lớp, từ dưới lên: pool và lane, khung sub-process, sequence flow, node chính, group / annotation / data object, rồi message flow và association trên cùng. Trước đó message flow bị nền và viền của sub-process che mất.

Group thì sai ba chỗ cùng lúc: vẽ bằng `loosely-dashed` thay vì gạch-chấm, nét quá dày, bán kính bo góc là `6pt` tuyệt đối nên không co giãn, và bỏ qua màu tác giả chọn trong `bioc:stroke`. Đặc tả nói dash-**dot**, bpmn-js viết `10,6,0,6`, và cái gạch dài-0 chỉ thành chấm khi có `cap: "round"`.

## v0.11.2

**Tên của sub-process mở rộng nằm ở trên-giữa khung**

Tên đang nằm giữa-giữa, tức là giữa đám node bên trong. BPMN đặt nó ở trên-giữa. Kèm theo, sub-process không còn được vẽ đậm hơn task nằm trong nó: các hàm hình nhận độ dài đã nhân sẵn rồi suy ngược tỉ lệ bằng cách chia cho 100, mà 100 chỉ đúng với một task 100 đơn vị. Một sub-process rộng 350 nhận viền, bán kính và ký hiệu to gấp 3,5 lần. Nay tỉ lệ được truyền xuống qua `unit:`, phép chia chỉ còn là đường lui cho lời gọi tay.

## v0.11.1

**`bp-text(.., scope:)`**

Cho tầng dữ liệu gọi được component: một chuỗi trong YAML có thể chứa lời gọi hàm, và `scope:` quyết định hàm nào nhìn thấy được. Trước đó tầng dữ liệu chỉ viết được chữ.

## v0.11.0

**`noteplace` luật 6: đường dẫn tránh nằm chéo**

Đường dẫn từ thẻ chú giải tới phần tử phải nằm đúng phương ngang hoặc dọc. Một đường chéo đọc ra thành một cạnh của sơ đồ, mà nó không phải.

## v0.10.1

**Nong theo từng trục, và khoá đặt chỗ**

`compact` nong hai trục cùng một lượng, nên một sơ đồ rộng và thấp bị nong sai tỉ lệ. Kèm theo, `whywhy` nhận `root-label` và `root` dạng danh sách, và gạch nối trong nhãn tầng đi qua `bp-text`.

## v0.10.0

**`compact(.., air: N)`**

Sàn cho khoảng trống: bảo đảm mỗi trục còn ít nhất N đơn vị băng trống. `bpmn-notes` cần chỗ đó, vì mọi thẻ chú giải đều bị giam trong khung sơ đồ. Nó cố tình thô: nong *mọi* khoảng, kể cả những khoảng không thẻ nào dùng tới. Hai cách sắc hơn (dành chỗ theo từng mỏ neo, và máng chú giải ngoài lề) nằm trong [roadmap.md](roadmap.md).

Kèm theo, bỏ đường kẻ đóng khung tên lane.

## v0.9.1

**`compact` không nghiền nát pool và lane rỗng**

Trục y nén cả những băng vốn *phải* trống, nên một lane không có node nào bị bóp về gần 0 và pool đọc ra như thiếu một phòng ban.

## v0.9.0

**`bpmn-sheet-info` và `compact:` cho tờ gấp**

`bpmn-sheet-info` trả lời "mô hình này ngốn mấy trang" trước khi dựng, để chốt được ngân sách trang. Khác với `bpmn-info`, vốn trả lời "ở bề rộng này thì nhãn còn mấy pt". Hai câu hỏi khác nhau: một cái về *đọc được không*, một cái về *ngân sách trang*.

## v0.8.0 tới v0.8.4

**`bpmn-sheet`: trải nguyên mô hình ra nhiều trang**

Một mô hình rộng 3000 đơn vị không thể vừa một trang A4 mà vẫn đọc được. `bpmn-sheet` vẽ **một lần** rồi mở nhiều cửa sổ nhìn lên cùng bản vẽ đó, nên các trang ghép lại đúng tỉ lệ. Khác hẳn `bpmn-span`, vốn thật sự bỏ bớt phần tử.

Bốn bản vá liền sau đó, và cả bốn đều là chuyện "xoay cái gì":

- **v0.8.1** xoay sơ đồ chứ không xoay tờ giấy. Xoay tờ giấy thì số trang và đầu trang cũng quay theo.
- **v0.8.2** xoay thuận chiều kim đồng hồ, để lật trang là các mảnh nối được vào nhau. Ngược chiều thì trang sau nối vào *đầu* trang trước.
- **v0.8.3** dải tên lặp lại bị hụt một khoảng đệm, và đổi tên tham số cho khớp với việc nó làm.
- **v0.8.4** `repeat-header: false` xén mất dải tên gốc của trang đầu, tức là tắt phần lặp lại thì mất luôn bản gốc.

## v0.7.0 tới v0.7.5

**`bpportfolio`, và `bptext`**

`bpportfolio` vẽ ma trận danh mục quy trình: Importance × Health × Feasibility. Năm bản vá sau đó là chuyện trình bày: Health thành thang màu lấy từ bảng màu của thư viện chứ không tự chọn hex mới (v0.7.1), bảng chú giải thành lưới với số căn phải (v0.7.3), legend kích thước dựng thành cột dọc ở lề phải (v0.7.4), và gọn lại chiều cao mặc định (v0.7.5).

`bptext` (v0.7.2) gửi chuỗi của tầng dữ liệu qua bộ phân tích của Typst, nên `--` trong một file YAML mới ra en-dash thay vì hai gạch nối. Hai cái bẫy tìm được trong dữ liệu thật đã ghi vào [design-system.md](design-system.md#external-strings): `#` mở một biểu thức code nên `"kho #1"` in ra "kho 1" **không kèm lỗi**, và in đậm là `*một sao*` chứ không phải `**hai sao**`.

## v0.6.0 và v0.6.1

**Thành package Typst, và nhận trọn họ component vẽ quy trình**

Trước đó thư viện được *vendor*: chép `components/` vào repo báo cáo. Cách đó rẻ nhưng trộn hai lịch sử vào một `git log`, và không có gì ghim version. Nay là **package Typst local**: `just install-lib` rồi `#import "@local/typst-bpmn:<ver>"`. Hai lịch sử tách rời, một số version trong dòng import, và một tài liệu đã nộp dựng lại được y hệt.

Cùng lúc đó, repo nhận trọn họ component vẽ quy trình vốn nằm rải trong repo báo cáo: `bpstep`, `bpmap`, `orgchart`, `bptable`, `whywhy`, `annotate`, `noteplace`. Chúng không phải BPMN, nhưng chúng cùng một nghề: đọc một file dữ liệu, vẽ một hình quy trình, và không phụ thuộc gói ngoài.

v0.6.1 sửa đường dẫn `/components/` còn sót sau khi đổi tên thành `src/`, và viết lại tài liệu cho đúng mô hình package.

## v0.5.1 tới v0.5.4

**Bốn bản vá hình học, tất cả về ký hiệu vòng lặp và sự kiện**

- **v0.5.1** sự kiện trung gian và biên mất vòng tròn kép, nên chúng đọc ra thành sự kiện kết thúc. Trọng lượng vòng, bán kính trong và khoảng trắng giữa hai vòng là **một hệ**: vẽ vòng kép ở trọng lượng của vòng đơn thì khoảng trắng ra đúng bằng không.
- **v0.5.2** đồng hồ hẹn giờ căn giữa, và ký hiệu vòng lặp vẽ trên một cung thật thay vì cubic ướm bằng tay.
- **v0.5.3** đầu mũi tên thuộc *về* cung thay vì rời khỏi nó: hai góc đáy nằm trên chính đường tròn của cung, nên đầu mũi tên nghiêng theo và quán tính của cung đi xuyên qua mũi.
- **v0.5.4** đầu mũi tên đo bằng chiều dài và chiều cao, không bằng góc. Gõ góc thì đổi bán kính là đầu mũi tên âm thầm to ra.

## v0.5.0

**Phase 1 xong ở phía này**

`just vendor DEST` chép component sang một repo báo cáo, kèm [integration.md](integration.md). Và fixture pool dọc đi trọn vòng qua Camunda để chứng minh hai bộ phân tích khớp nhau trên cả trục dọc.

## v0.4.0

**Hình tham chiếu được, và bộ đo hồi quy**

`tests/golden.typ` ghi lại một *bảng số* cho ma trận model × view × compact: số phần tử, extent, và cỡ chữ mà extent đó kéo theo ở một bề rộng tham chiếu. Cố ý **không** dùng golden ảnh: một PNG phụ thuộc vào font có trên máy, nên so ảnh sẽ hỏng trên laptop người khác vì lý do không liên quan tới code. Cái giá phải trả là một ký hiệu được vẽ lại thì không làm đổi con số nào; đó chính là việc của `tests/conformance.typ`.

Kèm theo: một process không có pool nào cũng dựng được, và hình tham chiếu được bằng `#ref()`. Tham chiếu phải dùng tham số `label:` chứ không phải `<lbl>` đặt sau, vì hàm trả về một wrapper và nhãn đặt sau sẽ rơi vào wrapper đó.

## v0.3.0

**Phase 0 đóng lại**

Hai mục cuối của bộ ký hiệu: **ba biến thể của cổng theo sự kiện**, vốn được phân biệt bằng `eventGatewayType` và `instantiate` chứ không bằng tên phần tử; và **pool dọc**, có fixture riêng, với dải tên và thứ tự lane quay theo trục của pool, và hộp đen gập về đúng phía nó vốn nằm.

## v0.2.0

**Bộ ký hiệu hoàn chỉnh**

Marker vòng lặp, đa thể hiện song song và tuần tự, bù trừ và ad-hoc; viền dày của call activity; viền kép của transaction; data object dạng tập hợp; data input/output; hình thoi của luồng có điều kiện. Kèm bảng màu Camunda với các tên gọi theo nghĩa (`happy`, `rework`, `external`, ...) chứ không phải theo màu.

Và hai lớp test đầu tiên: `tests/agreement.typ`, hai bộ phân tích phải cho ra dict mô hình giống hệt nhau, là thứ duy nhất chặn giữa một thiết kế hai bộ phân tích và sự trôi dạt âm thầm; `tests/conformance.typ`, bảng ký hiệu ở ba tỉ lệ để nhìn bằng mắt cạnh Camunda Modeler.

## v0.1.0

**Phase 1 chạy được từ đầu tới cuối**

Một file `.bpmn` xuất từ bất kỳ trình vẽ nào đã chứa sẵn **BPMNDI**: bounds tuyệt đối cho mọi shape, waypoint cho mọi cạnh, bounds cho mọi nhãn. Nên đây là bài toán *biến đổi toạ độ*, không phải bài toán bố cục đồ thị. Một câu đó quyết định hình dạng của cả dự án.

Bản đầu tiên có: bộ ký hiệu BPMN, bộ vẽ trung thành với DI, hai đường đọc (XML thẳng trong Typst, và YAML qua bộ chuyển đổi), bố cục lưới làm đường lui cho mô hình không có toạ độ, `compact:` nén băng trống để mua lại cỡ chữ, `view:` cắt lát kèm hộp đen, và bốn chế độ `fit:`.
