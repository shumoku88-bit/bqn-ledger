# Daily Trend Temporal Campaign Closure Review - 2026-07-08

Status: audit snapshot
Owner: report
Canonical: no; canonical temporal principle: `docs/TIME_AS_AXIS.md`
Exit: retain as closure evidence; reopen only from a separately justified finite candidate

Review date: 2026-07-08

## Decision

Select:

```text
C. close the major Daily Trend temporal semantics campaign,
   while recording residual questions as independent later candidates
```

Current evidence does not establish a concrete unresolved product-facing temporal problem that justifies keeping the major campaign open.

This decision does not claim that every remaining local `L` reference is ideal, dead, or permanently frozen. It means that remaining questions no longer form one active temporal campaign and do not authorize automatic runtime work.

## Review question

From the post-PR #120 / #121 state, determine whether any remaining `L` usage has a current concrete product problem backed by evidence.

Inspect specifically:

- remaining `VM as_of = L`,
- actual current consumers of `vm.as_of`,
- preserved empty-identity reserve branch code,
- current valid-source reachability into that branch,
- current product-facing effect evidence,
- whether a second independent consumer now justifies a shared temporal kernel.

Preserve:

```text
L != O
L != D
L != K
O_row = D
K = unavailable / not claimed
```

## Evidence baseline

The selected Daily Trend product remains A1-like current-source coordinate replay:

```text
S = source snapshot supplied to this run
D = Daily Trend row coordinate
O_row = D
C = cycle boundary
L = record-frontier context
K = unavailable / not claimed
```

Post-PR #120 current dependency shape is approximately:

```text
row coordinates             = f(R_actual, A_empty, C)
liquid                      = f(S, D, C)
planned_future_income       = f(S, D, C)
ordinary reserve            = f(S, D, C, M)
ordinary fund               = f(S, D, C, M)
row days_left               = f(D, C)
ordinary daily              = f(S, D, C, M)
day actual terms            = f(S, D, C)
delta                       = f(S, D, P, C, R, M)
VM as_of                    = f(L)
header days_left            = f(O, C)
```

The strongest characterized ordinary row-frame mixtures have already been removed or separated by PR #101, #105, #110, and #120.

## Finding 1: `vm.as_of` remains L-derived, but no current product-facing problem is established

Current `src_next/daily_trend.bqn` still computes:

```text
as_of = LatestActualDateInCycle(base, cy)
as_of_dn = DaysFromEpoch(as_of)
```

and returns:

```text
vm.as_of = as_of
```

`BuildAt` preserves that field while overriding only:

```text
vm.header_O
```

Current format paths separate the meanings:

- machine `Format` renders trend rows and does not use `vm.as_of`,
- human `FormatHuman` computes section header days remaining from `vm.header_O`,
- the human report path supplies `report_today` to `daily_trend.BuildAt`,
- `--outlook-as-of` remains Outlook-only.

The post-#120 header contract test reads `vm.as_of` to prove internal L preservation and isolation from `header_O`; that is evidence of a preservation check, not evidence of a current product-facing consumer problem.

Narrow conclusion:

```text
remaining VM field:
  vm.as_of = L

current evidence:
  no product-facing semantic defect established merely from that field remaining
```

Do not automatically rewrite it to `O`, `D`, `ctx.as_of`, or `K`.

## Finding 2: current internal L effect is confined to the preserved empty-identity reserve branch

Within current `daily_trend.Build`, `as_of_dn` feeds:

```text
last_act_dn = last((journal dates <= D) + <as_of_dn>)
```

inside the branch selected when:

```text
pid = ""
```

Ordinary reserve identity uses `overlap.PlanId`.

Current `PlanId` behavior is:

```text
first matching non-empty plan_id=value
  -> explicit identity value

metadata absent
  -> concatenated first five TSV fields fallback

explicit plan_id=
  -> concatenated first five TSV fields fallback
```

Therefore the explicit-empty syntax path characterized by PR #107 is closed after PR #110.

## Finding 3: no current valid ordinary plan-row path into `pid = ""` was found

For current fallback identity:

```text
fallback_id = concat(first five TSV fields)
```

A current valid plan row has a non-empty date coordinate. A non-empty first field alone makes the concatenated five-field fallback non-empty.

Therefore:

```text
ordinary valid five-field plan row
  -> fallback identity is non-empty

explicit plan_id= on a valid plan row
  -> same non-empty fallback identity
```

This review found no current valid ordinary plan-row source path that reaches the empty-identity branch.

Important boundary:

- this is not a proof over arbitrary malformed byte strings,
- branch existence is not treated as reachability proof,
- malformed source handling is not redesigned here,
- no dead-code deletion is authorized by this review alone.

Current product conclusion:

```text
preserved empty-identity branch code exists
+
characterized explicit-empty path is closed
+
no current valid ordinary source path was found
+
no current product-facing failure is evidenced
```

## Finding 4: a shared temporal kernel is still not justified

The existing temporal consumer sensitivity audit records materially different consumer contracts, including:

```text
hard cutoff
threshold
period selection
denominator
future cutoff
window length
source order
period boundary
presentation
```

The post-#120 report path also deliberately keeps:

```text
Outlook O
```

separate from:

```text
Daily Trend header O
```

and keeps row-local:

```text
O_row = D
```

No second independent consumer was identified with the same semantic contract as the remaining Daily Trend local frontier `L` path.

Therefore:

```text
no second same-contract consumer
  -> no shared temporal-kernel extraction authorization
```

Duplicate-looking date code is insufficient evidence.

## Closure rationale

Keeping the campaign open would currently require one of these unsupported moves:

- treating every remaining `L` as wrong because it remains,
- converting `vm.as_of` to `O` without a consumer problem,
- converting `vm.as_of` to `D` despite distinct meaning,
- inventing `K`,
- deleting the reserve branch from branch existence alone,
- treating the historical PR #107 fixture as current reachability,
- extracting a shared kernel without a second same-contract consumer.

None is justified by current evidence.

The campaign has already produced finite product alignment:

- selected current-source coordinate replay,
- row-local planned future income,
- explicit row-membership ownership,
- explicit-empty identity fallback alignment,
- report observation ownership for the human header,
- explicit neutral `report_today` carrier,
- Outlook override isolation,
- structured JSON clock independence.

That is sufficient to close the major campaign.

## Independent later candidates

These are not active work and do not authorize implementation.

### Candidate A: VM frontier metadata cleanup

Revisit only if evidence appears that:

- a real consumer depends on `vm.as_of`,
- the field causes API confusion or product drift,
- or a separate maintenance problem justifies removal/renaming.

Do not preselect `O`, `D`, `ctx.as_of`, or `K` as replacement.

### Candidate B: empty-identity reserve branch reachability / cleanup

Revisit only if:

- a valid current source state is shown to reach `pid = ""`,
- a concrete product effect is reproduced,
- or a separately justified code-hygiene slice proves safe removal.

Do not use branch existence or the historical explicit-empty fixture as sufficient evidence.

### Candidate C: shared temporal kernel

Revisit only if a second independent consumer demonstrates the same temporal contract and shared extraction reduces real duplication without collapsing meanings.

## Reopen criteria

Reopen a Daily Trend temporal workstream only from a finite evidence-backed question such as:

```text
reachable valid source state
  -> remaining L path
  -> concrete user-visible wrong meaning
```

or:

```text
second independent consumer
  -> same temporal contract
  -> demonstrated shared-kernel value
```

Do not reopen merely because a grep still finds `as_of`, `L`, or a historical branch.

## Final closure statement

```text
Major Daily Trend temporal semantics campaign: CLOSED

Residual questions:
  independent later candidates

Current unresolved product problem backed by evidence:
  none identified in this review

Runtime change authorized by this review:
  none
```
