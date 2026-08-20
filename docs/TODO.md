# TODO

Open work. Completed items move to [`changelogs.md`](changelogs.md) at the version that shipped them, and the direction of the project is in [`roadmap.md`](roadmap.md); this file is the short list of things that are wrong or missing right now.

Each item states what breaks, why, and the exact file to reproduce it on.

- [ ] #feat #high An `*-info()` for each component of the process-drawing family, returning counts and extents the way `bpmn-info` does. `tests/smoke.typ` can only assert "it built and the box is finite", because there is nothing to measure; a changed colour, a changed gap or a drifted alignment passes it silently. With `*-info()` the smoke layer becomes a golden layer for six components that currently have no structural guard at all. This is the highest-value item in the repository and it blocks anything built on top of those six.

- [ ] #bug #med A boundary event is not placed on its host's edge in the grid layout. `bpmn-grid.typ` positions every node from `row`/`col`, and a boundary event has no meaningful cell of its own: it belongs on the boundary of the activity it interrupts. On the DI path the modeler's coordinates are correct and this does not arise, so the defect is confined to hand-authored YAML. The fix is to resolve `attachedToRef` before the grid pass and place the event on the host's edge, nearest side to its outgoing flow.

- [ ] #bug #med The grid layout ignores a node's `lane:` key. `bpmn-grid.typ` splits a pool evenly between its lanes in declaration order and then places nodes by `row` within the pool, so `lane:` on a node has no effect and the picture can disagree with what the model says. Reproduce: add `lane:` to a node in `examples/leave-request.yaml` and watch nothing move. The fix is to resolve lane membership first and treat `row` as a position *within* the resolved lane.

- [ ] #feat #med Schema validation with useful messages, for hand-written YAML on both the BPMN path and the family path. A mistyped key is either ignored in silence or reaches a `panic` phrased in Typst's terms rather than the schema's. One shared validator serves both paths, and it is the difference between a typo costing ten seconds and costing an afternoon.

- [ ] #bug #low A message flow re-routed to a black box takes a straight line to the band, so one starting on the far side of the pool passes over the shapes in between. This is the single place where obstacle-aware routing earns its keep on the DI path, and it is narrow enough to solve on its own terms: route around the bounding boxes between the two endpoints, rather than building a layout engine. Reproduce: any slice of `samples/b04-btvn01.bpmn` where the partner sits opposite the sending node.

- [ ] #bug #low Labels in the grid layout are placed by rule rather than by measurement, so two long labels in the same neighbourhood can overlap. It affects the grid path only; DI labels carry their own bounds. `noteplace.typ` already solves the harder version of this problem for callouts, so the fix is more likely to be reuse than new code.

- [ ] #docs #low `docs/components.md` for the process-drawing family, in the spirit of `design-system.md`. Their conventions currently live in docstrings, which means they are read by whoever is already editing the file and by nobody else.
