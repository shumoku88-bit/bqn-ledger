# BQN experiments

This directory is the repository's analysis-only playground for BQN formulations that are worth understanding before any production decision.

Experiments here may be playful, comparative, incomplete, or intentionally simplified. They are not production owners, compatibility layers, or hidden alternate runtimes.

## Suitable experiments

- direct primitive versus explicit staged implementation;
- Each versus Cells versus Rank;
- nested rows versus rectangular arrays;
- sparse Group/Pivot versus Table-generated coordinates;
- Shift over competing temporal axes;
- Transpose of values together with coordinate and contributor metadata;
- toy Under or Undo examples over canonical in-memory values;
- named stages versus tacit modifiers;
- a new report or diagnostic view revealed by an array representation.

## Probe record

Tiny experiments do not need to fill every field. Use only the fields that help preserve the discovery.

A useful larger probe may state:

```text
Question:
Current owner or analogous runtime code:
Production contracts intentionally preserved:
Production contracts intentionally relaxed:
Representations or expressions compared:
Observed cells / frame / rank / shape / fill:
Ordering and contributor observations:
Result:
Possible destination: production / personal book / catalog / parked
```

A `.bqn` probe may be accompanied by a short Markdown note when the observed shapes or conclusions are not obvious from the code.

When a result should remain visible across future work, add or revise its card in `docs/BQN_EXPLORATION_CATALOG.md`.

## Boundaries

- Use synthetic data or public fixtures only. Never copy private household values here.
- Do not make production code import this directory.
- Do not add a probe to the canonical check suite merely to make it permanent. Promote it separately when it becomes focused production evidence.
- Do not assume that a prettier probe preserves diagnostics, exactness, identity, provenance, contributor order, source order, output bytes, or editor reconstruction.
- Do not turn an experiment into production without a separately selected finite slice and the `docs/BQN_REFACTORING_REVIEW_GUIDE.md` gate.

Failed and rejected formulations can be valuable results. Record the assumption they exposed instead of polishing them into false success.