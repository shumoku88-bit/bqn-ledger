# Currency Mixed JPY / ILS Daily-Use Plan — 2026-07-12

Status: active plan
Owner: currency
Canonical: yes
Exit: archive as completed or superseded after the selected mixed-ledger daily-use slices are implemented and verified

## Purpose and concrete user requirement

Stage 2 established the single-currency exact-arithmetic foundation. This plan selects a concrete mixed-ledger daily-use consumer without authorizing mixed-currency arithmetic:

```text
一つの accounts.tsv / journal.tsv にJPYとILSを記帳したい。

ILSでは、食費・書籍・交通などのILS用科目を入力候補から選びたい。

ILSの現金・銀行・負債残高だけを、JPYと合算せず表示したい。

帳簿のdefault currencyは明示的に設定し、現在どの通貨viewを表示しているか人間向け出力にも明示したい。

既存のproduction sourceにcurrencyが省略されている場合は、安全な移行手順でcurrency=JPYを明示したい。
```

Intended source shape:

```tsv
# accounts.tsv
assets:現金	role=asset	type=liquid	currency=JPY
expenses:食費	role=expense	currency=JPY	report_group=食費
assets:現金-ILS	role=asset	type=liquid	currency=ILS
expenses:食費-ILS	role=expense	currency=ILS	report_group=食費
expenses:書籍-ILS	role=expense	currency=ILS	report_group=書籍
expenses:交通-ILS	role=expense	currency=ILS	report_group=交通
```

```tsv
# journal.tsv
2026-07-12	スーパー	assets:現金	expenses:食費	1800	currency=JPY
2026-07-12	パン	assets:現金-ILS	expenses:食費-ILS	12.50	currency=ILS
```

The first daily-use design preserves existing JPY raw account names and uses unique raw names for additional currency-specific accounts, such as `expenses:食費-ILS`. Defining the same raw account name once for JPY and again for ILS is not adopted until ambiguity in the current raw-name account lookup is resolved.

`report_group=食費` is a future presentation grouping candidate. It may group currency-specific accounts under one human category, but it must never authorize cross-currency addition.

This plan changes no production source TSV by itself. Source migration is a separately verified and user-approved operation.

## Current implementation facts

Verified on `main` before selecting this plan:

- `AccountKey = (Account, Currency)` already exists; account currency defaults to JPY when unspecified.
- Row evidence resolves missing currency as JPY and `currency=ILS` as ILS.
- All-ILS exact decimals pass through context, normalized Posting IR deltas, Cube, and TBDS.
- A mixed JPY/ILS snapshot currently fails closed.
- Projection rows have no currency field; account identity is carried by AccountKey.
- `account list` filters only by role, not currency.
- `account add` cannot generate currency metadata.
- Editor amount validation is integer-only, so `12.50` cannot enter through the daily write path.
- Balances have no currency selector, explicit default-currency carrier, currency symbol, or minor-unit-aware display.
- Account metadata currency is not currently checked against row currency during projection; M1 must add that fail-closed boundary.
- Missing row/account currency currently uses legacy JPY compatibility. That remains current runtime truth until an explicit migration and strict-source slice replaces it.

## A. Selected boundary

- Put JPY rows and ILS rows in the same source TSV files.
- One calculation/report invocation selects exactly one currency.
- Never add JPY and ILS.
- Do not implement FX, conversion, valuation, base currency, or exchange gains/losses.
- Do not add a Currency axis to the Cube.
- Reuse existing single-currency exact arithmetic after currency selection.
- If row currency differs from From or To account metadata currency, fail closed.

### Explicit default currency policy

The selected daily-use policy is:

```text
ledger default currency
  = explicit ledger configuration
  = initial input/report selection
  = visible in human output

ledger default currency
  != missing source currency fallback
  != source amount authority
  != conversion target
  != base valuation currency
```

Consequences:

- A daily-use ledger must eventually declare an explicit default currency such as JPY, ILS, EUR, or USD in a ledger-level configuration owner selected by a later finite slice.
- The default selects the initial account-candidate view and the initial report currency when no explicit override is supplied.
- Human report output must state the selected currency, including when it came from the ledger default.
- New production accounts and journal-like rows must carry explicit `currency=` metadata.
- The editor must write explicit currency metadata even when the selected currency equals the ledger default.
- A missing source currency must not silently inherit the configured default.
- The current missing-to-JPY behavior remains a temporary legacy compatibility path only until migration is complete and strict source validation is separately enabled.

### Production source migration policy

The intended migration target is:

```text
accounts.tsv
journal.tsv
plan.tsv
budget_alloc.tsv
  -> every monetary account/row has exactly one explicit currency metadata token
```

The first production migration is expected to add `currency=JPY` to existing JPY source where currency is absent. It must not rename existing account identifiers or rewrite From/To references.

Migration safety requirements:

- provide a read-only audit before any write;
- preserve the first five journal-like TSV columns exactly;
- preserve existing account names and all journal-like From/To account references exactly;
- preserve row order, empty fields, comments, and unrelated metadata;
- append `currency=JPY` only when currency metadata is absent;
- reject duplicate currency metadata, unknown explicit currency, or structurally invalid rows;
- be idempotent;
- support dry-run with an exact proposed diff or replacement preview;
- use the existing safe-write/snapshot-token boundary rather than blind in-place editing;
- require explicit user confirmation for production data;
- run lint/full checks after migration;
- keep a recoverable pre-write copy or equivalent safe replacement boundary;
- never migrate public fixtures and production data in the same write operation.

After the production source is audited, migrated, and verified, a separate finite slice may enable strict production behavior where missing account/row currency fails closed. Legacy fallback may remain only where an explicitly documented compatibility fixture or migration test still requires it.

## B. Desired final daily-use surface

The following commands and config are candidate future surfaces, not implemented or authorized by this docs amendment:

```text
# ledger-level config, exact key/owner to be selected later
DEFAULT_CURRENCY=JPY
```

```bash
tools/edit account add \
  --name expenses:食費-ILS \
  --role expense \
  --currency ILS

tools/edit account list \
  --role expense \
  --currency ILS

tools/edit journal add \
  --date 2026-07-12 \
  --memo パン \
  --from assets:現金-ILS \
  --to expenses:食費-ILS \
  --amount 12.50 \
  --currency ILS

tools/report \
  --currency ILS \
  --section balances
```

The daily-use UI should start from the explicit ledger default, allow an explicit currency override, then show only matching From/To account candidates. The editor should always generate row currency metadata from the selected currency; a person should not need to enter it repeatedly through `--meta`.

A report using the default should still state its effective selection:

```text
Currency view: JPY (ledger default)
```

An explicit override should state:

```text
Currency view: ILS (explicit selection)
```

## C. Future currency display contract

Later slices must satisfy all of these requirements:

- Human ILS balances display as `₪12.50`.
- Because ILS uses agora, daily-use source amounts allow at most two fractional digits.
- ILS source amounts with more than two fractional digits fail closed without rounding.
- Existing JPY calculation remains unchanged during the migration period.
- Human formatting needs a carrier from which selected currency, selection provenance, and `amount_scale` can be read safely.
- No combined JPY/ILS net worth is emitted.
- The effective currency view is always visible in human output.
- Display precision remains presentation policy and does not redefine source amount meaning.

## D. Implementation slices

Each slice requires separate authorization. Completion of one does not automatically authorize the next.

### M1: Checked selected-currency projection seam

This is the finite slice selected in `TODO.md`.

Scope:

- Add a mixed JPY/ILS fake fixture.
- Build row evidence exactly once from one shared snapshot.
- Design and implement a pure checked boundary that filters row evidence by explicit selected currency.
- Reuse the existing single-domain arithmetic proof after selection.
- Carry selected JPY and selected ILS independently through balanced posting rows.
- Fail closed when row currency differs from From or To account currency.
- Preserve current fail-closed behavior for a mixed snapshot without a selector.
- Preserve full compatibility for a JPY-only snapshot without a selector during M1.
- Do not change the public report CLI, editor, production source, migration tooling, or human formatting.

Before adding a currency field to Posting IR, M1 must determine whether it is actually necessary. If each projection is always single-currency, prefer:

```text
selected currency / amount_scale
  -> checked result or context carries it

account identity
  -> existing AccountKey carries currency

Posting IR
  -> do not widen unless evidence proves it necessary
```

Do not decide Posting IR widening without evidence.

### M1.5: Explicit default carrier and production migration tooling

Independent slice after M1 and before strict production source enforcement:

- select the ledger-level owner and exact key for explicit default currency;
- keep default selection separate from source currency authority;
- expose effective selected currency and selection provenance to later consumers;
- add a read-only missing/duplicate/unknown currency audit;
- add idempotent dry-run migration tooling for `accounts.tsv`, `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv`;
- add fake fixtures proving `currency=JPY` migration without first-five-column or account-name drift;
- do not modify production data inside the implementation PR;
- execute production migration only as a separate user-approved operation after tooling verification;
- do not yet remove all legacy compatibility paths.

### M2: Editor currency-aware account and journal input

Independent slice after M1.5:

- `account add --currency`;
- `account list --role --currency`;
- exact-decimal editor amount validation;
- at most two fractional digits for ILS;
- only matching-currency From/To candidates;
- automatic explicit row `currency=` generation for every new row, including JPY;
- rejection of mismatched account currencies;
- explicit default currency as the initial selection only;
- no omission of source currency merely because it equals the default.

### M2.5: Production JPY source migration and strict-source checkpoint

Separate operational checkpoint after M1.5 tooling and M2 write-path support are verified:

- audit the actual `LEDGER_DATA_DIR` source;
- review the dry-run result;
- append `currency=JPY` to existing untagged JPY accounts and journal-like rows without renaming accounts;
- run post-migration checks;
- verify that the new editor writes explicit currency metadata;
- decide in a separate docs/runtime slice whether production missing currency can now fail closed;
- do not delete legacy compatibility fixtures merely because production migration completed.

### M3: Currency-selected balances report

Independent slice after M2 and the default carrier exists:

- public `--currency ILS` explicit override;
- explicit ledger default when no override is supplied;
- visible `Currency view:` line with provenance;
- `balances` as the first consumer;
- selected-currency assets and liabilities only;
- `₪12.50` display for ILS;
- no JPY/ILS aggregation;
- no JSON widening, snapshot, cycle, envelope, or outlook work.

### M4: Expense breakdown grouped by meaning and currency

Independent candidate only after daily-use observation:

- currency-specific source accounts may share an explicit presentation group such as `report_group=食費`;
- output may show one human category with separate currency rows;
- never compute a cross-currency category total;
- selected-currency mode remains the smallest first consumer;
- an all-currency read-only view may later coordinate separate single-currency projections and place them under one category without conversion;
- do not combine this slice with balances; first recheck the existing expense/cycle consumer contract.

Example future output:

```text
食費
  JPY  ¥18,400
  ILS    ₪92.50
  EUR    €14.20
```

## E. Explicit non-goals

- FX;
- JPY conversion;
- ILS conversion;
- base currency or valuation currency;
- exchange-rate metadata;
- Currency axis;
- mixed-currency totals;
- mixed-currency net worth;
- investment valuation;
- broad multi-currency plan/budget/envelope changes;
- all report sections in one campaign;
- all JSON outputs in one campaign;
- changes to the first five source columns;
- direct production data mutation by implementation PRs;
- using the configured default to reinterpret missing source currency;
- renaming existing production account identifiers during currency migration;
- duplicate definitions of the same raw account name across currencies;
- automatic expansion under a broad `Stage 3` campaign name.

## Routing and exit

Stage 2 documents remain the current single-currency exact foundation. This plan owns selection and sequencing for the concrete mixed-ledger daily-use consumer.

The current authorization is M3 only, as selected in `TODO.md`; implementation does not itself close or verify M3. Strict-source enforcement and M4 remain separate, unauthorized candidates. After each implementation slice, use a separate post-implementation verification PR. Archive this plan as completed when the selected daily-use slices are implemented and verified, or as superseded if a later plan replaces this boundary.
