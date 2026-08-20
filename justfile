# typst-bpmn: build runner
#
#   just            list recipes
#   just watch      live-rebuild the demo while you edit
#   just check      converter + parser-agreement checks
#
# Needs: typst 0.15+, python3. `just` itself: brew install just

typst := env("TYPST", "typst")
python := env("PYTHON", "uv run --project ../bpmn-generator")

# extra font directory, if the fonts are not installed system-wide
fonts := env("BPMN_FONTS", "")
font_flag := if fonts == "" { "" } else { "--font-path " + fonts }

src := justfile_directory()
samples := src / "samples"
models := src / "models"
out := src / "out"

default:
    @just --list --unsorted

# ---------------------------------------------------------------- convert ---

# Convert every .bpmn the tests need into models/*.yaml
#
# Hai nguồn, và lý do phải có cả hai: `samples/` là dữ liệu vào, cố ý không nằm trong
# repo. `tests/fixtures/` thì nằm trong repo, vì đó là đầu vào của bộ kiểm, do mình viết.
# Trước đây vòng lặp chỉ quét `samples/`, nên `models/vertical-pools.yaml` và
# `models/leading-comment.yaml` là hai file mồ côi không lệnh nào dựng lại được:
# `just clean-all` là mất vĩnh viễn, và `just check` hỏng cho tới khi chép tay lại.
convert:
    @mkdir -p {{models}}
    @for f in {{samples}}/*.bpmn tests/fixtures/*.bpmn; do \
        [ -e "$f" ] || continue; \
        name=$(basename "$f" .bpmn); \
        {{python}} bpmn2yaml "$f" -o {{models}}/$name.yaml; \
    done

# Convert, failing on any drawable element the converter does not recognise
convert-strict:
    @mkdir -p {{models}}
    @for f in {{samples}}/*.bpmn tests/fixtures/*.bpmn; do \
        [ -e "$f" ] || continue; \
        name=$(basename "$f" .bpmn); \
        {{python}} bpmn2yaml "$f" -o {{models}}/$name.yaml --strict; \
    done

# Convert one file: just one samples/foo.bpmn
one FILE:
    @mkdir -p {{models}}
    {{python}} bpmn2yaml {{FILE}} \
        -o {{models}}/$(basename {{FILE}} .bpmn).yaml

# ------------------------------------------------------------------ build ---

# Build the demo document
demo: convert
    @mkdir -p {{out}}
    {{typst}} compile --root {{src}} {{font_flag}} {{src}}/demo.typ {{out}}/demo.pdf
    @echo "→ out/demo.pdf"

# Rebuild the demo on every save
watch: convert
    @mkdir -p {{out}}
    {{typst}} watch --root {{src}} {{font_flag}} {{src}}/demo.typ {{out}}/demo.pdf

# Build the visual conformance sheet: every symbol at three scales
conformance:
    @mkdir -p {{out}}
    {{typst}} compile --root {{src}} {{font_flag}} \
        {{src}}/tests/conformance.typ {{out}}/conformance.pdf
    @echo "→ out/conformance.pdf"

# Rebuild the conformance sheet on every save
watch-conformance:
    @mkdir -p {{out}}
    {{typst}} watch --root {{src}} {{font_flag}} \
        {{src}}/tests/conformance.typ {{out}}/conformance.pdf

# Render page 1 of a document to PNG, for a quick look
png FILE="demo.typ" PPI="140":
    @mkdir -p {{out}}
    {{typst}} compile --root {{src}} {{font_flag}} --format png --ppi {{PPI}} \
        {{src}}/{{FILE}} "{{out}}/$(basename {{FILE}} .typ)-{n}.png"

# Everything
all: convert-strict demo conformance

# ---------------------------------------------------------------- package ---

# Typst tìm package local trong thư mục *data của hệ điều hành*, không phải một
# đường dẫn cố định. Đoán sai thì `install-lib` báo thành công còn Typst vẫn nói
# "package not found": im lặng và khó lần ra.
#
#   macOS    ~/Library/Application Support/typst   (KHÔNG phải ~/.local/share)
#   Linux    $XDG_DATA_HOME/typst, mặc định ~/.local/share/typst
#   Windows  %APPDATA%\typst
typst_data := if os() == "macos" {
    home_directory() / "Library/Application Support"
} else if os() == "windows" {
    env("APPDATA", home_directory() / "AppData/Roaming")
} else {
    env("XDG_DATA_HOME", home_directory() / ".local/share")
}
typst_pkgs := env("TYPST_LOCAL_PKGS", typst_data / "typst/packages/local")
pkg_name := "typst-bpmn"

# Kho local đang nằm ở đâu, và có gì trong đó
where-lib:
    #!/usr/bin/env bash
    echo "hệ điều hành : {{os()}}"
    echo "kho local    : {{typst_pkgs}}"
    if [ -d "{{typst_pkgs}}/{{pkg_name}}" ]; then
        echo "đã cài       : $(ls "{{typst_pkgs}}/{{pkg_name}}" | tr '\n' ' ')"
    else
        echo "đã cài       : (chưa có gì), chạy \`just install-lib\`"
    fi
    other="$HOME/.local/share/typst/packages/local/{{pkg_name}}"
    if [ "{{os()}}" != "linux" ] && [ -d "$other" ]; then
        echo "CẢNH BÁO     : còn một bản cũ ở $other mà Typst không đọc, xoá đi"
    fi

# Cài package vào kho local: tài liệu dùng `#import "@local/typst-bpmn:<ver>"`
install-lib: lint-src version-check
    #!/usr/bin/env bash
    set -euo pipefail
    ver=$(grep -m1 '^version' typst.toml | cut -d'"' -f2)
    dest="{{typst_pkgs}}/{{pkg_name}}/$ver"
    rm -rf "$dest" && mkdir -p "$dest"
    cp typst.toml "$dest/" && cp -r src "$dest/"
    echo "→ đã cài {{pkg_name}}:$ver"
    echo "   vào : $dest"
    echo "   dùng: #import \"@local/{{pkg_name}}:$ver\": *"
    other="$HOME/.local/share/typst/packages/local/{{pkg_name}}"
    if [ "{{os()}}" != "linux" ] && [ -d "$other" ]; then
        echo "   ! còn một bản cũ ở $other mà Typst không đọc, xoá đi cho khỏi lẫn"
    fi

# Trỏ kho local vào repo này bằng symlink, sửa là thấy, không phải cài lại
link-dev:
    #!/usr/bin/env bash
    set -euo pipefail
    ver=$(grep -m1 '^version' typst.toml | cut -d'"' -f2)
    dest="{{typst_pkgs}}/{{pkg_name}}/$ver"
    rm -rf "$dest" && mkdir -p "$(dirname "$dest")"
    ln -s "{{src}}" "$dest"
    echo "→ {{pkg_name}}:$ver trỏ thẳng vào repo (symlink)"
    echo "   chạy lại \`just install-lib\` trước khi đóng gói/nộp"

# Gỡ khỏi kho local
unlink-lib:
    #!/usr/bin/env bash
    ver=$(grep -m1 '^version' typst.toml | cut -d'"' -f2)
    rm -rf "{{typst_pkgs}}/{{pkg_name}}/$ver"
    echo "→ đã gỡ {{pkg_name}}:$ver"

# ----------------------------------------------------------------- golden ---

golden_file := src / "tests" / "golden" / "manifest.json"

# Regenerate the structural manifest and diff it against the approved one
golden: convert
    @mkdir -p {{out}}
    @{{typst}} query --root {{src}} {{font_flag}} --field value --one \
        {{src}}/tests/golden.typ '<golden>' --pretty > {{out}}/manifest.json
    @if diff -u {{golden_file}} {{out}}/manifest.json > {{out}}/golden.diff; then \
        echo "✓ golden manifest unchanged ($(grep -c '\"nodes\"' {{golden_file}}) cases)"; \
    else \
        echo "✗ golden manifest drifted:"; cat {{out}}/golden.diff; \
        echo "   review, then: just golden-update"; exit 1; \
    fi

# Re-approve the manifest after an intentional change
golden-update: convert
    @mkdir -p $(dirname {{golden_file}})
    {{typst}} query --root {{src}} {{font_flag}} --field value --one \
        {{src}}/tests/golden.typ '<golden>' --pretty > {{golden_file}}
    @echo "→ approved $(grep -c '\"nodes\"' {{golden_file}}) cases"

# ------------------------------------------------------------------ check ---

# Converter clean, parsers agree, structural manifest unchanged
# Số version phải khớp `typst.toml` và mọi dòng `#import` trong tài liệu.
#
# Vì sao là một recipe chứ không phải một thói quen: README và integration.md đứng yên
# ở `0.7.5` qua chín lần phát hành minor, mà đó lại là dòng đầu tiên người dùng chép.
# Quy ước "version phải khớp ba chỗ" chỉ có nghĩa khi có cái gì đó kiểm nó.
#
# `changelogs.md` được loại trừ: một changelog *phải* trích số version cũ, đó là việc
# của nó. Không loại thì recipe này báo lỗi ngay ở bản đầu tiên nó được thêm vào.
version-check:
    @ver=$(grep '^version' typst.toml | cut -d'"' -f2); \
    files=$(ls README.md docs/*.md | grep -v 'changelogs.md'); \
    bad=$(grep -n "@local/typst-bpmn:[0-9]" $files | grep -v "typst-bpmn:$ver" || true); \
    if [ -n "$bad" ]; then \
        echo "version lệch: typst.toml là $ver, còn tài liệu ghi:"; \
        echo "$bad"; \
        exit 1; \
    fi; \
    echo "✓ version khớp ($ver)"

# Smoke test cho họ component vẽ quy trình. Không cần `models/`, nên chạy được ngay
# trên một bản clone sạch. Xem chú thích đầu tests/smoke.typ cho phạm vi của nó.
smoke:
    @mkdir -p {{out}}
    @{{typst}} compile --root {{src}} {{font_flag}} {{src}}/tests/smoke.typ {{out}}/smoke.pdf
    @echo "✓ smoke: mọi component dựng được trên mọi hình dạng dữ liệu thử"

check: convert-strict golden version-check smoke
    @mkdir -p {{out}}
    {{typst}} compile --root {{src}} {{font_flag}} \
        {{src}}/tests/agreement.typ {{out}}/agreement.pdf
    @echo "✓ converter strict-clean, parsers agree"

# Gate for `install-lib`: compile every src/ file, no models/, no sibling repo
lint-src:
    #!/usr/bin/env bash
    set -uo pipefail
    bad=0
    for f in {{src}}/src/*.typ; do
        if {{typst}} compile --root {{src}} {{font_flag}} -f pdf "$f" /dev/null 2>/dev/null; then
            echo "ok   $(basename $f)"
        else
            echo "FAIL $(basename $f)"; bad=1
        fi
    done
    exit $bad

# Same, plus demo.typ and tests/: those need models/, so `just convert` first
lint: lint-src
    #!/usr/bin/env bash
    set -uo pipefail
    bad=0
    for f in {{src}}/demo.typ {{src}}/tests/*.typ; do
        if {{typst}} compile --root {{src}} {{font_flag}} -f pdf "$f" /dev/null 2>/dev/null; then
            echo "ok   $(basename $f)"
        else
            echo "FAIL $(basename $f)"; bad=1
        fi
    done
    exit $bad

# ------------------------------------------------------------------ chores ---

clean:
    rm -rf {{out}}

# Drop generated models too
clean-all: clean
    rm -rf {{models}}
