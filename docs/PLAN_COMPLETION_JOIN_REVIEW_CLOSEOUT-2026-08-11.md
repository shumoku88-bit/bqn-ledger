# Plan Completion Join review closeout — 2026-08-11

## Baseline

Final reread is against merged `main` `56dfbb09c37188f4443bb500f655509638e351cd` after PR #629.

The review sequence was:

- PR #624: recorded the Plan Completion Join owner, consumer graph, relationship semantics, ordering obligations, and subtraction candidates;
- PR #625: fixed caller-owned Plan row order, matching Actual evidence order, and unmatched Actual order with a multi-Plan/multi-Actual law;
- PR #628: replaced the Plan-by-Plan Actual relation scan and candidate-row reprojection with one BQN-native Plan-coordinate classification and ragged Group kernel;
- PR #629: removed the undocumented public Actual snapshot coordinate and the unused private TransactionEvidence coordinate.

## Final semantic owner

`src/accounting/plan_completion_join.bqn` remains the pure relation owner between explicit Plan and Actual selections:

```text
Plan Facts + Actual Facts + explicit selections
→ validate source families and selection coordinates
→ selected Plan plan_id axis
→ selected Actual rows with nonempty plan_id
→ Plan coordinate per linked Actual with ⊐
→ matched Plan coordinates + unmatched bound
→ ragged Actual-index cells aligned to the Plan axis with ⊔
→ Plan evidence + matched Actual evidence cells
→ open / completed / duplicate / ambiguous
→ aligned semantic evidence + durable unmatched Actual references
```

Selection and period policy remain outside the Join. The owner does not read sources, choose a cycle, render a report, mutate canonical data, or infer relationships from date, memo, amount, Account coordinates, or source-local indices.

## KEEP

- explicit caller-owned Plan and Actual selections;
- nonempty durable `plan_id` as the only Plan↔Actual relationship key;
- caller-owned Plan row order;
- caller-owned Actual order within each matching Plan cell;
- caller-owned unmatched Actual order;
- classification before Actual completion validation, so an unmatched linked Actual publishes only a durable Transaction reference and is not eagerly strengthened into Join admission;
- source-local exact coefficient and scale evidence, with no summation across separate Actual completions;
- explicit `open`, `completed`, `duplicate`, and `ambiguous` relationship states;
- duplicate versus ambiguous distinction from semantic completion signatures;
- source-qualified durable Transaction and Posting provenance;
- per-completion currency and Account-direction comparison evidence;
- fail-closed publication for invalid source families, selection coordinates, Plan identity, or matched completion evidence;
- the documented rich Actual semantic evidence family;
- `plan_transaction_index` as a selected Plan-Facts coordinate used by current same-source consumers, not as cross-source identity.

## SUBTRACTED

- repeated `matchingMask` rescans of all linked Actual `plan_id` values once per selected Plan;
- the temporary `candidateRows` namespace append followed by full field-by-field reprojection into columnar output;
- public `rows.actual_transaction_indices`, because it was an undocumented snapshot-local coordinate with no retained consumer while durable `actual_references` already carry relationship identity;
- private `TransactionEvidence.transaction_index`, because the Join did not consume that field.

The successful relation is now visible directly as:

```text
Actual plan_id
→ selected Plan coordinate
→ matched / unmatched
→ Group by Plan coordinate
→ ragged completion evidence cells
→ aligned semantic result
```

## Ordering and unmatched boundary

PR #625 remains the law protecting the relation shape introduced by #628. It proves that changing the internal relation algorithm must not silently sort or canonicalize caller-owned selections.

The unmatched boundary is also retained deliberately. A selected Actual with a nonempty `plan_id` that is outside the selected Plan axis is reported as durable unmatched relationship evidence without running matched-completion `TransactionEvidence` admission on it. This preserves legitimate period or historical omission behavior.

## Reachability decision

Plan Completion Join is a live shared accounting capability. Current direct production consumers include:

- `src/sections/planned_payments.bqn`;
- `src/application/daily_scope_adapter.bqn`;
- `src/accounting/envelope_backing.bqn`.

Their different uses of relationship status, Plan evidence, completion comparison flags, and provenance justify retaining the Join as its own accounting owner rather than collapsing it into one Section or Application adapter.

## Deferred relation question

`TransactionEvidence` still finds one Transaction's Postings by comparing its Transaction index against the complete Posting axis. Canonical Facts currently expose `postings.transaction_index` but do not expose a transaction-to-posting offset/count relation.

That repeated Transaction→Posting scan is a distinct relation/data-model question from Plan→Actual completion matching. It is therefore **deferred** to the later Facts / validation-kernel / cross-cutting review where the consumer graph and data-model consequences can be evaluated coherently.

Do not reopen the completed Plan↔Actual relation or introduce a generic helper solely to remove that scan locally.

## Final classification

The Plan Completion Join review is complete on `main` `56dfbb09c37188f4443bb500f655509638e351cd`.

No further Plan Completion-specific subtraction is currently justified. The next normal Phase 1 cursor is:

`src/accounting/plan_temporal_status.bqn`
