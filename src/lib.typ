// typst-bpmn — public API.
//
//   #import "@local/typst-bpmn:0.6.0": *
//
// One import gives you every drawing component. The modules below are also
// importable individually if you want a narrow surface:
//
//   #import "@local/typst-bpmn:0.6.0/src/bpmn.typ": bpmn-figure
//
// ---------------------------------------------------------------------------
// What lives here, and why these things and not others
//
// This package owns everything that *draws a process*. That is a wider remit
// than the name suggests, and deliberately so: the BPMN renderer and the
// chevron/map/org-chart family share a design system (stroke weights, palettes,
// label sizing, the note-placement engine), and splitting them would mean
// keeping two copies of that system in step by hand.
//
// It does **not** own the authoring side. Turning a coordinate-free
// `*-brief.yaml` into a `.bpmn` — layout, well-formedness rules, id conventions
// — is `bpmn-generator`, a Python package. The split is by direction of travel:
//
//   brief.yaml ──► .bpmn        bpmn-generator   (authoring)
//   .bpmn ──► .yaml ──► figure  typst-bpmn       (rendering)
//
// `tools/bpmn2yaml.py` sits on this side of that line even though it is Python:
// it defines the YAML dialect `bpmn.typ` reads, and the agreement test needs it
// to prove the two parsers still say the same thing.
// ---------------------------------------------------------------------------

// --- BPMN 2.0: read a model, slice it, draw it -----------------------------
// `bpmn-figure` is the one to reach for. It takes `yaml(..)` or `xml(..)` —
// two parsers, one model dictionary, kept in step by tests/agreement.typ.
#import "bpmn.typ": *
#import "bpmn-render.typ": default-theme, grayscale-theme
#import "bpmn-palette.typ": *

// --- BPMN: analysis overlays and vertical slices ---------------------------
// `bpmn-notes` places comment cards on a diagram; `bpmn-span` cuts a model from
// one element id to another. Both compose with `view:` and `compact:`.
#import "bpmn-note.typ": bpmn-notes
#import "bpmn-span.typ": bpmn-span, bpmn-span-ids, bpmn-span-model

// --- Step flows, process maps, org charts ----------------------------------
// Levels 1–2 of APQC PCF, where a process is still a chain rather than a graph.
// Coordinate-free: content lives in YAML, `grid` decides the geometry.
#import "bpstep.typ": *
#import "bpmap.typ": *
#import "orgchart.typ": *
#import "bptable.typ": *

// --- Overlays and analysis -------------------------------------------------
// `annotate` is the grid-diagram counterpart of `bpmn-notes`: same placement
// rules, different way of learning where the shapes ended up (see noteplace).
#import "annotate.typ": annotate
#import "noteplace.typ": *

// `whywhy` reads a 5 Whys chain from one data file and renders it two ways —
// as a list in the prose, and as the `notes:` array for a diagram — so the
// chain never exists as two hand-written copies.
#import "whywhy.typ": *
