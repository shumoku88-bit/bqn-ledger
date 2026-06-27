# src-next-envelope-computation

Fixture-only Stage 4a prototype for `src_next/envelope_computation.bqn`.

Policy helper target:

```text
target_id: fixture_food_like
label: 食費
selector: budget=食費
```

`食費` is fixture policy data, not an engine concept.

Expected computation:

```text
allocated = 1000
actual_spent = 300 + 50 = 350
remaining = allocated - actual_spent = 650
status = computed
```

The fixture also contains:

- a plan row for `expenses:食費` amount `200`; this must not be subtracted from `remaining`.
- an actual expense account with missing `budget=` metadata; it must not be silently included in the target.
- another budget allocation (`日用品`) that must not be included in the target allocation.

No production data or source TSV format is changed by this fixture.
