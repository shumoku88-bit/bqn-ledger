# Report pipeline performance observation — 2026-08-09

Status: measured observation, not an accepted redesign

## Question

The post-migration architecture audit found that the retained multi-report paths repeatedly cross process and admission boundaries. Static inspection predicted 49 BQN process launches for `tools/report-all` and 50 for `tools/report-cache`.

This observation asks whether that process shape is visible in runtime cost before selecting a batch report owner, cache redesign, or any other performance architecture.

## Measurement identity

- PR: #583 `perf: observe retained report pipeline cost`
- measurement branch head: `2828541fbe217262fb5c4e0de75faa0c2c813c99`
- base main at measurement: `bb99cc8072585850c77e29790be6750724dfe49d`
- GitHub Actions run: `31314863888`
- job: `93248371347`
- runner: GitHub-hosted Ubuntu 24.04 x86_64
- CBQN commit: `b4db324a99d6590d91b9b09bc36847f3254c1543`
- fixture: temporary copy of `fixtures/ledger-facts-phase1-proof`, with the same prior-income proof rows used by `checks/check-report-cache.sh`
- domain/latest: `JPY`, `2026-01-12`
- repetitions: 3
- timer: `/usr/bin/time -p`

The BQN launch count is measured, not inferred: the probe prepends a temporary `bqn` wrapper to `PATH`, counts every invocation, and then execs the real CBQN binary. No production source, report implementation, cache implementation, accounting kernel, or writer path is modified by the probe.

`time -p` reports hundredths of a second here. A displayed `0.00` therefore means below this observation's timer resolution, not zero execution cost.

## Raw observations

| case | real seconds, samples 1–3 | BQN processes per sample |
|---|---:|---:|
| request balances | 0.00, 0.00, 0.00 | 1 |
| route balances | 0.00, 0.00, 0.00 | 1 |
| presentation policy | 0.00, 0.00, 0.00 | 1 |
| destination balances | 0.06, 0.06, 0.06 | 1 |
| full balances report | 0.09, 0.09, 0.10 | 4 |
| destination Daily Flow | 0.07, 0.07, 0.07 | 1 |
| full Daily Flow report | 0.10, 0.10, 0.10 | 4 |
| report-all | 1.32, 1.32, 1.34 | 49 |
| report-cache | 1.36, 1.36, 1.35 | 50 |
| cached balances file read | 0.00, 0.00, 0.00 | 0 |

The measured process counts exactly confirm the prior static call-graph counts for the multi-report paths.

## What the measurement supports

On this runner and fixture, the destination accounting/report work for Daily Flow is only slightly slower than the simple balances destination: approximately `0.07s` versus `0.06s` in these samples.

The complete single-report shell path adds roughly `0.03s` beyond the corresponding destination in the representative balances and Daily Flow cases. That path includes the additional request, route, and presentation BQN processes plus shell/presentation work.

By contrast, `report-all` is about `1.33s` and cache generation about `1.36s`, with extremely stable repeat samples. Those paths launch 49 and 50 BQN processes respectively.

This supports the architectural inference that repeated process/admission lifetime is a material cost in current multi-report generation. It does **not** show one unusually expensive Daily Flow kernel dominating the all-report cost on this proof fixture.

The result therefore strengthens the candidate question already recorded in the post-migration architecture observations:

> Can one multi-report owner retain a single admitted Household observation and apply many purpose-specific pure report compositions without weakening the deliberately narrow single-report path?

That question is now justified by runtime evidence rather than static process counts alone.

## What the measurement does not prove

This is not a local daily-use benchmark and should not be turned into a latency promise.

It does not prove:

- the absolute latency on the user's machine;
- cold filesystem-cache behavior;
- scaling with a large Household history;
- which source admission step dominates destination cost;
- that one eager all-source observation is the correct batch design;
- that the single-report path should be changed;
- that CBQN itself is the dominant cause of the multi-report latency.

The first sample and repeat samples are nearly identical here, but they are not controlled OS cold-cache versus warm-cache experiments.

## Architectural consequence

N2 may advance from “measure before choosing” to “prototype the lifetime boundary before choosing.”

The next useful experiment is not micro-optimization. It is a behavior-preserving batch prototype that:

1. admits reusable current Household/report evidence once;
2. derives the same retained report request set;
3. applies the existing semantic report owners without changing single-report semantics;
4. proves byte-equivalent human output against current `tools/report-all` / cache bodies;
5. measures the prototype under the same probe conditions;
6. is discarded if the reduction in work is small or the ownership story becomes worse.

Only after that experiment should the repository decide whether a batch/current-report owner belongs in production and where that owner lives.
