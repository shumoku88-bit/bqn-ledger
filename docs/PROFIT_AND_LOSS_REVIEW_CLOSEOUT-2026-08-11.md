# Profit and Loss review closeout — 2026-08-11

## Baseline

Final production reread is against `main` `07168702a4427e6d6b98ae3a3a26dc83fd78ebe4` after PR #635.

The review sequence was:

- PR #634: recorded owner, consumer graph, array-visibility, public-shape questions, and exact-boundary hypotheses;
- PR #635: added law-only qualification for dense zero statement rows and the three role/net exact-sum failure boundaries;
- this closeout corrects the intermediate numeric illustration in #634 to the actual normalized construction proved by #635.

No production code changed during the Profit and Loss review.

## Final semantic owner

`src/accounting/profit_and_loss.bqn` remains the pure Actual statement projection over one caller-selected currency domain and half-open ordinal period:

```text
Actual Facts + domain + period
→ Account Period dense Account axis
→ Account role selection
→ statement sign normalization
→ checked Income / Expense totals
→ checked net income
→ statement rows + durable Posting contributors
```

The owner does not choose a cycle, observation date, source path, current currency, report route, or renderer.

## KEEP

### Upstream Account Period ownership

`account_period.bqn` already owns Posting selection, normalization, Posting→Account grouping, canonical Account order, Account movement, and Account-level evidence. Profit and Loss does not duplicate that relation.

### Direct role masks

Income and Expense membership remains visible as two direct masks over the dense Account axis. Another Group/Pivot layer would add machinery without removing repeated evidence scans.

### Dense zero Account rows

Every admitted Income and Expense Account remains in canonical Account order even with no selected-period movement.

PR #635 proves exact zero amount and empty contributor cells for those rows.

### Statement sign semantics

Income continues to negate canonical signed movement; Expense keeps canonical signed movement. Abnormal Income debit and Expense credit remain visible as negative statement amounts rather than being reclassified.

### Three checked exact boundaries

Keep:

```text
income_sum_failed
expense_sum_failed
net_income_sum_failed
```

PR #635 proves each is reachable after the same Facts/period has already passed `account_period.Build`.

The executable construction uses individually normalizable 15-digit chunks to reach `2^53 - 1`, places a non-statement bridge `1`, and then a statement value `2`. The complete Account-side sequence remains exact while the role subset omits the bridge and attempts the non-exact `2^53 + 1` result.

The net law separately proves that individually exact Income and Expense totals can still produce a non-exact final statement combination.

These checks are therefore operation-local safety laws, not defensive duplication.

### Direct Rows publication

`Rows` directly publishes selected Account coordinates, statement amounts, and durable Posting evidence. There is no candidate-row append and later field reprojection to subtract.

### Durable provenance

Statement rows continue to publish source-qualified Posting references from Account Period contributor cells.

## DEFER

### `account_index` public coordinate

`account_index` appears unused by current Profit and Loss consumers, but the reviewed Balance Sheet accounting owner exposes the same `account_index + account_key` row family.

Do not remove it from one statement owner in isolation. Revisit as a coherent cross-statement public-surface question.

### Section empty/success row-shape asymmetry

Profit and Loss and Balance Sheet sections both have an empty-row declaration that differs from their successful forwarded accounting row shape around `account_index`.

This is a Phase 3 Section/publication-shape concern, not a reason to alter the accounting kernel during Phase 1.

## Why no production refactor landed

The review actively tested several subtraction hypotheses rather than treating the current code as presumptively correct.

- Additional Group/Pivot structure did not clarify the already-dense Account relation.
- `Rows` was not row-append plumbing.
- The three local exact guards initially looked potentially redundant, but executable counterexamples proved they are necessary.
- Snapshot-local `account_index` deserves a wider sibling-statement decision rather than local removal.

The correct outcome is therefore a **qualified KEEP**, not “nothing found”. The value of the review is that retained complexity now has explicit evidence.

## Qualification

The final law set includes:

- ordinary Profit and Loss amounts, period slicing, abnormal signs, provenance, and domain rejection in `tests/test_accounting_profit_and_loss.bqn`;
- dense zero statement rows in `tests/test_accounting_profit_and_loss_boundaries.bqn`;
- `expense_sum_failed` after successful Account Period;
- `income_sum_failed` after successful Account Period;
- `net_income_sum_failed` with individually exact statement totals;
- section publication behavior in `tests/test_section_profit_and_loss.bqn`.

PR #635 head `983bb71d6e3234ade92c2bdba430db28758c20a9` passed full `tools/check.sh` and Coverage. The production owner was reread unchanged after merge on `main` `07168702a4427e6d6b98ae3a3a26dc83fd78ebe4`.

## Final classification

The Profit and Loss accounting review is complete.

No Profit and Loss-specific production subtraction is justified by current evidence.

The next normal Phase 1 cursor is:

`src/accounting/recent_transactions.bqn`
