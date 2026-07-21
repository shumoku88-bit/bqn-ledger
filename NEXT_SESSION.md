# Next session

Status: finite slice selected
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: complete the focused characterization and return routing to no selected finite Journal slice

## Selected Slice

Journal split-purchase transaction characterization — test-only

## Canonical Finite Contract

[docs/JOURNAL_SPLIT_PURCHASE_TRANSACTION_CHARACTERIZATION_PLAN.md](docs/JOURNAL_SPLIT_PURCHASE_TRANSACTION_CHARACTERIZATION_PLAN.md)

## Finite Question

> Can public synthetic Journal purchase transactions preserve one real-world purchase event containing multiple expense-category postings and one payment posting through Stage 1, the read-only source carrier, Stage 2A, and numeric account reduction, while retaining posting order, transaction-local balance, and exact category totals, using tax-inclusive amounts and remaining disconnected from production routing?

## Selected Public Synthetic Evidence

3 transactions with explicit JPY commodity and account declarations:
- Transaction A: Convenience store split purchase (tobacco 600, coffee 150, cash -750)
- Transaction B: Supermarket food split (daily 1400, stock 900, bank -2300)
- Transaction C: Supermarket mixed purchase (daily 1400, stock 900, household 500, bank -2800)

## Tax-inclusive Boundary

All posting amounts are tax-inclusive receipt amounts. No tax postings, splits, tax metadata, or net-price reconstruction. Category posting is tax-inclusive category subtotal.

## Expected Future Implementation Invariants

- Stage 1: `state = "ok"`, 3 transactions, posting counts `3, 3, 4`, delta sum is 0, distinct fallback event identities.
- Stage 2A & Carrier: `state = "ok"`, total Posting IR row count is 10, retains orders, standard 16-field shapes, `source_file` is unmodified, no production loader.
- Expected aggregate totals:
  - expenses:tobacco/JPY      600
  - expenses:coffee/JPY       150
  - expenses:food:daily/JPY  2800
  - expenses:food:stock/JPY  1800
  - expenses:household/JPY    500
  - assets:cash/JPY          -750
  - assets:bank/JPY         -5100
  - Delta sum: 0. Expense total: 5850. Cash/bank total: -5850.

## Non-goals

- No production Journal loader/routing, writer, editor, or sync.
- No tax postings, net price re-construction, or tax rate metadata.
- No automatic account creation, fuzzy match, inventory accounting, shadow read, conversion, or cutover.
