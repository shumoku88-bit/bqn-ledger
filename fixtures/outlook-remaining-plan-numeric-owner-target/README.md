# Outlook Remaining-Plan Numeric-Owner Target Fixture

Public synthetic fixture for Outlook Slice B.

```text
C = [2026-02-01, 2026-02-11)
O = 2026-02-05
```

The fixture proves that checked `plan.tsv` Posting IR owns remaining money while source evidence owns completion and anchors.

Expected remaining-plan behavior:

- unanchored outflow `10` is reserved;
- anchored outflow with a met anchor `20` is reserved;
- anchored outflow with an unmet anchor `30` is still reserved;
- unanchored inflow `40` is included;
- anchored inflow with an actual income event at or before O `50` is included;
- anchored inflows whose income arrives after O, or does not arrive, are excluded;
- completed outflow `80` is excluded;
- the row at `C.end_exclusive` is outside the remaining horizon.

At O, actual liquid balance is `920`, remaining planned income is `90`, fixed reserve is `60`, and remaining liquid net is `30`.
