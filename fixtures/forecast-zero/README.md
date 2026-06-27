# Fixture: layer3-budget-alloc-sum (historical name: forecast-zero)

This fixture originally tested that the reserved forecast layer (Layer 3) stayed zero.
The current implementation uses Layer 3 as `budget_alloc_sum`, a diagnostic/canonical-helper layer for envelope allocation totals.

The fixture now checks:

- Canonical Daily Cube keeps shape `Day × Account × 4 layers`.
- Layer 3 is populated when `budget_alloc.tsv` exists.
- Layer 3 can be used to derive cycle envelope allocation without confusing it with budget consumption.

Historical note:

- Older docs may refer to Layer 3 as `forecast`.
- Current formula docs (`docs/CANONICAL_FORMULAS.md`) treat Layer 3 as `budget_alloc_sum` for F010/F011.
- Future cleanup should either rename this fixture/tool or finish Layer 3 meaning consolidation documented in `docs/CUBE_EVOLUTION_POLICY.md`.
