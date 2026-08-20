# Roadmap

Phase 0 is the groundwork that makes everything else credible, Phase 1 is the one that had to work, and Phase 2 is the ambitious one that has now been retired rather than finished, because another repository answered its question better. Alongside them sits a fourth thing that was never planned as a phase and is now most of the package: the process-drawing family that is not BPMN.

What shipped when is in [changelogs.md](changelogs.md). This file is about what is left.

| | State | Since |
| --- | --- | --- |
| Phase 0, shape vocabulary | closed | v0.3.0 |
| Phase 1, modeler-first | closed | v0.6.0 |
| The process-drawing family | in use, smoke-tested | v0.6.0, smoke from v0.17.0 |
| Phase 2, hand-authored BPMN | retired as a goal, v0.17.4 | the layout side moved to bpmn-generator |

---

## Phase 0: the BPMN component library

**Goal.** A complete, spec-accurate shape vocabulary, as close to Camunda Modeler as we can get, defined once and reused by every phase.

This is the heavy, unglamorous work. It is listed first because both other phases sit on top of it: Phase 1 can only render what the vocabulary can draw, and Phase 2 can only lay out what Phase 1 can render.

**Scope.**

- Every event: 5 families × 11 definitions × catch/throw, interrupting and not.
- Every activity: task and the 7 typed tasks, call activity, sub-process (collapsed / expanded / event / transaction / ad-hoc), loop and multi-instance markers, compensation marker.
- Every gateway: exclusive, parallel, inclusive, event-based (both variants), complex.
- Data: object, input, output, collection marker, store.
- Artifacts: group, text annotation.
- Connections: sequence (normal / default / conditional), message, association, data association.
- Pools and lanes, horizontal and vertical, expanded and collapsed.

**Status: closed (v0.3.0).**

Added in v0.2.0: loop, multi-instance parallel and sequential, compensation and ad-hoc markers; call-activity thick border; transaction double border; collection data objects; data input/output; conditional sequence-flow diamonds; the Camunda colour palette with semantic aliases.

Closed in v0.3.0, the two items that were still open:

- **Event-based gateway variants.** BPMN distinguishes three renderings by `eventGatewayType` and `instantiate` rather than by element name: exclusive non-instantiating (two rings + pentagon), exclusive instantiating (one ring + pentagon) and parallel (one ring + plus). Ring radii now follow bpmn-js exactly: outer inset 0.20 × height, inner 0.26.
- **Vertical pools, tested.** `tests/fixtures/vertical-pools.bpmn` exercises `isHorizontal="false"` for pools and lanes. Lane bands and titles now turn with the pool, lane and pool ordering follows the pool's own axis, and a black-box partner collapses to a band on the side it came from rather than always below.

Out of scope, deliberately: choreography and conversation diagrams.

**Deliverable: done.** `tests/conformance.typ` renders every symbol at three scales (100 / 55 / 34%) plus both pool orientations, for side-by-side comparison with Camunda Modeler: `just conformance`. `docs/design-system.md` is kept in step.

**Known limitation carried forward.** When a slice collapses a partner to a black box, the re-routed message flows take a straight line to the band. If the flow starts on the far side of the pool it will pass over the shapes in between. Routing around obstacles is not planned: it belongs to a layout engine, and layout is bpmn-generator's side of the boundary. Until then the fix is to move the node.

### A note on borrowing from bpmn-js

**Settled: we draw our own from the spec.** Two separate things are involved:

- **The symbols themselves** come from the OMG BPMN 2.0 specification, which is publicly available. Redrawing from the spec is unambiguous and is what the current shapes do.
- **bpmn-js's rendering code and assets** are published by Camunda under the bpmn.io licence, which carries an attribution requirement ("powered by bpmn.io") and conditions on the watermark. Copying its path data or icons into this project would bring those obligations along.

Since the project is not being published or monetised the practical risk is low either way, but drawing from the spec costs little and keeps the question from ever arising. bpmn-js stays a **visual reference**: open a diagram, compare proportions, match them. The one thing taken verbatim is the colour palette's hex values, which are data rather than artwork and are documented as such in `src/bpmn-palette.typ`.

---

## Phase 1: modeler-first

**Goal.** Draw in Camunda Modeler; parse and render in Typst; make it fit the page as well as it possibly can.

**Done.**

- BPMN XML → YAML converter, execution attributes stripped.
- In-Typst XML parser, byte-identical output to the YAML path.
- DI-faithful renderer: pools, lanes, edges, labels, colours.
- `view:` slicing by pool / lane / node set, with black-box counterparts.
- `compact:` whitespace compaction on either axis.
- Fit modes: width / rotate / fixed / auto, with a turned caption.
- Themes, caption override, `bpmn-info()` for measurements.

**Remaining before integration into IE203.**

1. ~~Finish the Phase 0 vocabulary gaps.~~ Done in v0.3.0.
2. ~~A regression harness.~~ Done in v0.4.0: `tests/golden.typ` plus `just golden`. Structural rather than pixel-based; see [architecture.md](architecture.md#testing) for why.
3. ~~Multi-diagram documents: numbering, `#ref()` across turned figures, a list of figures.~~ Done in v0.4.0. All three work; referencing needs the `label:` parameter rather than a trailing `<lbl>`, because the figure is returned inside a wrapper. A separate `bpmn-index()` turned out to be unnecessary: `#outline(target: figure.where(kind: image))` does the job.
4. ~~Where the components live, and how models are referenced.~~ Settled twice. First as vendored copies in the report's `template/components/`; then, in v0.6.0, as a **Typst local package** (`just install-lib`, then `#import "@local/typst-bpmn:<ver>"`). Vendoring was cheap but merged two histories into one `git log`; the package separates them and pins a version. Root-absolute paths and committing both `.bpmn` and `.yaml` survived unchanged. See [integration.md](integration.md).

**Exit criterion.** ~~An IE203 chapter builds end to end with BPMN figures that need no manual fiddling.~~ Met in v0.6.0: the report imports the package and the chapters build with no vendored copy in sight.

**Added after the phase closed**, because the report kept asking for them:

- `bpmn-sheet` (v0.8.0): draw the model **once**, then open several windows onto that one drawing, so a 3000-unit collaboration spreads across pages that still join up. Plus `bpmn-sheet-info` for the page budget (v0.9.0), `view:` to cut elements before cutting pages, and `turn: none` for paper that is already landscape (v0.15.0).
- `compact(.., air: N)` (v0.10.0): a floor under the empty bands, so `bpmn-notes` has somewhere to put a card.
- Black boxes recognised at the parser, not guessed at the slice (v0.13.0), with the name repeated on every page of a fold-out.
- `sheet-turn-icon` (v0.14.0), and `bpmn-span` carrying its context (v0.16.0).

**Still open on this side.**

1. **Message flows to a black box take a straight line.** One that starts on the far side of the pool passes over whatever lies between. This is the one place where obstacle-aware routing would genuinely help on the DI path, and it is narrow enough to be worth doing on its own terms rather than as part of a layout engine. It is in [`TODO.md`](TODO.md); until then the fix is to move the node.
2. **Sub-processes have no drill-down.** An expanded sub-process draws its children in place; a collapsed one is a box. There is no way to render the child plane as its own figure.
3. **Group titles ignore their DI label bounds.** Deliberate for now, because modelers put them where a Typst layout cannot follow, but it is a documented divergence rather than a decision.
4. **No `.bpmn` writer.** The pipeline is one-way. Anything the renderer learns about a diagram cannot be pushed back into the file. [bpmn-generator](https://github.com/sam-uit/bpmn-generator) owns that direction.

---

## The process-drawing family

Nine components arrived together in v0.6.0, lifted out of the report that grew them. None of them is BPMN. All of them share the same three properties, and that is why they belong in one package: they read a **data file**, they draw a **process picture**, and they depend on **no external package**.

| Component | Draws | State |
| --- | --- | --- |
| `bpstep` | a step flow, chevrons or boxes | stable, used throughout the report |
| `bpmap` | a process map, grouped tiles | stable |
| `orgchart` | an org chart | stable |
| `bptable` | a table with the library's own grammar | stable |
| `bpportfolio` | importance × health × feasibility matrix | stable since v0.7.5 |
| `whywhy` | a why-why chain | stable since v0.10.1 |
| `annotate` | callouts laid over any figure | stable |
| `noteplace` | the placement rules `annotate` and `bpmn-notes` share | six rules, rule 6 added in v0.11.0 |
| `bptext` | a data-layer string through Typst's own parser | stable since v0.11.1 |

**What this family is missing, in the order it hurts.**

1. **A smoke layer exists; a golden layer does not.** `tests/smoke.typ` (v0.17.0) drives all six through `examples/family-fixtures.yaml`: empty, one, many, long labels, missing optional keys, and strings carrying `--` and `#`. It catches a component that breaks outright, which is what a refactor causes, and it is deliberately not a golden manifest: it cannot see a changed colour, a changed gap or a drifted alignment. Getting there needs an `*-info()` per component returning counts and extents, the same shape `bpmn-info` has. That is the next item, and it is worth doing before anything is built on top of these six.
2. **No schema validation.** A typo in a key is silently ignored or reaches `panic` with a Typst-level message. The BPMN path has the same gap; a shared validator with useful messages would serve both.
3. **No documentation beyond docstrings.** `docs/design-system.md` covers BPMN geometry and the shared tokens. The family's own conventions live in the source. A `docs/components.md` in the same spirit would close it.
4. **The placement rules are not shared far enough.** `noteplace` was extracted so `annotate` and `bpmn-notes` could agree; `bpstep` and `bpmap` still place their own labels by hand.

---

## Phase 2: hand-authored BPMN, retired

**The goal was.** Write the process in YAML; the renderer does everything else. No modeler in the loop.

**Retired in v0.17.4, because that goal is met, elsewhere, and better.** [bpmn-generator](https://github.com/sam-uit/bpmn-generator)'s `bpmn-brief` takes coordinate-free YAML and produces a laid-out diagram: layering along the longest path, back-edge detection, row inheritance, orthogonal routing, structural repair, and since its v0.6.0 a native vertical layout. It reaches the same destination by a better road, because what it emits is a real `.bpmn` with real BPMNDI. That file opens in Camunda Modeler, converts back through `bpmn2yaml`, and survives a round trip unchanged. A grid layout inside this package produces a rendered figure and nothing else, so the author who wants to adjust one edge has nowhere to do it.

**What was built, and stays.** `bpmn-grid.typ` is not withdrawn. It renders coordinate-free YAML with no Python anywhere in the loop, which is worth keeping for exactly that reason:

- `row`/`col` grid layout with pool and lane frames derived from content.
- Port allocation: each flow attached to a node gets its own side, so gateway branches leave from different vertices.
- Orthogonal routing between allocated ports (straight / L / Z).
- External labels placed on a side no flow is using.
- Flow labels anchored near the source, the way a modeler labels a branch.
- Pools and lanes carry an `id`, so nodes reference `pool: p_mgr` rather than repeating a display name.

**Its ceiling, stated rather than discovered.** About a dozen nodes and two pools, which is what `examples/leave-request.yaml` and the `grid` case in the golden manifest exercise. Past that, write a brief and run it through `bpmn-brief`. The README says the same thing at the top, and it is now a decision rather than an apology.

**Three of the six open items are dropped**, not deferred. Crossing minimisation, edge bundling and automatic `row`/`col` are a layout engine. Building a second one here means two engines that have to agree, and unlike the two *parsers*, which `tests/agreement.typ` compares mechanically on every push, two layout engines can only be compared by eye. That is the drift problem in its worst form: expensive to build, impossible to police, and the second engine would be the weaker of the two on the day it shipped.

**Two of them were never phase work.** A boundary event drawn away from its host and a `lane:` key that the grid ignores are defects, not ambitions, and they moved to [`TODO.md`](TODO.md) where they can be fixed in an afternoon each.

**One is marginal.** Label collision avoidance applies only to the grid path, since labels on the DI path come from the modeler. It stays listed in `TODO.md` at low priority.

**What replaces it as the boundary between the two repositories:** *bpmn-generator owns layout, typst-bpmn owns rendering.* `bpmn-grid` is the exception that predates the split, and it is scoped rather than grown. The direction of travel is already documented in [integration.md](integration.md).

---

## Making room for notes: beyond `air:`

`compact(.., air: N)` is shipped: it guarantees at least N units of empty band on an axis, which is what `bpmn-notes` needs, since every comment card is confined to the inside of the diagram box. It is deliberately blunt: it grows *every* gap, including the ones no card will ever use. Two sharper things, in the order they are worth doing:

1. **Reserve per anchor.** Grow only the gap on the `side:` a note asks for, by the height the card actually measures. Needs two passes: measure the cards, build the y-map from those measurements, re-render. Precise, and it stops a diagram from doubling in height to fit one card. This is the one to build next.
2. **Comment gutter.** Do not touch the lanes at all: widen `meta.extent` on one side and let the solver put every card in that band, with leader lines back to the shapes. Cheapest of the three, and for a figure that is mostly commentary it reads better than cards scattered through the diagram. Worth having as a *mode*, not as a replacement: a card next to the step it discusses beats a card in a margin whenever there is room for it.

Both compose with `air:` rather than replacing it.

---

## Cross-cutting

- **Testing.** Four layers now: agreement, golden and conformance on the BPMN path (see [architecture.md](architecture.md#testing)), plus `tests/smoke.typ` on the process-drawing family. Extending the *structural manifest* to that family is item 1 above; smoke is a floor, not a ceiling.
- **Validation.** A schema validator for hand-written YAML, with useful messages instead of `panic`, serving both the BPMN path and the family.
- **Performance.** Not yet measured. The 33-node example renders instantly; a 300-node model is untested and the compaction pass is `O(n log n)` at best.
- **Documentation.** `docs/` tracks the design, the README stays a front door, and [changelogs.md](changelogs.md) records what each version changed and why. Prose in this repo follows one rule worth stating because it is easy to undo: **one paragraph is one line**, no manual wrapping. Wrapping makes `git diff` claim a whole paragraph changed when one word did, and it makes every search-and-replace slip past strings that happen to straddle a line break.
