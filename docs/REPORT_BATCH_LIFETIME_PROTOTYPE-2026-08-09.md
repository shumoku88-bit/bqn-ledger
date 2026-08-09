# Report batch lifetime prototype — 2026-08-09

Status: successful disposable prototype, not an accepted production design

## Question

The measured retained-report baseline showed that `tools/report-all` launches 49 BQN processes and that multi-report time is much larger than an individual report destination. This prototype tests one narrow hypothesis:

> If current request construction is left unchanged, can all twelve human report destinations share one admitted Household lifetime while preserving output exactly?

The prototype deliberately does not redesign the request model, accounting kernels, sections, renderer, cache, editor, writer, or canonical source format.

## Prototype boundary

```text
current_report_profile_cli.bqn
  -> admitted current semantic request rows        1 BQN process
  -> experimental batch destination
       -> Registry                                  loaded once
       -> Actual                                    loaded/admitted once
       -> Plan/Budget policy/Household/Budget       loaded/admitted once
       -> Report presentation policy                loaded/admitted once
       -> existing compose.* per request
       -> existing render.Render per request        1 BQN process
```

Production `tools/report-all` is not changed by this experiment.

## Evidence identity

- PR: #584 `perf: prototype shared report destination lifetime`
- prototype head measured: `43335155f6a1f594a788f838fa1e84b1e2bde264`
- base main: `bb99cc8072585850c77e29790be6750724dfe49d`
- GitHub Actions run: `31315246274`
- job: `93249322447`
- runner: GitHub-hosted Ubuntu 24.04 x86_64, westus3
- CBQN commit: `b4db324a99d6590d91b9b09bc36847f3254c1543`
- fixture: temporary copy of `fixtures/ledger-facts-phase1-proof` with the same prior-income proof context used by the report performance observation
- domain/latest: `JPY`, `2026-01-12`
- repetitions: 3

Actual BQN process counts are measured with the same temporary PATH wrapper used by the baseline performance observation.

## Semantic result

Before any timing comparison, the probe writes complete outputs from:

1. current `tools/report-all`;
2. the two-process batch lifetime prototype.

`cmp` succeeds on the complete files.

Result:

```text
byte_equivalence  ok
```

Therefore every retained human report in this proof context is byte-for-byte identical under the prototype lifetime.

This proves equivalence only for the exercised retained-report proof context. It is strong characterization evidence, not a universal semantic proof for every possible Household source.

## Measured result

| path | real seconds, samples 1–3 | BQN processes per sample |
|---|---:|---:|
| current `report-all` | 1.16, 1.16, 1.16 | 49 |
| batch lifetime prototype | 0.13, 0.13, 0.13 | 2 |

On this runner:

- BQN process launches fall from 49 to 2, about a 96% reduction;
- wall time falls from 1.16s to 0.13s, about an 89% reduction;
- the prototype is about 8.9× faster for the exercised all-report path;
- the improvement occurs without changing an accounting kernel or semantic report composer.

The magnitude is large enough that the shared-lifetime hypothesis is no longer merely a micro-optimization candidate.

## Architectural interpretation

The evidence supports a specific diagnosis for this path:

> the retained all-report architecture pays materially for repeatedly ending process/admission lifetime and reconstructing evidence that can safely remain shared across the current request set.

This does not mean process count alone is the universal performance metric. It means that, for this measured path, changing evidence lifetime while holding semantic composition constant removes most of the observed cost.

The result also clarifies where **not** to optimize first:

- do not rewrite `date_category_flow.bqn` for this performance problem;
- do not weaken exact arithmetic or diagnostics;
- do not cache derived accounting results merely to hide repeated source admission;
- do not change the single-report route solely because the all-report path benefits from batching;
- do not invent a generic application context before the production ownership is defined.

## What should survive into a production design

A production change, if accepted, should preserve the useful distinction discovered by the prototype:

1. current request-set construction remains a semantic owner;
2. single-report execution remains available as a narrow path;
3. a multi-report application owner may retain one admitted Household observation across several existing pure `compose.*` calls;
4. rendering remains the existing pure `render.Render` dispatch;
5. canonical source admission remains strict and fail-closed;
6. the current shell process fan-out should disappear only for the multi-report/cache path that demonstrably benefits from a longer lifetime.

The production owner should not be a copy of this experiment file. The experiment intentionally duplicates dispatch in order to isolate the lifetime hypothesis and remain disposable.

## Remaining design question

The performance question is now substantially answered. The remaining question is ownership:

> What is the smallest production application API that lets a current retained request set share admitted evidence without introducing a universal context object or a second report semantics owner?

A production proposal should answer that question before implementation. It should also prove current report-all output equivalence and retain the existing single-report behavior.
