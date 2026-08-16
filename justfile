# typst-bpmn — build runner
#
#   just            list recipes
#   just watch      live-rebuild the demo while you edit
#   just check      converter + parser-agreement checks
#
# Needs: typst 0.15+, python3. `just` itself: brew install just

typst := env("TYPST", "typst")
python := env("PYTHON", "python3")

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

# Convert every sample .bpmn into models/*.yaml
convert:
    @mkdir -p {{models}}
    @for f in {{samples}}/*.bpmn; do \
        [ -e "$f" ] || continue; \
        name=$(basename "$f" .bpmn); \
        {{python}} {{src}}/tools/bpmn2yaml.py "$f" -o {{models}}/$name.yaml; \
    done

# Convert, failing on any drawable element the converter does not recognise
convert-strict:
    @mkdir -p {{models}}
    @for f in {{samples}}/*.bpmn; do \
        [ -e "$f" ] || continue; \
        name=$(basename "$f" .bpmn); \
        {{python}} {{src}}/tools/bpmn2yaml.py "$f" -o {{models}}/$name.yaml --strict; \
    done

# Convert one file: just one samples/foo.bpmn
one FILE:
    @mkdir -p {{models}}
    {{python}} {{src}}/tools/bpmn2yaml.py {{FILE}} \
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

# Build the visual conformance sheet — every symbol at three scales
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

# ----------------------------------------------------------------- vendor ---

version := `git describe --tags --always --dirty 2>/dev/null || echo "unknown"`

# Copy the components into a report's template, stamped with this version
vendor DEST:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{DEST}}"
    for f in {{src}}/components/bpmn*.typ; do
        name=$(basename "$f")
        {
          echo "// vendored from typst-bpmn {{version}} — do not edit here."
          echo "// Change it upstream, run \`just check\`, then re-run \`just vendor\`."
          echo ""
          cat "$f"
        } > "{{DEST}}/$name"
        echo "  $name"
    done
    echo "→ vendored {{version}} into {{DEST}}"
    echo "   remember tools/bpmn2yaml.py if the report converts its own models"

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
check: convert-strict golden
    @mkdir -p {{out}}
    {{typst}} compile --root {{src}} {{font_flag}} \
        {{src}}/tests/agreement.typ {{out}}/agreement.pdf
    @echo "✓ converter strict-clean, parsers agree"

# Typst syntax check without producing output
lint:
    @for f in {{src}}/components/*.typ {{src}}/demo.typ {{src}}/tests/*.typ; do \
        {{typst}} compile --root {{src}} {{font_flag}} -f pdf "$f" /dev/null 2>/dev/null \
            && echo "ok   $(basename $f)" || echo "FAIL $(basename $f)"; \
    done

# ------------------------------------------------------------------ chores ---

clean:
    rm -rf {{out}}

# Drop generated models too
clean-all: clean
    rm -rf {{models}}
