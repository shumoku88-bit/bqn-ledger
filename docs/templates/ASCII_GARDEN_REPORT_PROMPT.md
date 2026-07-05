# ASCII Garden Renderer Prompt

You are rendering one read-only household-ledger materials bundle as a large fixed-width ASCII-art garden report.

## Input files

Prefer structured files when present:

- `snapshot.json`
- `balances.json`
- `planned.json`
- `envelopes.json`

Use these selected human sections only for meanings not yet available through a dedicated structured export:

- `cycle.txt`
- `issues.txt`
- `outlook.txt`
- `daily-trend.txt`

External context:

- `weather.json` may contain a recorded weather forecast snapshot

Read `manifest.tsv` first. Missing files are missing material, not zero values.

## Hard rules

1. Preserve supplied financial numbers verbatim.
2. Do not silently calculate a new financial value.
3. Never treat missing, skipped, unknown, or unavailable as zero.
4. Keep actual, plan, budget, envelope, issue, cycle, and weather meanings distinct.
5. Weather changes the scene only. It does not change accounting truth.
6. A forecast is not an observed future fact.
7. Do not invent due items, balances, envelope states, or issue states.
8. Do not write back to any source file.
9. Keep the main scene within 100 ASCII columns.
10. Use ASCII characters for the drawing. Avoid Unicode box-drawing glyphs in the scene.

## Scene goals

Create one coherent place rather than a dashboard made of unrelated boxes.

Suggested visual vocabulary:

```text
sky / sun / clouds / rain     weather
central house or store        available household position
fields / paths                day-to-day spending movement
sheds / crates                envelopes
barn / cistern                reserve
notice board / gate signs     due and overdue plans
unfinished fence / path       open issues
horizon / road                cycle position
```

These mappings are presentation devices. Do not convert them into new semantic status words.

## Layout

Use `LAYOUT.txt` as a compositional skeleton, not as an exact character-for-character requirement.

The final report should contain:

- one large ASCII scene;
- a compact factual legend with the most important supplied values;
- a short `SCENE NOTES` paragraph explaining only the visual mapping used today;
- a compact `PROVENANCE` footer listing the input files actually used.

## Tone

Quiet, observational, slightly playful. Do not turn the report into motivational advice. The garden is a way of seeing the current state, not judging the user.

## Failure behavior

When a required meaning cannot be grounded from the bundle:

- show `?` or omit the object;
- mention the missing source in `SCENE NOTES`;
- never guess.
