# Integrating into a report (IE203)

The three decisions, settled:

| Question | Decision |
| --- | --- |
| Where the components live | **Vendored** into the report's `template/components/` |
| Path style | **Root-absolute** for both imports and models |
| Model pipeline | **Both** `.bpmn` and converted `.yaml` committed to the report |

## Why vendored rather than a package

The report has to build from a fresh clone with nothing installed. A Typst local package (`@local/typst-bpmn`) is cleaner on versioning but moves a build dependency outside the repo, and a submodule makes the build depend on a checkout
sitting in the right place. Copying six `.typ` files costs nothing and matches how `bpstep` and `bpmap` already live there.

typst-bpmn stays upstream: changes are made and tested here, then re-vendored. `just vendor` stamps the version into each copied file so a report can say which one it is carrying.

## One-time setup

```bash
# from the typst-bpmn checkout
just vendor ~/repos/ie203-report/template/components
```

Then add the import to the report's central template file — `template/lib.typ` or equivalent — so every chapter gets it for free:

```typ
#import "/template/components/bpmn.typ": *
```

Layout in the report repo:

```
template/components/bpmn*.typ     vendored, do not edit here
content/processes/
  admission.bpmn                  edit this in Camunda Modeler
  admission.yaml                  generated; commit it
justfile                          add a `bpmn` recipe (below)
```

Regeneration recipe for the report's own justfile:

```just
# Reconvert every BPMN model
bpmn:
    @for f in content/processes/*.bpmn; do \
        python3 tools/bpmn2yaml.py "$f" -o "${f%.bpmn}.yaml" --strict; \
    done
```

Copy `tools/bpmn2yaml.py` across as well — it is the only non-Typst piece.

## Using it in a chapter

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

Root-absolute paths mean a chapter file can move between directories without any edit. The one thing that is *not* optional: **`label:` rather than a trailing `<lbl>`** — see [the README](../README.md#referencing-a-figure) for why.

## Matching the report's typography

The component defaults to DejaVu Sans. Give it the report's font once, in `lib.typ`:

```typ
#let bpmn-theme = default-theme + (font: "Lora")
```

and pass `theme: bpmn-theme` at each call, or wrap `bpmn-figure` in a thin report-local helper that supplies it.

`font-size` is in **BPMN units, not points** — it scales with the diagram. Leave it at 11 unless the report's body text is unusually large.

## Fitting diagrams to the page

In order of what to reach for, and why, see [the README](../README.md#fitting-a-wide-diagram-onto-a4). For a typical A4 report body at 174mm text width:

- A whole collaboration will land around 4pt. Too small. Slice it.
- One pool, compacted: 4.5–5pt. Readable in print, tight on screen.
- One lane, compacted: 7pt+. Comfortable.

`bpmn-info(M, view: .., compact: .., width: 174mm).label-size` gives the number before you commit to a layout, which is worth checking once per diagram rather than eyeballing the PDF.

### A turned figure takes its own page

`fit: "auto"` will turn a figure whose labels would otherwise fall below `min-font`, and a turned figure is sized against the full page height — so it cannot share a page with the paragraph that introduces it. In a chapter that usually reads badly: a page of text with one line on it, then the diagram.

For a slice that is only mildly too small, pin it flat and accept the type size:

```typ
#bpmn-figure(admission, view: (pool: "Thí Sinh"), compact: true,
  fit: "width",              // stay inline, do not turn
  theme: bpmn-theme, caption: [...], label: <fig-student>)
```

Rule of thumb: turn a *whole collaboration* (it needs the space), keep *single pool and lane slices* flat. `debug: true` tells you which mode it picked.

## Keeping the vendored copy honest

The report should not edit `template/components/bpmn*.typ`. If something needs changing:

1. Change it here, in typst-bpmn.
2. `just check` — parsers agree, golden manifest unchanged or re-approved.
3. `just conformance` if a shape changed, and look at it.
4. `just vendor <report>/template/components` again.

The version stamp at the top of each vendored file makes a stale copy obvious.
