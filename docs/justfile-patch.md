# justfile — thay `src :=` và thêm ba recipe

`justfile` là file được bảo vệ với `device_commit_files`, nên phần này vá tay hoặc
để tôi vá bằng script qua `device_bash` (đã đối chiếu md5).

## 1. Đường dẫn component đổi từ `components/` sang `src/`

Tìm mọi chỗ `{{src}}/components` và đổi thành `{{src}}/src`. Có ở `lint` và `vendor`.

## 2. Bỏ recipe `vendor` — không còn vendor nữa

Thay bằng ba recipe dưới đây.

```just
# ------------------------------------------------------------- package ---

typst_pkgs := env("XDG_DATA_HOME", home_dir() / ".local/share") / "typst/packages/local"
pkg_name := "typst-bpmn"
pkg_ver := `grep -m1 '^version' typst.toml | cut -d'"' -f2`

# Cài package vào kho local để tài liệu `#import "@local/typst-bpmn:<ver>"` thấy được
install-lib: check
    #!/usr/bin/env bash
    set -euo pipefail
    dest="{{typst_pkgs}}/{{pkg_name}}/{{pkg_ver}}"
    rm -rf "$dest" && mkdir -p "$dest"
    cp typst.toml "$dest/" && cp -r src "$dest/"
    echo "→ đã cài {{pkg_name}}:{{pkg_ver}} vào $dest"
    echo "   dùng: #import \"@local/{{pkg_name}}:{{pkg_ver}}\": *"

# Trỏ kho local vào repo này bằng symlink — sửa là thấy, không phải cài lại
link-dev:
    #!/usr/bin/env bash
    set -euo pipefail
    dest="{{typst_pkgs}}/{{pkg_name}}/{{pkg_ver}}"
    rm -rf "$dest" && mkdir -p "$(dirname "$dest")"
    ln -s "{{src}}" "$dest"
    echo "→ {{pkg_name}}:{{pkg_ver}} đang trỏ thẳng vào repo (symlink)"
    echo "   nhớ chạy lại \`just install-lib\` trước khi nộp bài/đóng gói"

# Gỡ khỏi kho local
unlink-lib:
    rm -rf "{{typst_pkgs}}/{{pkg_name}}/{{pkg_ver}}"
    @echo "→ đã gỡ {{pkg_name}}:{{pkg_ver}}"
```

## 3. `convert` gọi bpmn-generator thay vì script nội bộ

```just
python := env("PYTHON", "uv run --project ../bpmn-generator")

convert:
    @mkdir -p {{models}}
    @for f in {{samples}}/*.bpmn; do \
        [ -e "$f" ] || continue; \
        name=$(basename "$f" .bpmn); \
        {{python}} bpmn2yaml "$f" -o {{models}}/$name.yaml; \
    done
```

Nếu chưa có repo `bpmn-generator` cạnh bên, đặt `PYTHON=...` trỏ tới chỗ khác.
