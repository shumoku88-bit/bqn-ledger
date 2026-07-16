# Actual Snapshot Numeric-Owner Target Fixture

Public synthetic fixture for the Slice A runtime contract.

```text
C = [2026-02-01, 2026-02-11)
O = 2026-02-05
```

Expected checked actual snapshot behavior:

- pre-cycle actual history contributes to opening balance;
- the O-day actual row is included;
- rows after O are excluded;
- moving O to 2026-02-12 includes the end-exclusive and later out-of-cycle rows;
- no plan or anchor policy is exercised by this fixture.

At O, `assets:cash/JPY = 250`. At 2026-02-12, it is `260`.
