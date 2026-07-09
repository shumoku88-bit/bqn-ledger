# Currency Stage 1 Amount Semantics Decision

Status: current contract / docs-only decision record
Owner: config
Canonical: yes
Decision date: 2026-07-09
Supersedes / depends on: selects the Stage 1 amount/currency semantics requested by `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md`; depends on Stage 0 evidence in `docs/CURRENT_CURRENCY_ASSUMPTION_MAP.md`
Exit: supersede when a later current currency contract replaces these source amount, currency, and arithmetic-domain semantics

## 1. Question

What does the source `amount` field mean once non-JPY currency exists, and how should missing, explicit, unknown, account-level, and Posting IR currency states be understood before implementation begins?

This is a product-semantics decision. It does not change current runtime behavior.

## 2. Selected contract

Stage 1 selects these semantics:

```text
source amount = exact decimal monetary quantity, human-readable original observed amount in the source row's currency
precision semantics = exact decimal monetary quantity; no implicit binary floating-point semantics; no automatic rounding policy selected
explicit currency = identity of the source amount's monetary unit
currency scope = source amount currency identity is row-level semantics; arithmetic currency domain is domain-level context; concrete carriers are Stage 2
missing currency = legacy JPY compatibility resolution, not explicit JPY
unknown explicit currency = invalid / fail closed
account-level currency= = account denomination / account identity metadata
display precision = presentation policy, not source amount authority, currency identity, or arithmetic semantics
Posting IR naked delta = temporarily valid only inside a proven single-currency arithmetic domain
mixed-currency arithmetic = not authorized merely by currency labels
FX / reporting valuation = out of scope
```

Required semantic guards:

```text
amount != currency
original_amount != reporting_value
currency != exchange_rate
missing currency != unknown explicit currency
missing currency != explicit JPY
account currency != source amount authority
source amount currency != arithmetic domain currency
source amount currency != display precision policy
source amount currency != reporting valuation
row-level currency identity != arithmetic domain currency
currency label != arithmetic addability
display precision != source amount authority
display precision != currency identity
display precision != arithmetic semantics
naked delta != universally addable monetary value
```

## 3. Source amount meaning

Selected source contract:

```text
source amount
=
human-readable original observed amount
in the source row's currency
```

Examples of the selected future source meaning:

```text
JPY 1200 yen:
amount=1200
currency=JPY

ILS 42.50:
amount=42.50
currency=ILS

USD 12.34:
amount=12.34
currency=USD
```

Meaning:

```text
source amount != JPY-converted value
source amount != reporting value
source amount != base amount
source amount != FX valuation
```

The source amount represents the amount as observed in the original transaction currency.

### 3.1 Precision semantics

Selected precision contract:

```text
source amount
=
exact decimal monetary quantity
in the source currency
```

The source amount must not be given implicit binary floating-point semantics. No automatic rounding policy is selected here.

Current runtime note: current projection and editor validation remain integer-only in this PR. Decimal parsing, scale validation, and rounding are not implemented here. This decision selects future semantics only.

## 4. Explicit currency meaning

Selected explicit currency contract:

```text
explicit currency
=
identity of the source amount's monetary unit
```

Examples:

```text
amount=1200  currency=JPY
amount=42.50 currency=ILS
amount=12.34 currency=USD
```

`amount` and `currency` remain separate concepts. A currency code identifies the unit of the observed source amount; it is not itself an exchange rate, a reporting value, or a proof of arithmetic addability with other currencies.

### 4.1 Currency scope

Selected currency-scope contract:

```text
source amount currency identity = row-level semantics
arithmetic currency domain = domain-level context
row-level currency identity != arithmetic domain currency
```

A source row's explicit currency identifies the monetary unit of that row's observed source amount. It does not by itself establish that the current projection, cube, TBDS, report, or export is operating inside a proven single-currency arithmetic domain.

Concrete carriers for the arithmetic currency domain remain a Stage 2 decision. Possible carrier questions include ledger config, run context, source compatibility resolution, and the projection boundary.

Preserve:

```text
source amount currency
!= arithmetic domain currency
!= display precision policy
!= reporting valuation
```

## 5. Missing currency compatibility

Selected missing currency contract:

```text
missing currency
=
legacy compatibility resolution to JPY
for current existing source behavior
```

This preserves existing JPY data and current operation without rewriting historical source rows.

Important distinction:

```text
missing currency != explicit JPY
```

Meanings:

```text
legacy row with no explicit currency
  -> compatibility JPY fallback path

explicit currency=JPY
  -> explicit JPY identity

explicit currency=ILS
  -> explicit ILS identity
```

The fallback is a compatibility resolution, not a universal truth that currency absence semantically means JPY forever.

## 6. Unknown explicit currency

Selected unknown explicit currency contract:

```text
explicit unknown currency
=
invalid
=
fail closed
```

Examples of future invalid explicit currency states:

```text
currency=XYZ_UNKNOWN
currency=???
```

These must not silently become JPY.

Selected distinction:

```text
missing
  -> compatibility fallback path

known explicit
  -> explicit identity

unknown explicit
  -> rejection / fail closed
```

Current runtime note: this PR does not implement currency validation or metadata schema changes.

## 7. Account-level currency role

Selected account-level contract:

```text
account-level currency=
=
account denomination / account identity metadata
```

It is not authoritative for the source row amount.

Preserve:

```text
account currency != source amount currency authority
```

Current AccountKey behavior may carry values such as:

```text
assets:bank/JPY
assets:usd_cash/USD
```

That AccountKey label can describe the account denomination or identity, but it does not by itself prove the source row amount's currency.

This distinction is necessary because current source rows have:

```text
one amount
two accounts
```

A source row that references a cross-currency account pair cannot derive safe amount semantics merely from the two AccountKeys. Current account default-to-JPY behavior is compatibility behavior, not universal source amount authority.

## 8. Posting IR transitional rule

Selected transitional rule:

```text
Posting IR naked delta may remain temporarily valid
only inside a proven single-currency arithmetic domain
```

Preserve:

```text
naked delta != universally addable monetary value
```

Selected next-stage meaning:

```text
single-currency domain proven
  -> current naked delta arithmetic may continue temporarily

mixed or unresolved currency domain
  -> naked delta arithmetic is not semantically authorized
```

This is a transitional Stage 1 contract. It is not proof that mixed-currency arithmetic is safe. This PR does not add currency fields to Posting IR, change cube or TBDS axes, implement partitions, or modify projection runtime shape.

## 9. Mixed-currency arithmetic prohibition

Selected mixed-currency arithmetic boundary:

```text
AccountKey carrying /JPY, /ILS, /USD
does not authorize arithmetic across those values
```

Preserve:

```text
currency label presence
!= conversion
!= addability
!= valuation
```

Explicitly rejected:

```text
currency=ILS
```

by itself does not make current totals safe.

Current behavior is compatible with the repository's effectively one-currency operating assumption, but mixed-currency arithmetic is not currently protected or authorized by this decision.

## 10. Compatibility with existing JPY data

Existing JPY data without explicit currency remains compatible.

Compatibility is preserved through legacy JPY resolution:

```text
missing source currency -> compatibility JPY fallback
```

This does not rewrite historical source rows. This does not claim absence and explicit JPY are identical meanings. This does not change current integer-only runtime behavior.

Current runtime remains integer-only in this PR even though the selected source semantics allow future exact decimal human-readable amounts for currencies that require them.

## 11. Display precision decision

Selected display precision contract:

```text
display precision = presentation policy
```

Display precision is not source amount authority, currency identity, or arithmetic semantics.

Preserve:

```text
display precision != source amount authority
display precision != currency identity
display precision != arithmetic semantics
```

Currency metadata may later inform formatting, but it must not redefine the stored source amount. For example, a future formatter may choose how many decimal places to show for a known currency, but that presentation choice must not change the observed source amount, establish arithmetic addability, or create reporting valuation.

## 12. Non-goals

This decision does not select or implement:

- runtime BQN changes;
- shell behavior changes;
- source TSV migration;
- `currency=` implementation in source rows;
- `base_amount=`;
- `BASE_CURRENCY`;
- decimal parser support;
- minor-unit normalization;
- currency axis;
- Posting IR runtime currency fields;
- cube or TBDS axis changes;
- JSON/ViewModel changes;
- editor amount parsing changes;
- AccountKey runtime behavior changes;
- metadata schema changes;
- live FX API;
- automatic conversion;
- historical valuation;
- rate source policy;
- rate observation policy;
- valuation date policy.

Preserve:

```text
original_amount != reporting_value
currency != exchange_rate
transaction_date != rate_observation_date
rate_observation_date != valuation_date
valuation_date != report_coordinate
```

## 13. Consequences for next implementation slice

Smallest justified next finite slice:

```text
Currency Awareness Stage 2 single-currency awareness design intake
```

Next finite question:

```text
Where and how is one arithmetic currency domain explicitly established before projection/aggregation?
```

The next slice should prove one explicit arithmetic currency domain before mixed-currency operation. Examples of possible future domain shapes include:

```text
ledger/run/partition currency = JPY
```

or later:

```text
ledger/run/partition currency = ILS
```

This decision does not select the carrier. The carrier question remains separate and may involve ledger config, run context, source compatibility resolution, or the projection boundary.

The Stage 2 design intake must not smuggle in FX valuation or mixed-currency reporting. It should decide how a single-currency arithmetic domain is established, observed, and failed closed before current naked-delta arithmetic is allowed to proceed.

## 14. Exit / supersession conditions

This decision remains current until replaced by a later current currency contract that explicitly covers these meanings:

- source amount representation;
- precision semantics;
- explicit currency identity;
- row-level currency identity vs domain-level arithmetic currency;
- missing currency compatibility;
- unknown explicit currency failure;
- account-level currency role;
- display precision policy;
- Posting IR amount/currency shape;
- arithmetic domain proof;
- mixed-currency aggregation boundary.

A later implementation PR may update contracts and checks, but it must preserve the semantic distinctions selected here unless a new decision record explicitly supersedes them.
