# src-next-opening-before-cycle

Accounting-grade fixture for TBDS opening / movement / closing.

The opening balance is created before the selected cycle:

```text
cycle: 2026-06-15 .. 2026-08-15

2026-06-01 Opening  equity:opening-balances -> assets:bank   100000
2026-06-20 Food     assets:bank             -> expenses:food 1000
```

Expected actual-layer TBDS:

| account | opening | movement | closing |
|---|---:|---:|---:|
| assets:bank/JPY | 100000 | -1000 | 99000 |
| expenses:food/JPY | 0 | 1000 | 1000 |
| equity:opening-balances/JPY | -100000 | 0 | -100000 |

This fixture fails if the engine treats cycle start as the ledger loading boundary or displays period movement as balance.
