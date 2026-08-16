# Cross-cutting experiment reachability audit — 2026-08-17

## Scope

This audit follows completion of the Phase 1–7 production BQN owner review.

It asks a different question from the earlier BQN-native pass:

```text
Is an experiment still useful evidence,
or has its question already moved into a current production owner?
```

Experiments are not production dependencies. The concern here is repository authority and attention: an executable historical candidate can look like a second implementation even after production has already absorbed the useful idea.

## Decision classes

Three classes are useful:

```text
promoted
  the experiment's useful idea is now owned and tested in production;
  retire the executable experiment and dedicated CI

negative evidence
  the experiment explains why a plausible alternative was rejected;
  retain while that conclusion still matches production

open experiment
  the question is still unresolved and the probe remains useful;
  retain as explicitly non-production evidence
```

No experiment is retained merely because a test or workflow can still execute it.

## Action catalog experiment — promoted, retired

Retired:

```text
experiments/bqn/add_ui_action_catalog.bqn
experiments/bqn/add_ui_action_catalog.md
.github/workflows/bqn-action-catalog-experiment.yml
```

The probe asked whether repeated shell action declarations could be expressed as one aligned BQN action relation and exported to thin clients without moving terminal interaction into BQN.

Current production now has that semantic boundary in `src/application/household_surface.bqn`:

```text
HouseholdSurface.Actions
  -> domain
  -> operation
  -> scope
  -> action_key
  -> label
  -> kind
```

`src/application/household_surface_cli.bqn` publishes that production relation for frontend consumption.

The original experiment remains historically useful because it exposed the aligned-catalog idea and the boundary between action metadata and effectful interaction. It no longer needs an executable duplicate catalog or a dedicated GitHub Actions workflow after production owns the relation.

Git history remains the complete experimental record.

## Sparse classify-once experiments — promoted, retired

Retired:

```text
experiments/bqn/sparse_group_classify_once.bqn
experiments/bqn/sparse_group_classify_once.md
experiments/bqn/sparse_group_classify_once_candidate.bqn
experiments/bqn/sparse_group_classify_once_envelope.bqn
experiments/bqn/sparse_group_classify_once_envelope.md
experiments/bqn/sparse_group_candidate_portfolio.md
experiments/bqn/run_sparse_group_candidate_portfolio.sh
```

These probes compared the earlier row × column rescan with one admitted item-to-cell classification followed by BQN Group.

The experiment sequence established:

- row-major occupied coordinate publication;
- occupied exact-zero preservation;
- contributor order;
- exact reduction through `scale.Sum`;
- ordered diagnostics and fail-closed publication;
- compatibility with the focused production sparse-group portfolio.

The final experiment explicitly concluded that a finite production slice was reasonable to propose.

That proposal was subsequently adopted in production by PR #487 (`refactor(accounting): classify daily grouping once`) and later reviewed again in the accounting review line, including PR #641.

Current `src/accounting/sparse_group.bqn` owns the classify-once shape through its private admitted grouping kernel. Keeping an executable candidate beside it would therefore preserve an older duplicate implementation rather than an independent current question.

The runner that rewrote the production test import to point at the candidate is retired for the same reason: current production tests now exercise the production implementation directly.

## Matrix Cells/Rank experiment — negative evidence, retained

Retained:

```text
experiments/bqn/matrix_result_cells_rank.bqn
experiments/bqn/matrix_result_cells_rank.md
```

This experiment reached the opposite conclusion. It tested a Cells/Rank rewrite of the small fixed-field result assembly and found that behavior could be preserved but readability and maintenance became worse.

Current `src/accounting/matrix_result.bqn` still uses the simpler Each-based form. The experiment therefore continues to answer a live architectural question:

```text
Why is this small result assembly not expressed through Cells/Rank?
```

That is useful negative evidence rather than a competing runtime candidate.

## Repository result

After this audit, `experiments/bqn/` contains only:

```text
README.md
matrix_result_cells_rank.bqn
matrix_result_cells_rank.md
```

There is no remaining dedicated action-catalog experiment workflow.

The directory README now states the retention rule explicitly: promoted executable candidates should be retired once production owns their laws; negative evidence may remain when it still explains the current implementation.

## Next cross-cutting cursor

The next observation is UI/documentation reachability:

```text
tui/README.md
active tools/bl -> tools/add-ui.sh path
Calendar-first Household surface documentation
older Command Hub/Home/TUI descriptions
```

The goal is not to remove a live frontend adapter because its name is old. It is to separate current thin adapters from stale architectural descriptions and then inspect where shell still duplicates action/selection knowledge already owned by `HouseholdSurface.Actions`.
