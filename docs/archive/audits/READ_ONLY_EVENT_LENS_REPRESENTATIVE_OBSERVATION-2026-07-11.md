# Read-only Event Lens Representative Observation

## 1. Status and point-in-time commit

- **Status**: Completed (Observation and evidence collection)
- **Commit**: `dc0246d69ef85c6d37b213954d415b1e97922aca` (after PR #173 merged)
- **Engine Version**: Headless Kernel (Phase D - Slice 1)

## 2. Question

What does the current event lens actually reveal, preserve, classify as ambiguous, and leave absent when applied to representative checked results?

## 3. Runtime path inspected

The observation was performed using the pure builder function [BuildRows](../../../src_next/event_lens.bqn#L7) in [src_next/event_lens.bqn](../../../src_next/event_lens.bqn).

Data flow:
```text
checkedResult (from ctx.BuildCheckedPostingProjectionFromSnapshot)
  -> event_lens.BuildRows
  -> lensResult (state = "ok" or "error")
```

## 4. Representative input cases

The following representative cases were inspected:
1. **Normal JPY expense**: `assets:bank` -> `expenses:food`, memo present, no party metadata.
2. **Explicit party metadata**: Token `party=StoreA` in metadata fields.
3. **Empty memo**: Empty second field (index 1) in TSV.
4. **Plan expense**: Source row in `plan.tsv` mapped to expense category.
5. **Transfer**: Self-transfer `assets:bank` -> `assets:bank`.
6. **Income**: `income:salary` -> `assets:bank`.
7. **All-ILS exact decimal rows**: Multiple ILS rows with decimals (`1200`, `42.50`, `0.05`).
8. **Failed checked result**: Malformed currency amount causing check failure.
9. **Multiple source rows**: Source ordering, row indices, and 1-to-1 mapping checks.

## 5. Exact observed lens rows

The execution output for each representative case:

### Case 1: Normal JPY Expense
```text
source_file:        journal.tsv
source_row:         0
source_id:          normal memo
when_value:         2026-06-15
when_state:         direct
party_value:        
party_state:        absent
what_value:         normal memo
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     expenses:food
where_to_state:     direct
amount_text:        1200
amount_coefficient: 1200
amount_scale:       0
currency:           JPY
amount_state:       direct
action_value:       actual:expense
action_state:       derived
layer:              actual
kind:               expense
```

### Case 2: Explicit Party Metadata
```text
source_file:        journal.tsv
source_row:         0
source_id:          memo text
when_value:         2026-06-15
when_state:         direct
party_value:        StoreA
party_state:        direct
what_value:         memo text
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     expenses:food
where_to_state:     direct
amount_text:        1200
amount_coefficient: 1200
amount_scale:       0
currency:           JPY
amount_state:       direct
action_value:       actual:expense
action_state:       derived
layer:              actual
kind:               expense
```

### Case 3: Empty Memo
```text
source_file:        journal.tsv
source_row:         0
source_id:          
when_value:         2026-06-15
when_state:         direct
party_value:        
party_state:        absent
what_value:         
what_state:         absent
from_account:       assets:bank
where_to_value:     expenses:food
where_to_state:     direct
amount_text:        1200
amount_coefficient: 1200
amount_scale:       0
currency:           JPY
amount_state:       direct
action_value:       actual:expense
action_state:       derived
layer:              actual
kind:               expense
```

### Case 4: Plan Expense
```text
source_file:        plan.tsv
source_row:         0
source_id:          plan exp
when_value:         2026-06-15
when_state:         direct
party_value:        
party_state:        absent
what_value:         plan exp
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     expenses:food
where_to_state:     direct
amount_text:        1200
amount_coefficient: 1200
amount_scale:       0
currency:           JPY
amount_state:       direct
action_value:       plan:expense
action_state:       derived
layer:              plan
kind:               expense
```

### Case 5: Transfer
```text
source_file:        journal.tsv
source_row:         0
source_id:          transfer memo
when_value:         2026-06-15
when_state:         direct
party_value:        
party_state:        absent
what_value:         transfer memo
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     assets:bank
where_to_state:     direct
amount_text:        1200
amount_coefficient: 1200
amount_scale:       0
currency:           JPY
amount_state:       direct
action_value:       actual:transfer
action_state:       derived
layer:              actual
kind:               transfer
```

### Case 6: Income
```text
source_file:        journal.tsv
source_row:         0
source_id:          salary memo
when_value:         2026-06-15
when_state:         direct
party_value:        
party_state:        absent
what_value:         salary memo
what_state:         ambiguous
from_account:       income:salary
where_to_value:     assets:bank
where_to_state:     direct
amount_text:        1200
amount_coefficient: 1200
amount_scale:       0
currency:           JPY
amount_state:       direct
action_value:       actual:income
action_state:       derived
layer:              actual
kind:               income
```

### Case 7: All-ILS Exact Decimal Rows
Row 1:
```text
source_file:        journal.tsv
source_row:         0
source_id:          food
when_value:         2026-06-15
when_state:         direct
party_value:        
party_state:        absent
what_value:         food
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     expenses:food
where_to_state:     direct
amount_text:        1200
amount_coefficient: 120000
amount_scale:       2
currency:           ILS
amount_state:       direct
action_value:       actual:expense
action_state:       derived
layer:              actual
kind:               expense
```
Row 2:
```text
source_file:        journal.tsv
source_row:         1
source_id:          book
when_value:         2026-06-16
when_state:         direct
party_value:        
party_state:        absent
what_value:         book
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     expenses:learning
where_to_state:     direct
amount_text:        42.50
amount_coefficient: 4250
amount_scale:       2
currency:           ILS
amount_state:       direct
action_value:       actual:expense
action_state:       derived
layer:              actual
kind:               expense
```
Row 3:
```text
source_file:        journal.tsv
source_row:         2
source_id:          small
when_value:         2026-06-17
when_state:         direct
party_value:        
party_state:        absent
what_value:         small
what_state:         ambiguous
from_account:       assets:bank
where_to_value:     expenses:food
where_to_state:     direct
amount_text:        0.05
amount_coefficient: 5
amount_scale:       2
currency:           ILS
amount_state:       direct
action_value:       actual:expense
action_state:       derived
layer:              actual
kind:               expense
```

### Case 8: Failed Checked Result
```text
state: error
message: checked result state is not ok
```

## 6. Semantic-state review

The observation confirms that the six dimensions report their state exactly as follows:

| Dimension | State | Value Source / Logic |
|---|---|---|
| **when** | `direct` | Date present and valid. |
| | `absent` | Date is missing/empty. |
| | `ambiguous` | Date has invalid format (unobserved in healthy runtime due to validation rules). |
| **party** | `direct` | Extracted from `party=` token in metadata fields. |
| | `absent` | No `party=` metadata is provided. |
| | `ambiguous` | Multiple `party=` tokens are provided in metadata. |
| **what** | `absent` | Memo text (field 2) is empty. |
| | `ambiguous` | Memo text is non-empty. It is marked `ambiguous` because it represents a raw string where business categorizations, item lists, or specific transaction meanings remain untokenized/unstructured. |
| **where_to** | `direct` | `where_to_value` (field 4) is present. |
| | `absent` | `where_to_value` is empty. |
| **amount** | `direct` | Extracted successfully from transaction amount and arithmetic proof. |
| **action** | `derived` | Constructed from resolved layer name and transaction kind (`layer_name:kind`). |

## 7. ILS exact-decimal evidence

Decimals in ILS are successfully preserved through scaling:
- **1200 ILS** -> coefficient: `120000`, scale: `2`, currency: `ILS`.
- **42.50 ILS** -> coefficient: `4250`, scale: `2`, currency: `ILS`.
- **0.05 ILS** -> coefficient: `5`, scale: `2`, currency: `ILS`.

No rounding error or float conversion occurred, preserving exact representation.

## 8. What the lens reveals well

- **1-to-1 Source Identity**: Exactly one event row maps back to exactly one source line (matching `source_file` and `source_row`), completely avoiding the need to split debits/credits.
- **Accurate Action Routing**: Resolves correct layers (`actual` vs. `plan`) and kinds (`expense`, `income`, `transfer`) by checking corresponding posting rows.
- **Robust Decimal Handling**: Captures the exact coefficient and decimal scale for non-standard currencies (e.g. ILS) accurately.

## 9. What remains ambiguous or absent

- **Itemized Details (what)**: The raw memo field remains unparsed, so specific item divisions or purchase details are marked `ambiguous`.
- **Counterparties (party)**: Unless explicitly annotated with `party=`, counterparties are `absent`. We avoid guessing party information from raw memo text.

## 10. Information not represented

- **Valuation / FX Rates**: No conversion to a base currency is calculated.
- **Display formatting**: Currency symbols (e.g., `₪`, `¥`) are absent.
- **Household Policy**: No budget groupings, cycles, or roll-over logic.

## 11. Whether a formatter is justified

A formatter is highly justified. Currently, inspectable rows are returned as nested BQN namespaces, which cannot be viewed by humans or external tools without evaluation. A formatter converting these into read-only TSV representation is a safe next step.

## 12. Scope boundary retained

The observation confirms:
- **No canonical model changes**: 6D remains an auxiliary lens.
- **No side-effects**: The operation is completely pure.
- **No strict event-sourcing**: Does not append state events or enforce history replay.

## 13. Conclusion

**A. A formatter is justified as the next finite slice**

Specified boundary for next slice:
```text
FormatTsv lensResult
```
- Module path: `src_next/event_lens_format.bqn`
- Purpose: Convert a successful or failed `lensResult` into clean read-only TSV text.
