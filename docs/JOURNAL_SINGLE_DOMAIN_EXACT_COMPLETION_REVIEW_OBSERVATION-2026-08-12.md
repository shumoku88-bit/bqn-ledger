# Single-domain Journal exact completion review observation — 2026-08-12

## Scope

This review covers the exact-completion half of `src/ledger/journal_single_domain_admission.bqn` after PR #674 exposed the source/Posting relation.

The reviewed functions are:

- `Normalize`;
- `CompleteElided`;
- `BalanceDiagnostics`.

Structural JPY adaptation, structural transaction admission, and final structural/semantic Transaction joining remain outside this change.

## Characterization findings

Characterization was deliberately performed through final Transactions and public diagnostics rather than through the private normalization carrier removed from publication in PR #674.

The focused laws protect:

- different canonical source scales normalizing to one exact transaction calculation scale;
- original source coefficients and canonical source scales remaining evidence;
- one elided Posting being inferred as the exact opposite of explicit evidence;
- inferred Posting source amount text remaining empty;
- multiple elisions producing `posting_elided_multiple` at the transaction start;
- an elided-only transaction producing `posting_elided_uninferable` at the elided source row;
- explicit evidence already summing to zero producing `posting_elided_zero` at the elided source row;
- normalized imbalance producing `event_unbalanced` at the transaction start;
- all error cases publishing no partial Transaction.

## Characterization corrections

Two failed runs were useful boundary evidence but are not production failures.

### CI #2733

The first test used `Prefix` as a noun binding. BQN capitalization gives that name a function role, so the test failed before semantic execution with a role mismatch. The fixture was renamed `prefixLines`.

### CI #2734

The first mixed-scale witness assumed source text `1.20` retained scale 2. That contradicted the already-reviewed `exact_decimal` contract, which trims trailing fractional zeros before constructing its canonical coefficient/scale carrier.

The witness was corrected to values with genuinely different canonical scales:

```text
-1.23  -> -123 @ scale 2
+1.2   ->   12 @ scale 1
+0.03  ->    3 @ scale 2
```

At calculation scale 2 they normalize to:

```text
-123, +120, +3
```

and balance exactly.

CI #2735 was SUCCESS with the corrected characterization before production changed.

## Normalize

The previous empty-safe scale reduction used mutable initialization plus a guard:

```text
calculationScale = 0
if postings exist:
  calculationScale = max source scales
```

The retained relation is now the reduction itself with its explicit identity:

```bqn
calculationScale ← ⌈´ 0 ∾ {𝕩.source_scale}¨postings
```

This preserves:

- empty input -> scale 0;
- nonempty input -> maximum canonical source scale;
- exact integer coefficient scaling;
- original source coefficient and source scale evidence.

No binary floating-point arithmetic, rounding, or conversion is introduced.

## CompleteElided

The previous implementation accumulated shared `diagnostics` and `completed` vectors while iterating the transaction axis.

The reviewed form makes transaction lifetime explicit:

```text
transaction coordinate
  -> selected Posting cell
  -> elided relation
  -> local diagnostics
  -> local completed Posting cell

all transaction result cells
  -> diagnostics flatten in transaction order
  -> completed Posting flatten in transaction order
```

`CompleteTransaction` therefore returns:

```text
{ diagnostics, postings }
```

rather than mutating owner-wide accumulators.

### Dependent local guards retained

The internal inference path remains staged intentionally:

```text
exactly one elided Posting
  -> explicit evidence exists
  -> normalize explicit evidence
  -> infer exact opposite coefficient
  -> inferred coefficient is nonzero
  -> replace only the elided Posting evidence
```

These are semantic dependencies, not traversal machinery. Flattening them into eager whole-array expressions would make invalid intermediate values reachable and obscure diagnostic ownership.

## Balance diagnostics

Balance validation now maps one local diagnostic function across the transaction axis:

```text
transaction coordinate
  -> selected normalized Posting cell
  -> exact total
  -> missing diagnostic cell
  -> unbalanced diagnostic cell
  -> concatenate in existing local order

transaction diagnostic cells
  -> flatten in transaction order
```

The two diagnostic cells are named before concatenation. This avoids relying on dense train parsing and keeps the public local diagnostic order visible.

## Evidence

- CI #2733 FAILURE: test binding-role error, no production evidence;
- CI #2734 FAILURE: incorrect characterization assumption about trailing-zero canonical scale;
- CI #2735 SUCCESS: corrected exact-completion characterization on previous production;
- CI #2736 SUCCESS: transaction-local completion/balance implementation with full `tools/check.sh` and coverage.

## Review conclusion

The useful subtraction was not to remove all conditionals. It was to distinguish:

```text
transaction-axis accumulation state
```

from:

```text
local exact-inference dependency state
```

The former is now expressed as independent result cells plus flattening. The latter remains local because it carries real exact-accounting meaning.

No currency policy, Account resolution, Posting source coordinate, identity, provenance, diagnostic code/line ownership, complete-Journal partitioning, or writer/source authority changed.
