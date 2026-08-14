# Roadmap

Three phases. Phase 1 is the one that has to work; Phase 0 is the groundwork that
makes both other phases credible; Phase 2 is the ambitious one.

---

## Phase 0 — the BPMN component library

**Goal.** A complete, spec-accurate shape vocabulary, as close to Camunda Modeler
as we can get, defined once and reused by every phase.

This is the heavy, unglamorous work. It is listed first because both other phases
sit on top of it: Phase 1 can only render what the vocabulary can draw, and Phase 2
can only lay out what Phase 1 can render.

**Scope.**

- Every event: 5 families × 11 definitions × catch/throw, interrupting and not.
- Every activity: task and the 7 typed tasks, call activity, sub-process
  (collapsed / expanded / event / transaction / ad-hoc), loop and multi-instance
  markers, compensation marker.
- Every gateway: exclusive, parallel, inclusive, event-based (both variants),
  complex.
- Data: object, input, output, collection marker, store.
- Artifacts: group, text annotation.
- Connections: sequence (normal / default / conditional), message, association,
  data association.
- Pools and lanes, horizontal and vertical, expanded and collapsed.

**Status — closed (v0.3.0).**

Added in v0.2.0: loop, multi-instance parallel and sequential, compensation and
ad-hoc markers; call-activity thick border; transaction double border; collection
data objects; data input/output; conditional sequence-flow diamonds; the Camunda
colour palette with semantic aliases.

Closed in v0.3.0, the two items that were still open:

- **Event-based gateway variants.** BPMN distinguishes three renderings by
  `eventGatewayType` and `instantiate` rather than by element name: exclusive
  non-instantiating (two rings + pentagon), exclusive instantiating (one ring +
  pentagon) and parallel (one ring + plus). Ring radii now follow bpmn-js
  exactly — outer inset 0.20 × height, inner 0.26.
- **Vertical pools, tested.** `tests/fixtures/vertical-pools.bpmn` exercises
  `isHorizontal="false"` for pools and lanes. Lane bands and titles now turn with
  the pool, lane and pool ordering follows the pool's own axis, and a black-box
  partner collapses to a band on the side it came from rather than always below.

Out of scope, deliberately: choreography and conversation diagrams.

**Deliverable — done.** `tests/conformance.typ` renders every symbol at three
scales (100 / 55 / 34%) plus both pool orientations, for side-by-side comparison
with Camunda Modeler: `just conformance`. `docs/design-system.md` is kept in step.

**Known limitation carried forward.** When a slice collapses a partner to a black
box, the re-routed message flows take a straight line to the band. If the flow
starts on the far side of the pool it will pass over the shapes in between. Real
routing around obstacles is Phase 2 work (edge bundling / corridor assignment).

### A note on borrowing from bpmn-js

**Settled: we draw our own from the spec.** Two separate things are involved:

- **The symbols themselves** come from the OMG BPMN 2.0 specification, which is
  publicly available. Redrawing from the spec is unambiguous and is what the
  current shapes do.
- **bpmn-js's rendering code and assets** are published by Camunda under the
  bpmn.io licence, which carries an attribution requirement ("powered by
  bpmn.io") and conditions on the watermark. Copying its path data or icons into
  this project would bring those obligations along.

Since the project is not being published or monetised the practical risk is low
either way, but drawing from the spec costs little and keeps the question from
ever arising. bpmn-js stays a **visual reference** — open a diagram, compare
proportions, match them. The one thing taken verbatim is the colour palette's hex
values, which are data rather than artwork and are documented as such in
`components/bpmn-palette.typ`.

---

## Phase 1 — modeler-first (current focus)

**Goal.** Draw in Camunda Modeler; parse and render in Typst; make it fit the page
as well as it possibly can.

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
2. ~~A regression harness.~~ Done in v0.4.0 — `tests/golden.typ` plus
   `just golden`. Structural rather than pixel-based; see
   [architecture.md](architecture.md#testing) for why.
3. ~~Multi-diagram documents: numbering, `#ref()` across turned figures, a list
   of figures.~~ Done in v0.4.0. All three work; referencing needs the `label:`
   parameter rather than a trailing `<lbl>`, because the figure is returned
   inside a wrapper. A separate `bpmn-index()` turned out to be unnecessary —
   `#outline(target: figure.where(kind: image))` does the job.
4. **Open: where the components live in the report template**, and whether models
   are referenced root-absolute or relative to the calling file. This is the last
   gate and it is a decision about the IE203 repo, not about this code.

**Exit criterion.** An IE203 chapter builds end to end with BPMN figures that
need no manual fiddling.

---

## Phase 2 — hand-authored BPMN

**Goal.** Write the process in YAML; the renderer does everything else. No
modeler in the loop.

**Done so far.**

- `row`/`col` grid layout with pool and lane frames derived from content.
- Port allocation: each flow attached to a node gets its own side, so gateway
  branches leave from different vertices.
- Orthogonal routing between allocated ports (straight / L / Z).
- External labels placed on a side no flow is using.
- Flow labels anchored near the source, the way a modeler labels a branch.
- Pools and lanes carry an `id`, so nodes reference `pool: p_mgr` rather than
  repeating a display name — and renaming a pool does not break the model.

**Not done.**

1. **Crossing minimisation.** Edges cross whenever the author's `row`/`col`
   ordering says they should. A layered-layout pass (Sugiyama-style, ordering
   within columns) would fix most of it.
2. **Label collision avoidance.** Labels are placed by rule, not by measurement;
   two long labels in the same neighbourhood can still overlap.
3. **Edge bundling / corridor assignment.** Parallel edges in the same corridor
   share a line; they should be offset.
4. **Boundary events.** The grid layout does not place them on their host's edge.
5. **Automatic `row`/`col`.** Infer position from flow topology so the author only
   writes nodes and flows. This is the real prize and the hardest item.
6. **Lane inference.** Assign lanes from a node's `lane:` key instead of relying
   on row order within a pool.

**Design principle.** Everything above must degrade gracefully: an author who
provides explicit `row`/`col`/`waypoints` always wins over the algorithm. Layout
help should never be layout tyranny.

**Honest assessment.** Items 1–4 are a few days each and worth doing. Item 5 is
where hand-authored BPMN either becomes genuinely pleasant or stays a toy, and it
is also where a naive implementation will look worse than the modeler for a long
time. Sequence it last, behind a flag, and keep the explicit-coordinate path as
the default until it clearly wins.

---

## Cross-cutting

- **Testing.** Golden-image regression per phase; a schema validator for
  hand-written YAML with useful error messages instead of `panic`.
- **Performance.** Not yet measured. The 33-node example renders instantly; a
  300-node model is untested and the compaction pass is `O(n log n)` at best.
- **Documentation.** `docs/` tracks the design; the README stays a front door.
