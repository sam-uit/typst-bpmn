# Changelogs

Every tagged version gets an entry here, newest first. Entries explain rather than list: what changed, why it was needed, and what was considered and dropped. This is not a list of commits; `git log` already does that.

Numbering: **minor** for a new component or a new capability, **patch** for a fix or an extension to something that exists. The version has to agree in three places: `typst.toml`, the `#import` line in this library's own documentation, and `template/pkg.typ` on the report's side.

## v0.17.4

**Phase 2 retired, a TODO of its own, and `docs/` in English**

**Phase 2 is retired rather than finished.** Its goal was "write the process in YAML, the renderer does the rest, no modeler in the loop", and that goal is now met by [bpmn-generator](https://github.com/sam-uit/bpmn-generator), which reaches it by a better road: `bpmn-brief` emits a real `.bpmn` with real BPMNDI, so the diagram opens in a modeler, converts back, and survives a round trip. A grid layout in this package produces a rendered figure and nothing else, so an author who wants to move one edge has nowhere to do it.

Three of its six open items are **dropped, not deferred**. Crossing minimisation, edge bundling and automatic `row`/`col` are a layout engine, and building a second one here means two engines that have to agree. Unlike the two *parsers*, which `tests/agreement.typ` compares mechanically on every push, two layout engines can only be compared by eye. Two more items were never phase work at all: a boundary event drawn away from its host and a `lane:` key the grid ignores are defects, and they moved to the new `TODO.md`. The sixth, label collision on the grid path, is there too at low priority.

`bpmn-grid.typ` stays, with its ceiling written down instead of discovered: about a dozen nodes and two pools, which is what `examples/leave-request.yaml` and the `grid` case in the golden manifest exercise. The boundary that replaces the phase is simpler to state and easier to hold: **bpmn-generator owns layout, typst-bpmn owns rendering.**

**`docs/TODO.md`**, mirroring the convention bpmn-generator already had. The roadmap says where the project is going; a reader who wants to know what is broken today should not have to infer it from a phase plan. Seven items, each with a reproducer. The one at the top is an `*-info()` per family component, which turns the smoke layer into a golden layer for the six components that currently have no structural guard at all.

**`docs/` is now English.** `integration.md` (141 lines), the last Vietnamese lines of `schema.md` and `design-system.md`, and all 37 entries of this changelog. Translated whole files at a time rather than line by line, which is the unit the language rule asks for. Example labels and step names were translated with the prose, so the documents read in one language throughout.

Two things were deliberately not translated. The quoted string `"(1/3 — Phòng Marketing)"` in the v0.16.4 entry is a verbatim quotation of the text that broke the em-dash rule, and the entry stops making sense without it; it remains the only em-dash in the repository. And the sample models under `samples/` keep their Vietnamese element names, because they are real models from the report and their ids are referenced by name from the report's chapters.

That leaves the source comments in `src/` as the remaining Vietnamese, which is the larger half of the backlog and a separate pass.

## v0.17.3

**The em-dash sweep finishes, and the converter pin moves to v0.6.1**

**Six em-dashes the sweep missed.** v0.16.4 swept `src/`, and `demo.typ` and `examples/leave-request.yaml` are not in `src/`. Five were in demo captions and one in a comment that teaches the `color:` key, which means all six were in text a reader meets early. Replaced by meaning: a colon where the second half explains the first, a comma where it qualifies. The only em-dash left in the repository is inside a changelog entry quoting the old string it replaced, which has to stay for the entry to make sense.

**The converter pin moves from v0.5.1 to v0.6.1**, five releases of `bpmn-generator` in one step, and it was checked rather than assumed. Every model this library reads through YAML (`b04-btvn01`, `vertical-pools`, `leading-comment`) was converted with both versions and compared: the only difference is a new `process:` key on each pool, and nothing here reads it. The golden manifest cannot move. What the newer converter brings is worth having: pools that own a process are no longer silently flattened into black boxes, so a model with a single-role pool now arrives intact.

It also closes a gap the two parsers had. `bpmn-xml.typ` marks a participant with no `processRef` as a black box; the YAML path could not, because the converter never wrote the flag, so the same model drew one way through `xml()` and another through `yaml()`. From v0.5.4 the converter states `blackbox: true`, and the two agree. None of the current agreement pairs contains a black box, so nothing moves today; the pairing in `tests/agreement.typ` can now be extended to `two-blackboxes.bpmn`, which was impossible before and is the obvious next line in that file.

Order matters when this lands: `bpmn-generator` v0.6.1 has to be pushed and tagged before the commit that raises the pin, or CI installs a tag that does not exist yet.

## v0.17.2

**The English-only rule covers commit messages, said out loud**

`CONTRIBUTING.md` already listed commit messages among the things written in English, and that was still the part being missed. A commit message is not in any file anybody reopens, so nothing brings it back into view the way a stale comment does. It is documentation that outlives the diff it describes, and it now says so in the rule rather than only appearing in a list.

No code changed. The version moves because the repository logs every change, and because `just version-check` requires `typst.toml` and the documentation to agree whatever the reason for the bump.

## v0.17.1

**CONTRIBUTING.md, and English as a rule**

The conventions this repository follows were, until now, held in one person's head and in a memory file outside the repository. A clone did not carry them, so the first thing a second reader would do is guess, and guess differently in each file. [`CONTRIBUTING.md`](../CONTRIBUTING.md) writes them down: language, naming, punctuation, Markdown source, changelog, dependencies, and what to run before committing.

Each rule carries the reason it is a rule. That is deliberate. A convention with no stated reason reads as taste, and taste is negotiable at three in the morning when something needs to ship; a convention whose cost is written next to it is not.

**English only**, from 2026-08-20, for documentation, comments, docstrings, panic messages, `just` recipe descriptions and commit messages. This library started inside a Vietnamese-language report and most of its prose is still Vietnamese, so the rule as written applies to everything **newly** written, and the existing backlog is scheduled for one planned pass. Translating a file here and a file there while doing other work was considered and rejected: a half-translated file costs the reader more than a consistently Vietnamese one, and a translation pass mixed into a behaviour change makes the behaviour change unreviewable.

**Dependencies must be stated** is the rule with real teeth. `bpmn2yaml` comes from another repository, the version number has to agree in three places across two repositories, and neither fact is visible from inside a single file. `just version-check` already guards the part a machine can guard; the document covers the rest.

Version bumped to 0.17.1 in `typst.toml`, `README.md` and `docs/integration.md` together, which is exactly what `just version-check` exists to enforce. That recipe now scans `CONTRIBUTING.md` as well: it is a document that teaches the import line, so it is a document that can state the wrong version.

## v0.17.0

**LICENSE, CI, and the first test layer for the component family**

Three items left over from the solidity review, plus one that Sam had already done on his side.

**`tests/smoke.typ`.** `bpstep`, `bpmap`, `orgchart`, `bptable`, `bpportfolio` and `whywhy` come to 2721 lines between them, 39% of `src/`, and until this release not one line of them was covered by a test. Not out of laziness: they were migrated in from the report's repository, where the thing under test was the final PDF, so each component had only ever seen exactly one real data file.

The tests therefore go by the **shape of the data** rather than by its content: empty, one element, many elements, long labels, missing optional keys, and strings containing `--` and `#` so that the `bp-text` path is exercised too. 17 cases, with the data in `examples/family-fixtures.yaml`.

They assert exactly two things: that building does not blow up, and that the result is a block with a finite non-zero size, except for the cases that are deliberately empty. They do not compare measurements against expected values, because measurements depend on the fonts installed and the tests have to run on another machine. The scope, stated plainly: **this is not a golden manifest**. It cannot see a changed colour, a changed gap or a drifted alignment. What it does see immediately is a component that breaks outright, which is exactly what a refactor causes. For six files with nothing guarding them at all, that is the most valuable first step, and the next one is written down in [`roadmap.md`](roadmap.md).

It needs no `models/`, so it runs on a clean clone. Added to `just check`.

**CI.** `.github/workflows/check.yml` runs `just check` and `just lint` on every push and every pull request. Until now the check gate ran only when somebody remembered to run it. It can run here because `samples/b04-btvn01.bpmn` is in the repository: building a trial clone containing only the files `git ls-files` lists shows that all four layers plus `demo.typ` build.

`bpmn2yaml` is **pinned to a tag** rather than tracking the default branch, for the same reason `template/pkg.typ` is pinned on the report's side: a change to the converter can move the golden manifest, and that has to be a decision.

**LICENSE.** `typst.toml` has declared `license = "MIT"` since v0.6.0 with no licence file in the repository. Not a problem while it was used internally, but a hard requirement for publishing to Typst Universe.

**`typst.toml`'s `exclude`** gains `.github` and drops the deleted `plan.md`.

And the last two phantom names: `bpmn-lane` and `bpmn-part` were still in the docstring of `whywhy.typ`.

## v0.16.5

**`just version-check`, and a version number that had stood still for nine releases**

The README and `docs/integration.md` still said `#import "@local/typst-bpmn:0.7.5"` while the package was at 0.16.4. That is the **first** line a user copies, and it was wrong across nine consecutive minor releases.

The repository's convention is "the version has to agree in three places: `typst.toml`, the `#import` line in the documentation, and `template/pkg.typ` on the report's side". A convention nothing checks is a promise, not a rule. Now there is `just version-check`, and it is a prerequisite of both `just check` and `just install-lib`, which means a release whose own documentation states the wrong number cannot be installed.

## v0.16.4

**The writing conventions applied to the code base, and two bugs found while sweeping**

249 uses of the em-dash across `src/`, `tests/` and the `justfile`. Same three rules used on `docs/` in v0.16.3: replaced by meaning rather than mechanically turned into commas.

19 of them were **not** comments, and that is the part worth noting. `bpmn-sheet` printed the page label `"(1/3 — Phòng Marketing)"`, text that goes straight into the report's PDF, so the rule was being broken in the most visible place there is. The rest were three `panic` messages, three `echo` lines in the justfile, and twelve strings in `tests/conformance.typ` that are printed onto the comparison sheet itself.

Two bugs surfaced during the sweep:

**`models/` had two orphan files.** `just convert` only scanned `samples/`, while `tests/agreement.typ` and `tests/conformance.typ` need `models/vertical-pools.yaml` and `models/leading-comment.yaml`, which are generated from `tests/fixtures/`. No command could rebuild those two, so `just clean-all` would have destroyed them permanently and `just check` would have stayed broken until they were recreated by hand. The loop now scans both sources; all three fixtures were checked through `bpmn2yaml --strict` clean.

**`bpmn-lane` and `bpmn-part` do not exist.** The header comment of `bpmn-sheet.typ` introduced them as siblings of `bpmn-span`. The actual way to slice by lane is `bpmn-figure(view: (lane: ..))`. The same two names were also in a hint that `bpmn-brief` prints for users over in the bpmn-generator repository, fixed there in its v0.5.1.

And `typst.toml` still had an em-dash in `description`, which put it in the package's own metadata.

## v0.16.3

**Documentation: normalised prose, a rebuilt changelog, and a roadmap that states the truth**

A documentation-only release that still bumps the version, because `template/pkg.typ` on the report's side pins this number.

**Writing conventions.** Two rules applied to all of `docs/` and the README. *One paragraph is one line*: every manual line break inside a paragraph removed, because breaking mid-paragraph makes `git diff` claim the whole paragraph changed when one word did, and it makes every scripted search-and-replace slip past strings cut across a line. *No em-dash*: 84 of them, replaced by meaning rather than mechanically, a semicolon when it joins two independent clauses, a colon when it opens an explanation, parentheses when a pair of them brackets an aside.

**Changelog.** This file was empty while the repository already had 37 tags. Runs of consecutive patches on one theme are merged into a single entry, because reading them one patch at a time loses the thread.

**Roadmap.** It still called Phase 1 the "current focus" when the exit criterion had been met at v0.6.0, and it said nothing about the nine components that now make up most of the package. There is now a status table at the top, Phase 1 closed with its four remaining open items, and a new section for the component family. The most telling thing from that section: **they had no test layer of their own**, `just check` covered only the BPMN path, so changing `bpstep` or `bpportfolio` was checked by looking at a PDF and remembering.

## v0.16.2

**The loop marker turns the way BPMN draws it**

BPMN draws the loop symbol **anticlockwise with the gap at the bottom**: the tail starts around half past five, the arc takes the long way round, and the head stops around seven. The old one ran clockwise with the gap at the top, which is that same picture flipped about the horizontal axis. The right shape, the wrong statement, and it reads as a "reload" icon rather than a loop.

Two changes, kept separate because they are independent. **Handedness**: measure `y` downwards instead of upwards; a reflection reverses handedness, so ↻ becomes ↺ without touching `sweep`. **Where the gap sits**: a `phase` inside `P` rolls the whole figure around the circle, `phase = 0` putting the tail at half past four and the head at six, and `-30deg` pushing both one hour further to match the specification. Every point has to see the same `phase`, including the radius the arrowhead's base opens along; miss that one and the head comes out skewed.

Alongside it, the centring is now measured from the actual ink rather than solved by hand. The old closed form `cy = (size - t/2 + hw) / 2` only holds while the gap sits on an axis, because it assumes the arrowhead is the extreme point on one side and the bare stroke is the other. With a `phase`, both assumptions are false.

## v0.16.1

**Message flow drop points from geometry, and space between two black boxes**

Two faults in black-box slicing, both inside `bpmn-slice`'s re-routing block.

**Message flows sat off centre unpredictably.** The offset was computed from the flow's index in the array, `(calc.rem(fi, 3) - 1) * 7`, which has nothing to do with geometry. Two thirds of the flows were pushed off centre without colliding with anything, and where a given flow landed changed whenever the set of flows changed. The black-box fix in v0.16.0 increased the number of flows, which is what made this obvious. Drop points are now grouped by `(coordinate, side)` and only groups with more than one member are spread, symmetrically about the shared coordinate, with a step of `min(14, extent / (n + 1))` so the whole cluster stays on the node's own edge. Measured across the six L3 models in the report: all 27 message flows return to centre, and no model has a genuine collision.

**Two black-box bands side by side fused into one block.** The bands were stacked exactly `blackbox-height` apart, so two partners on the same side printed as one grey block divided by a line, which reads as a single two-lane pool. They are now pitched by `blackbox-height + blackbox-gap`, and their order follows each participant's original position rather than the order they were met in the message-flow array.

The old test suite could not guard either of these: every slice in it produced a single band, and no model had two flows wanting the same spot, so the manifest did not move by one line after the fix. `tests/fixtures/two-blackboxes.bpmn` was added so that next time it does guard them.

## v0.16.0

**`bpmn-span` carries its context, and the contract is written down**

`bpmn-span` cuts along the sequence flow, but it kept only the nodes it could compute, so message flows, black-box partners, data objects, annotations and enclosing groups all fell away. The slice looked clean and read wrongly, because what it dropped was precisely the part saying who this stretch of the process exchanges with.

Two fixes. **Message flows anchored on a participant**: a participant with no `processRef` has message flows anchored on the participant itself rather than on any node inside it, and `pool-of` only mapped node ids, so the lookup missed and both the partner and the flow vanished. This was the last fragment of the black-box recognition added in v0.13.0. **A second pass**: after computing the node set from sequence flows, pick up the data objects and annotations joined to it by associations, and any group whose rectangle encloses the centre of a node that was kept.

The contract is now stated in the docstring: sequence flow decides the *boundary* of the span, and everything attached to what falls inside comes along. Renaming it to `bpmn-part` was considered and dropped: the fault was not in the name but in a contract that had never been spoken, and renaming would only have blurred the name by exactly as much as the contract was blurred.

Measured: slicing by pool across the six L3 models restored **10 black boxes and 27 message flows**, with the node count unchanged.

## v0.15.0

**`bpmn-sheet` takes `view:` and `turn: none`**

`view:` cuts *elements* before the sheet cuts *pages*, so a fold-out can spread a single pool rather than a whole collaboration. `turn: none` drops the rotation entirely, for paper that already runs the right way: on a 16:9 slide neither `"cw"` nor `"ccw"` helps, and a slide is exactly where a diagram most needs spreading out.

## v0.14.1

**`docs/curved-arrows.md`**

A record of how to build a curved arrow in pure Typst: sample the arc into a polyline with Δ ≤ 8°, derive the head's angular step from `Δ = 2·asin(L / 2r)`, stop the stroke exactly at the base angle, lay the base edge along the normal, round the corners with a same-coloured stroke and `join: "round"`, and centre by the ink rather than by the geometry.

Alongside it, `turnicon` drops its hand-typed `trim: 18deg` constant. It equalled the derived 17.81°, but only for *one* pair of `(r, head-len)`; change the radius and it goes silently wrong.

## v0.14.0

**`sheet-turn-icon`**

The "turn the page" glyph for a fold-out: a rectangle standing for an A4 sheet and two semicircular arcs showing which way to turn it. The paper's outline is thinner than the arrows so that the arrows are what the eye catches first, and the "A4" caption is printed only when there is room for it.

## v0.13.0

**Black boxes recognised at the parser, and the name repeated on every page of a fold-out**

Three items with one root: a participant that is not expanded is a black box, and a black box holds no nodes.

**The parser had never marked a black box.** All six L3 models drew an empty partner as a pool with a title band. Wrong as a statement, because a title band promises lanes and content the partner does not have, and unreadable, because a black box is about 60 units tall and the band eats half of that. The parser now reads the two signals the specification gives: no `processRef`, or `isExpanded="false"` on the DI shape.

**`bpmn-sheet` silently deleted black-box bands.** The row planner asked "does this row contain any node?", and that question is false for every black-box band by definition. Partners disappeared and the message flows to them ended in mid-air. The test became "contains a node **or** contains a black-box band"; six fold-outs went from 19 pages to 21.

**A black box's name repeated on every page.** The name sits at the centre of the box, so on a fold-out that centre falls on exactly one page and every other page gets an untitled grey band. The name is now lifted out of the shared drawing and re-centred on the part of the box each page can actually see.

## v0.12.0

**Stacking order, and groups drawn with a real dash-dot**

Typst has no z-index; drawing order *is* stacking order, so `draw-canvas` has to say so. Six layers, bottom to top: pools and lanes, sub-process frames, sequence flows, the main nodes, groups / annotations / data objects, then message flows and associations on top. Before that, message flows were hidden by a sub-process's fill and border.

Groups were wrong in three ways at once: drawn with `loosely-dashed` instead of dash-dot, stroked too heavily, with a corner radius of an absolute `6pt` so it did not scale, and ignoring the colour the author chose in `bioc:stroke`. The specification says dash-**dot**, bpmn-js writes `10,6,0,6`, and a zero-length dash only becomes a dot with `cap: "round"`.

## v0.11.2

**An expanded sub-process's name sits top-centre of its frame**

It was sitting centre-centre, which is to say in among the nodes inside it. BPMN puts it top-centre. Alongside that, a sub-process is no longer drawn heavier than the tasks inside it: the shape functions received already-multiplied lengths and then inferred the scale by dividing by 100, which is only right for a 100-unit task. A 350-wide sub-process got a border, a radius and symbols 3.5 times too large. The scale is now passed down through `unit:`, and the division survives only as a fallback for hand calls.

## v0.11.1

**`bp-text(.., scope:)`**

Lets the data layer call a component: a string in a YAML file can contain a function call, and `scope:` decides which functions it can see. Before this, the data layer could only write text.

## v0.11.0

**`noteplace` rule 6: leader lines are never diagonal**

The leader from a callout card to its element has to run either horizontally or vertically. A diagonal line reads as an edge of the diagram, which it is not.

## v0.10.1

**Per-axis growth, and a placement lock**

`compact` grew both axes by the same amount, so a wide, short diagram was grown out of proportion. Alongside that, `whywhy` takes `root-label` and a list-valued `root`, and the dashes in a layer's label now pass through `bp-text`.

## v0.10.0

**`compact(.., air: N)`**

A floor under the empty space: guarantee at least N units of empty band on each axis. `bpmn-notes` needs that room, because every callout card is confined to the inside of the diagram box. It is deliberately blunt: it grows *every* gap, including the ones no card will ever use. Two sharper approaches (reserve per anchor, and a comment gutter in the margin) are in [roadmap.md](roadmap.md).

Alongside that, the rule closing the box around a lane name was removed.

## v0.9.1

**`compact` no longer crushes empty pools and lanes**

The y axis compacted bands that were *supposed* to be empty, so a lane with no nodes was squeezed to near zero and the pool read as though a department were missing.

## v0.9.0

**`bpmn-sheet-info`, and `compact:` for fold-outs**

`bpmn-sheet-info` answers "how many pages will this model take" before building, so the page budget can be settled in advance. That is a different question from `bpmn-info`, which answers "at this width, how many points are the labels". One is about *legibility*, the other about *a page budget*.

## v0.8.0 to v0.8.4

**`bpmn-sheet`: spread a whole model across several pages**

A 3000-unit-wide model cannot fit one A4 page and stay readable. `bpmn-sheet` draws it **once** and then opens several windows onto that one drawing, so the pages join up at the same scale. Quite different from `bpmn-span`, which genuinely drops elements.

Four patches followed, and all four were about what gets turned:

- **v0.8.1** turn the diagram, not the sheet of paper. Turning the paper turns the page numbers and the running head with it.
- **v0.8.2** turn clockwise, so that turning the page joins the pieces up. Anticlockwise makes the next page join onto the *start* of the previous one.
- **v0.8.3** the repeated name band was missing a pad, and a parameter was renamed to match what it does.
- **v0.8.4** `repeat-header: false` cropped away the first page's own name band, so turning the repetition off also lost the original.

## v0.7.0 to v0.7.5

**`bpportfolio`, and `bptext`**

`bpportfolio` draws the process portfolio matrix: Importance × Health × Feasibility. The five patches after it were presentation: Health became a colour scale taken from the library's palette rather than fresh hex values (v0.7.1), the legend became a grid with right-aligned numbers (v0.7.3), the size legend became a column down the right margin (v0.7.4), and the default height was tightened (v0.7.5).

`bptext` (v0.7.2) sends a data-layer string through Typst's own parser, so `--` in a YAML file finally renders as an en-dash instead of two hyphens. Two traps found in real data are recorded in [design-system.md](design-system.md#external-strings): `#` opens a code expression, so `"store #1"` prints as "store 1" **with no error**, and bold is `*one star*` rather than `**two stars**`.

## v0.6.0 and v0.6.1

**Becoming a Typst package, and taking in the whole process-drawing family**

Before this the library was *vendored*: `components/` copied into the report's repository. That was cheap, but it mixed two histories into one `git log` and nothing pinned a version. Now it is a **Typst local package**: `just install-lib`, then `#import "@local/typst-bpmn:<ver>"`. Two separate histories, a version number in the import line, and a submitted document that rebuilds identically.

At the same time the repository took in the whole family of process-drawing components that had been scattered through the report's repository: `bpstep`, `bpmap`, `orgchart`, `bptable`, `whywhy`, `annotate`, `noteplace`. None of them is BPMN, but they are all in the same trade: read a data file, draw a process picture, depend on no external package.

v0.6.1 fixed the `/components/` paths left over after the rename to `src/`, and rewrote the documentation for the package model.

## v0.5.1 to v0.5.4

**Four geometry patches, all about the loop marker and events**

- **v0.5.1** intermediate and boundary events had lost their double ring, so they read as end events. Ring weight, inner radius and the white space between the two rings are **one system**: draw a double ring at a single ring's weight and the white space comes out at exactly zero.
- **v0.5.2** the timer clock is centred, and the loop marker is drawn on a real arc instead of a hand-fitted cubic.
- **v0.5.3** the arrowhead belongs *to* the arc rather than sitting apart from it: both base corners lie on the arc's own circle, so the head tilts with it and the arc's momentum carries through the head.
- **v0.5.4** the arrowhead is measured by length and height, not by angle. Typing an angle means the head silently grows when the radius changes.

## v0.5.0

**Phase 1 complete on this side**

`just vendor DEST` copied the components into a report's repository, with [integration.md](integration.md) alongside. And the vertical-pool fixture made a full round trip through Camunda, proving the two parsers agree on that axis too.

## v0.4.0

**Referenceable figures, and a regression harness**

`tests/golden.typ` records a *table of numbers* for the matrix of model × view × compact: element counts, the extent, and the label size that extent implies at a reference width. Deliberately **not** image goldens: a PNG depends on the fonts installed, so comparing images would break on somebody else's laptop for reasons unrelated to the code. The price is that a redrawn symbol changes no number at all; that is exactly what `tests/conformance.typ` is for.

Alongside it: a process with no pools builds, and figures can be referenced with `#ref()`. Referencing has to use the `label:` parameter rather than a trailing `<lbl>`, because the function returns a wrapper and a trailing label lands on the wrapper.

## v0.3.0

**Phase 0 closed**

The last two items of the shape vocabulary: **the three event-based gateway variants**, which BPMN distinguishes by `eventGatewayType` and `instantiate` rather than by element name; and **vertical pools**, with a fixture of their own, where the title band and the lane ordering turn with the pool's axis and a black box folds to the side it came from.

## v0.2.0

**The shape vocabulary completed**

Markers for loop, parallel and sequential multi-instance, compensation and ad-hoc; the call activity's thick border; the transaction's double border; collection data objects; data inputs and outputs; the conditional flow's diamond. Plus the Camunda palette with names by meaning (`happy`, `rework`, `external`, and so on) rather than by colour.

And the first two test layers: `tests/agreement.typ`, where the two parsers must produce identical model dictionaries, which is the only thing standing between a two-parser design and silent drift; and `tests/conformance.typ`, the symbol sheet at three scales, to be looked at beside Camunda Modeler.

## v0.1.0

**Phase 1 working end to end**

A `.bpmn` file exported by any modeler already contains **BPMNDI**: absolute bounds for every shape, waypoints for every edge, bounds for every label. So this is a *coordinate transform* problem, not a graph-layout problem. That one sentence decided the shape of the whole project.

The first release had: the BPMN shape vocabulary, a DI-faithful renderer, two ways in (XML read directly in Typst, and YAML through the converter), a grid layout as the fallback for models with no coordinates, `compact:` collapsing empty bands to buy back label size, `view:` slicing with black boxes, and the four `fit:` modes.
