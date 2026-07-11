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
```

Intended source shape:

```tsv
# accounts.tsv
assets:現金-ILS	role=asset	type=liquid	currency=ILS
expenses:食費-ILS	role=expense	currency=ILS
expenses:書籍-ILS	role=expense	currency=ILS
expenses:交通-ILS	role=expense	currency=ILS
```

```tsv
# journal.tsv
2026-07-12	パン	assets:現金-ILS	expenses:食費-ILS	12.50	currency=ILS
```

The first daily-use design uses unique raw account names for ILS accounts, such as `expenses:食費-ILS`. Defining the same raw account name once for JPY and again for ILS is not adopted until ambiguity in the current raw-name account lookup is resolved.

This plan changes no source TSV. The examples describe a future supported surface only.

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
- Balances have no currency selector, currency symbol, or minor-unit-aware display.
- Account metadata currency is not currently checked against row currency during projection; M1 must add that fail-closed boundary.

## A. Selected boundary

- Put JPY rows and ILS rows in the same source TSV files.
- Preserve compatibility: a row or account without currency resolves to JPY.
- ILS rows and accounts explicitly carry `currency=ILS`.
- One calculation/report invocation selects exactly one currency.
- Never add JPY and ILS.
- Do not implement FX, conversion, valuation, base currency, or exchange gains/losses.
- Do not add a Currency axis to the Cube.
- Reuse existing single-currency exact arithmetic after currency selection.
- A mixed ledger without a selected currency fails closed.
- An existing JPY-only ledger continues to work without a selector.
- If row currency differs from From or To account metadata currency, fail closed.

## B. Desired final daily-use surface

The following commands are candidate future surfaces, not implemented or authorized by this PR:

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

The daily-use UI should select currency first, then show only matching From/To account candidates. The editor should generate journal metadata `currency=ILS` from that selected currency; a person should not need to enter it repeatedly through `--meta`.

## C. Future ILS display contract

A later slice must satisfy all of these requirements:

- Human ILS balances display as `₪12.50`.
- Because ILS uses agora, daily-use source amounts allow at most two fractional digits.
- ILS source amounts with more than two fractional digits fail closed without rounding.
- Existing JPY display and calculation remain unchanged.
- Human formatting needs a carrier from which selected currency and `amount_scale` can be read safely.
- No combined JPY/ILS net worth is emitted.
- ILS expense breakdown is an independent slice after balances is complete.

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
- Preserve full compatibility for a JPY-only snapshot without a selector.
- Do not change the public report CLI, editor, or human formatting.

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

### M2: Editor currency-aware account and journal input

Independent slice after M1:

- `account add --currency`
- `account list --role --currency`
- exact-decimal editor amount validation
- at most two fractional digits for ILS
- only matching-currency From/To candidates
- automatic row `currency=ILS` generation
- rejection of mismatched account currencies

### M3: ILS balances report

Independent slice after M2:

- public `--currency ILS`
- `balances` as the first consumer
- ILS assets and liabilities only
- `₪12.50` display
- no JPY/ILS aggregation
- no JSON widening, snapshot, cycle, envelope, or outlook work

### M4: ILS expense breakdown

Independent candidate only after daily-use observation:

- cycle breakdown for ILS food, books, transport, and similar expenses
- do not combine it with balances; first recheck the existing expense/cycle consumer contract

## E. Explicit non-goals

- FX
- JPY conversion
- ILS conversion
- base currency
- exchange-rate metadata
- Currency axis
- mixed-currency totals
- mixed-currency net worth
- investment valuation
- broad multi-currency plan/budget/envelope changes
- all report sections in one campaign
- all JSON outputs in one campaign
- changes to the first five source columns
- real data changes
- duplicate definitions of the same raw account name across currencies
- automatic expansion under a broad `Stage 3` campaign name

## Routing and exit

Stage 2 documents remain the current single-currency exact foundation. This plan owns selection and sequencing for the concrete mixed-ledger JPY/ILS daily-use consumer.

The current authorization is M1 only. After each implementation slice, use a separate post-implementation verification PR. Archive this plan as completed when the selected daily-use slices are implemented and verified, or as superseded if a later plan replaces this boundary.
