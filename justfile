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

# ------------------------------------------------------------------ check ---

# Converter runs clean and both parsers agree on every sample
check: convert-strict
    @mkdir -p {{out}}
    {{typst}} compile --root {{src}} {{font_flag}} \
        {{src}}/tests/agreement.typ {{out}}/agreement.pdf
    @echo "✓ converter strict-clean, parsers agree"

# Typst syntax check without producing output
lint:
    @for f in {{src}}/components/*.typ {{src}}/demo.typ {{src}}/tests/*.typ; do \
        {{typst}} compile --root {{src}} {{font_flag}} "$f" /dev/null 2>/dev/null \
            && echo "ok   $(basename $f)" || echo "FAIL $(basename $f)"; \
    done

# ------------------------------------------------------------------ chores ---

clean:
    rm -rf {{out}}

# Drop generated models too
clean-all: clean
    rm -rf {{models}}
