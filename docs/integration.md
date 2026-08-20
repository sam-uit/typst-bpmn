# Using typst-bpmn in a document

Three decisions, settled:

| Question | Decision |
| --- | --- |
| Where the library lives | **A Typst local package**: `@local/typst-bpmn:<ver>` |
| Path style | **Absolute from the document root**, for both imports and models |
| How models travel | **Both** `.bpmn` and `.yaml` are committed to the document |

## Why a package rather than vendored copies

Six `.typ` files used to be copied straight into the report's `template/components/`. That was cheap, but it put two different things in one `git log`: editing the report's content and editing the drawing library looked identical when reading the history. Bearable for one report; not bearable for a library that outlives the course.

A local package fixes exactly that: a version number in the `#import` line, one installation directory, and two separate histories. The price is that the document needs an install step, but it is one command and it is reproducible.

## First install

```bash
cd <typst-bpmn> && just install-lib
```

`install-lib` copies `typst.toml` and `src/` into `$XDG_DATA_HOME/typst/packages/local/typst-bpmn/<ver>`. It depends only on `just lint-src` (compile every file in `src/`), so it needs **no** `samples/`, no `models/`, and no sibling `bpmn-generator` checkout. It installs straight from a fresh clone.

Then add one import line to the document's central template file (`template/lib.typ` or equivalent), so every chapter can use it without declaring it again:

```typ
#import "@local/typst-bpmn:0.17.5": *
```

**The version is pinned in the import line.** Raising the library's version means editing this line. That is deliberate: a submitted document has to rebuild identically.

## Editing the library while writing the document

```bash
cd <typst-bpmn> && just link-dev     # point the local store at the repo by symlink
```

From then on, editing `src/*.typ` is visible to the document immediately, with no reinstall. **Run `just install-lib` again before submitting**: the symlink exists only on your machine. `just unlink-lib` removes it entirely.

## One Typst constraint to remember

**A package can only read files inside itself.** A path like `/content/...` inside the package resolves against the *package's* root, not the document's, so a `*-file()` function provided by the package reports a missing file when the document calls it.

So the boundary is: **file reading happens at the document layer.** The package takes data that is already loaded (`bpflow-data`, `bpmap-data`, `orgchart-data`, `bptable-data`, `whywhy`), and the document keeps one `load-data` function plus a few `*-file` shims that call it:

```typ
#let load-data(path, id: none) = { /* yaml() / json() / csv() at the document layer */ }
#let bpflow-file(path, id: none, ..args) = bpflow-data(load-data(path, id: id), ..args)
```

When adding a component that loads a file, put the entry point in `*-data` in the package and the `*-file` shim in the document, not the other way round.

## Layout in the document's repository

```
template/lib.typ                #import "@local/typst-bpmn:<ver>" plus the *-file shims
content/processes/
  admission.bpmn                edit this one in Camunda Modeler
  admission.yaml                produced by bpmn2yaml; committed all the same
justfile                        a `bpmn` recipe that calls bpmn2yaml
```

`bpmn2yaml` belongs to [bpmn-generator](https://github.com/sam-uit/bpmn-generator), not to this repository. The boundary between the two is **the direction the data flows**:

```
brief.yaml ──► .bpmn         bpmn-generator   (authoring)
.bpmn ──► .yaml ──► figure    typst-bpmn      (rendering)
```

A recipe for the document's justfile:

```just
bpmn:
    @for f in content/processes/*.bpmn; do \
        uv run bpmn2yaml "$f" -o "${f%.bpmn}.yaml" --strict; \
    done
```

## Using it in a chapter

```typ
#let admission = yaml("/content/processes/admission.yaml")

#bpmn-figure(
  admission,
  view: (pool: "Applicant"),
  compact: true,
  caption: [The admission process, from the applicant's point of view],
  label: <fig-admission-student>,
)

As @fig-admission-student shows, ...
```

Paths absolute from the root mean a chapter file can move without anything being edited. The part that is **not** optional: use the **`label:` parameter, not a trailing `<lbl>`**, see [README](../README.md#referencing-a-figure).

## Matching the document's typeface

The components default to DejaVu Sans. Pass the document's font once, in `lib.typ`:

```typ
#let bpmn-theme = default-theme + (font: "Lora")
```

then pass `theme: bpmn-theme` at each call, or wrap `bpmn-figure` in a thin document-level helper that passes it for you.

`font-size` is in **BPMN units, not points**: it scales with the diagram. Leave it at 11 unless the body text is unusually large.

## Fitting the page

What to reach for, in order, and why: see [README](../README.md#fitting-a-wide-diagram-onto-a4). On A4 with a 174mm text width:

- A whole collaboration lands around 4pt. Too small. Cut it.
- One pool, compacted: 4.5 to 5pt. Readable in print, tight on screen.
- One lane, compacted: 7pt and up. Comfortable.

`bpmn-info(M, view: .., compact: .., width: 174mm).label-size` gives the number **before** the layout is settled. Worth checking once per diagram rather than guessing from the PDF.

### A turned figure takes a whole page

`fit: "auto"` turns a figure whose labels would fall below `min-font`, and a turned figure is measured against the full page height, so it cannot share a page with the paragraph introducing it. Inside a chapter that usually reads badly: a page of text holding a single line, and then the diagram.

For a slice that is only slightly too small, pin it flat and accept the type size:

```typ
#bpmn-figure(admission, view: (pool: "Applicant"), compact: true,
  fit: "width",              // stay in the flow, do not turn
  theme: bpmn-theme, caption: [...], label: <fig-student>)
```

The rule of thumb: turn a *whole collaboration*, because it needs the room; keep a *single pool or lane slice* flat. `debug: true` reports which mode it chose.

## What to do when the library needs a change

1. Make the change here, in typst-bpmn.
2. `just check`: the two parsers agree, and the golden manifest is unchanged or deliberately re-approved.
3. `just conformance` if a symbol's geometry changed, and **look** at it.
4. `just install-lib`, then raise the version in the document's `#import` line if it changed.

`just check` needs `samples/`, `models/` and a sibling `bpmn-generator` checkout; `just install-lib` needs none of them. That is why the two are kept apart.
