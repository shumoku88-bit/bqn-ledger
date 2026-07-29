# Retained Account Balances report

Status: Portfolio P2 destination proof

Owners:

- `src/accounting/account_balance.bqn` — exact closing capability;
- `src/sections/account_balances.bqn` — retained Matrix/List result and renderers;
- `src/report/json_text.bqn` — explicit pure JSON text constructors shared by two destination JSON consumers.

## Accounting boundary

Input is canonical Actual Facts, one explicit domain, and one explicit observation ordinal. The capability selects Actual Postings through inclusive observation, normalizes them to one exact scale, and returns every admitted Account in domain order, including zero-posting Accounts.

Each Account closing retains source-qualified Posting references. Unknown domain, invalid observation, wrong source Facts, normalization overflow, or sum overflow fails closed with an empty Account table.

The all-Account total is retained as a zero-sum `balanced` check; it is not a net-worth total.

## Section result

The section validates strict observation text against the accounting ordinal and constructs one-column MatrixResult:

```text
rows    = Account indices in admitted order
columns = closing
```

Human, compact, and JSON use the same result. Destination compact emits only:

```text
ledger_balance: ACCOUNT/CURRENCY EXACT_AMOUNT
```

JSON schema is intentionally portfolio-specific:

```json
{
  "currency": "JPY",
  "as_of": "YYYY-MM-DD",
  "accounts": [
    {"account": "assets:cash", "role": "asset", "type": "liquid", "balance": 965}
  ],
  "balanced": true
}
```

Exact decimals are emitted as JSON number text without binary-float conversion. The JSON constructor API requires callers to explicitly choose String, ExactNumber, Boolean, Array, Object, and Pair; it does not coerce arbitrary runtime values.

## Intentional differences from current Balances

- zero Accounts remain visible rather than being filtered out;
- one explicit domain is mandatory;
- no implicit-JPY compatibility body;
- no role-group subtotal or net-worth interpretation is bundled into the balance Matrix;
- currency symbols/display precision are presentation additions, not accounting values;
- compact key is `ledger_balance`, never dual-emitted with `retired_balance`.

Current production routing and key remain unchanged until atomic cutover.

## Proof

- strict public JPY nonzero history and deterministic eight-Account order;
- observation sensitivity;
- ILS mixed scales (`12.30` and `0.05`);
- USD valid empty Actual with explicit zero Accounts;
- source-qualified contributors;
- unknown-domain and observation mismatch fail-closed;
- deterministic human/compact/JSON goldens;
- Planned Payments JSON remains byte-stable after shared JSON extraction.
