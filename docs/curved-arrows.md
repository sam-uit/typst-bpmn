# Curved arrows

Two of these exist so far: the loop marker (`marker-loop`, `src/bpmn-shapes.typ`) and the turn-the-page icon (`sheet-turn-icon`, `src/turnicon.typ`). The first one took three revisions to stop looking wrong. This is the method that came out of that, written down so the third one does not rediscover it.

The short version: **a curved arrow is an arc plus a head, and almost all the difficulty is in where the arc stops and how the head meets it.** Drawing the arc is easy.

## What Typst gives you

`curve` with `curve.move` / `curve.line` / `curve.quad` / `curve.cubic` / `curve.close`, plus `stroke` and `fill`. **There is no arc primitive.** So a circular arc is either

- **sampled** as a polyline of `n` chords, or
- **approximated** with cubics, for a sweep Δ, control points at distance `k·r` along the tangents with `k = 4/3 · tan(Δ/4)` (0.5523 for a quarter).

Sampling has won both times, for a reason worth stating: the sample points are *values you can read back*, so the same `P(θ)` that draws the arc also gives you the tip, the base and the normal for the head. With cubics the head has to be computed separately and the two can drift apart. Reach for cubics only when the path is a genuine fill that must be exact, or when you need to offset the outline.

### How many samples

The gap between a chord and its arc is `r·(1 − cos(Δ/2)) ≈ r·Δ²/8`. Keep the per-segment sweep **Δ ≤ 8°** and the error is under 0.1% of `r`, below both the eye and the printer.

| | sweep | n | Δ | error |
| --- | --- | --- | --- | --- |
| `marker-loop` | 315° | 60 | 5.3° | 0.001 r |
| `sheet-turn-icon` | ~92° | 14 | 6.6° | 0.002 r |

Sampling more is close to free; these numbers are already generous.

## Fix the direction convention once, in the point function

Typst's **y grows downward**, so the textbook parametrisation turns the opposite way from what you see on the page. Decide the convention in `P(θ)` and never think about it again. Do **not** sprinkle sign flips at the call sites; that is how an arrow ends up pointing the wrong way in one of four places.

The two files use different conventions, and both are fine because each says so in one place:

```typ
// turnicon.typ, maths convention with y flipped: θ increases counter-clockwise on the page
#let _ring(cx, cy, r, a) = (cx + r * calc.cos(a), cy - r * calc.sin(a))

// bpmn-shapes.typ, marker-loop: 0° at six o'clock, θ increases anticlockwise
let P(a) = (r * calc.sin(a + phase), r * calc.cos(a + phase))
```

Pick whichever makes the *shape's own* description read naturally. `marker-loop` sweeps "round from the gap at the bottom", so the bottom is 0°.

### Turning it round

`marker-loop` first ran **clockwise with the gap at the top**, which is the same figure BPMN draws mirrored about the horizontal axis. Two things fix that, and it is worth separating them because they are independent:

- **Handedness.** Measure y *downwards* from the centre instead of upwards. Mirroring reverses handedness, so ↻ becomes ↺ with the sweep untouched, no reversed loop, no negated angle, no second convention to keep in your head.
- **Where the gap sits.** Mirroring alone leaves the gap on the axis it was already on. A `phase` added inside `P` rolls the finished figure round the circle: at `phase = 0` the tail is at half past four and the head at six o'clock, and `−30°` moves both on by an hour, to the 5:30 and 7:00 the spec asks for.

Every point has to see the same `phase`: the arc samples, the tip, **and the radial the head's base opens along**. Miss the radial and the head shears, which at 6 units of icon reads as "the arrow looks a bit off" rather than as an obvious bug.

## The head is the hard part

`marker-loop` went through three revisions, and each one fixed a defect that is easy to reproduce:

1. **Head at fixed unit coordinates.** Two hand-fitted cubics with a wedge parked beside them. The head was not on the curve at all, and the whole mark sat off-centre.
2. **Head built on the tangent at the tip.** Geometrically correct, still wrong to look at. A straight head leaving a curve reads as *flying off the path*, and the head's square base met the curving stroke at an angle, leaving a notch.
3. **Head anchored on the circle.** Both base corners sit on the arc's own circle, so the head leans with the turn and the arc's momentum carries through the tip. The base edge runs **along the radius**, which is by construction perpendicular to the tangent exactly where the stroke ends; the two meet square and the notch is gone.

### The recipe

In the order you would draw it by hand:

1. Run the arc to the tip angle `a_tip`. **`P(a_tip)` is the tip.**
2. Step back **along the curve** by the head's length to get the base angle. For a circle, a chord of length `L` subtends `Δ = 2·asin(L / 2r)`, so `a_base = a_tip ∓ Δ`.
3. The base edge lies along the **normal** at `a_base` (for a circle that is the radial direction `(sin a_base, −cos a_base)`), extended `± head-half` either side.
4. **Stop the stroke at `a_base`, not at `a_tip`.** This is why the head is a separate `curve` and why the arc's end angle is the base angle.

```typ
let base-a = 360deg - 2 * calc.asin(head-len / (2 * r))
let bc = P(base-a)
let (rx, ry) = (calc.sin(base-a), -calc.cos(base-a))   // outward radial

// arc: a0 .. base-a          (stops short by exactly the head's length)
// head: P(360deg) -> bc + hw*(rx, ry) -> bc - hw*(rx, ry) -> close
```

### Two knobs, both lengths: never an angle

`head-len` and `head-half` are fractions of the box. The angular step is **derived**, not typed. Type the angle and retuning `r` silently resizes the head: same 18°, different arc length. This is worth insisting on even when the typed number happens to be right, `sheet-turn-icon` carried a literal `trim: 18deg` for exactly one commit, and the derived value turns out to be 17.81°, which is to say the literal was the derived value rounded, frozen at one particular `r`.

### When the cheap version is enough

`sheet-turn-icon` uses the simpler **tangent-at-tip** head plus an angular trim, not the on-circle construction. That is a deliberate trade, not an oversight: it is a 1.6em icon whose heads sit far from any other ink, so the notch is sub-pixel and the "flying off" reading never arises at two arcs of 92°.

The rule: **tangent head for an icon, on-circle head for a symbol**: anything drawn beside other symbols at the same weight, where the eye compares them.

## Stroke details that matter more than they should

- **`cap: "round"` on the arc.** This family is drawn round everywhere; one square end reads wrong without anyone being able to say why.
- **Rounding the head's corners.** `curve` has no corner radius. Stroke the filled head with `join: "round"` **in the fill colour**: the stroke thickness becomes roughly twice the corner radius. `marker-loop` uses `0.03 × size`.
- **A dot is a zero-length dash under a round cap.** Same family of trick: use the cap to make geometry the API cannot express. The group's dash-dot border is `dash: (array: (10, 6, 0, 6))` with `cap: "round"`, with a butt cap the dot vanishes entirely. See [design-system.md](design-system.md#stroke-weights).

## Scale: take it as a parameter

Never recover the scale by dividing a pre-scaled width by a nominal size. `shape-task` did (`1.6pt * (w / 100pt)`, assuming a 100-unit activity) and an expanded sub-process at 350 units wide got a border, a corner radius and markers all 3.5× too big. Renderers now pass `unit:` down; the division survives only as a fallback for a hand call.

Inside a self-contained icon the equivalent discipline is: express every dimension as a fraction of one `size` and multiply exactly once, at the point of placement.

## Centre on the ink, not on the construction

A curved arrow with a head is **asymmetric**: the head reaches past the circle by `head-half`, the stroke past it by `t/2`. Centring on the circle puts the mark visibly high or low. `marker-loop` used to solve that by hand:

```typ
// (cy − r − hw) + (cy + r + t/2) = size
let cy = (size - t / 2 + hw) / 2
```

That closed form is only right while the gap sits on an axis, because it assumes the head is the extreme point in one direction and the bare stroke in the other. The moment a `phase` rolls the gap off the axis, both assumptions fail and the icon sits quietly off-centre. So build the figure **around the origin**, measure it, then translate:

```typ
let spread(ps, pad, i) = ps.map(p => p.at(i) - pad) + ps.map(p => p.at(i) + pad)
let axis(i) = {
  let vs = spread(arc, t / 2, i) + spread(head, round / 2, i)
  0.5 * size - (calc.min(..vs) + calc.max(..vs)) / 2
}
```

Two padding values, not one: the arc grows by half its stroke, the solid head only by half its round join. The conformance sheet's crosshair page is what catches this, the ink has to straddle the cross, and a hand-fitted centre that has drifted shows up there before it shows up anywhere else.

## Do not reach for the glyph

`↻` was tried and rejected. It comes out far lighter than the neighbouring markers (this family is drawn at 0.09–0.13 × size), and it makes a BPMN symbol depend on whichever font the host document happens to set. The same symbol has to look the same in every report.

## Why there is no shared helper yet

Two call sites, two genuinely different heads (on-circle vs tangent) and two different angle conventions. Factoring that into one function today would mean a parameter for each disagreement, which is a worse thing to read than either call site. **Extract on the third**, and extract the *recipe*, `P(θ)`, sampled arc, derived base angle, head on the normal, not the two current shapes.

## Checklist for the next one

1. Write `P(θ)`; state the direction convention in its comment.
2. Sample with Δ ≤ 8°.
3. Derive the head's angular step from its length: `Δ = 2·asin(L / 2r)`.
4. End the stroke at the base angle, not the tip.
5. Build the base edge along the **normal at the base**, not perpendicular to the tangent at the tip.
6. Round the head's corners with a same-colour round join.
7. Centre on the inked extent.
8. Take the scale as a parameter.
