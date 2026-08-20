# Conventions

Rules this repository follows. They are rules rather than preferences: if something here reads as merely stylistic, the reason it is a rule is written next to it.

## Language

**English only.** Documentation, code comments, docstrings, strings printed to the user, `panic` messages, commit messages, changelog entries, `just` recipe descriptions. All of it.

Commit messages are included in that list and are the easiest part of it to forget, because a commit message is not in any file you reopen later. It is documentation that outlives the diff it describes, so it follows the same rule the documentation does.

This rule was adopted on 2026-08-20. The repository grew out of a Vietnamese-language report project, so a large amount of Vietnamese prose is still in `src/` and `docs/`. That backlog is scheduled for one planned translation pass and is deliberately **not** fixed piecemeal while doing other work, because a half-translated file is harder to read than a consistently Vietnamese one. Anything **newly written** is English from the start.

## Naming and description

**Be as descriptive as the name will allow**, in prose and in code. A name that says what the thing does saves a line of comment; a vague name is not rescued by three lines of comment. This applies to functions, parameters, variables, files, `just` recipes, and section headings.

The library's own naming already carries meaning and new names should keep it consistent:

| Prefix | Means |
| --- | --- |
| `bpmn-*` | operates on a BPMN model dictionary |
| `bp-*` | a shared helper across the process-drawing family |
| `bpf-*` | internal to `bpportfolio` |
| `oc-*` | internal to `orgchart` |
| `ww-*` | internal to `whywhy` |
| `*-data` | build from an already-loaded dictionary |
| `*-file` | load a path and build, in one call |
| `*-figure` | wrap in a `figure` with caption and label |
| `*-info` | measure and return numbers, draw nothing |

## Punctuation

**No em-dash.** Replace it by meaning, not mechanically: a semicolon when it joins two independent clauses, a colon when it opens an explanation or attaches a label, parentheses when a pair of them brackets an aside. Replacing every one with a comma produces comma splices and four-comma sentences where the main clause is no longer findable.

En-dash in a numeric range is fine: "0.09–0.13 × size".

## Markdown source

**One paragraph is one line.** No manual wrapping at 80 or 100 columns. Wrapping makes `git diff` claim a whole paragraph changed when one word did, and it makes every search-and-replace slip past strings that happen to straddle a line break.

Code comments still wrap to the file's own width (about 90 columns); the diff problem does not apply there.

## Changelog

**Every change is logged in [`docs/changelogs.md`](docs/changelogs.md)**, not only the large ones. One entry per tagged version, newest first.

Entries explain rather than list: what changed, why it was needed, and what was considered and dropped. `git log` already does the listing. A version number is a minor bump for a new component or capability, a patch bump for a fix or an extension to something that exists.

## Dependencies must be stated

Every dependency is either synchronised automatically or described explicitly at the point that needs it: which version, where it comes from, and what breaks when it drifts.

This repository has one external dependency and one downstream consumer:

- **`bpmn2yaml` comes from [bpmn-generator](https://github.com/sam-uit/bpmn-generator)** and is needed by `just convert`, `just check`, `just demo` and `just lint`. Locally it defaults to a sibling checkout driven through `uv run --project ../bpmn-generator`; override with `PYTHON=...`. CI installs it from GitHub **pinned to a tag**, because a change to the converter can move the golden manifest and that has to be a decision rather than a red build nobody caused. The tag is written in `.github/workflows/check.yml` and nowhere else, so there is no second copy to disagree with it; raising it means checking first that the converter's new output changes no key this library reads, and pushing the generator's tag before the commit that raises the pin.
- **The version number must agree in three places**: `typst.toml`, the `#import` line in `README.md` and `docs/integration.md`, and `template/pkg.typ` in the consuming document. `just version-check` guards the first two and is a prerequisite of both `just check` and `just install-lib`, so a release whose own documentation states the wrong number cannot be installed.

## Before committing

```bash
just check     # convert --strict, parsers agree, golden manifest, version, smoke
just lint      # every file in src/, plus demo.typ and tests/
```

`just conformance` as well whenever a symbol's geometry changed, and then **look at the PDF**. The golden manifest is font-independent numbers; it cannot see a redrawn icon. That is what the conformance sheet is for, and it is the one layer a machine cannot run for you.

Commits are atomic: one logical change each, with a body that explains **why**, including the alternatives that were considered and dropped.
