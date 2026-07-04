# Golden Assertion Ownership Plan — 2026-07-04

Status: active plan / implementation not yet authorized

## 1. 対象・目的・現在地

この計画は、AI Working Feedback Classification Review の A5 を最初の planning slice として扱います。

Adopted classification item:

- `A5 Golden + exact grep 重複`
- Primary: `D Verification / Test`
- Secondary: `C Architecture / Design`
- Root cause hypothesis: 同一期待値を複数 test surface が所有している
- Systemic direction: assertion ownership policy

Related process:

- `docs/AI_WORKING_FEEDBACK_PROCESS.md`
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md`
- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`

この plan の目的は、golden file と shell check が同じ exact expected values を重複所有している現行箇所を小さく確認し、各 assertion の主所有者を決め、1つの小さい implementation slice に落とすことです。

**この plan 自体は implementation authorization ではありません。**

## 2. Current evidence

Primary target:

- `checks/check-src-next-envelope-computation.sh`
- `fixtures/src-next-envelope-computation/expected/src_next_summary.txt`

Current flow:

1. `tools/report-next-summary` の出力から envelope summary を抽出する。
2. `diff -u "$expected" "$actual_summary"` で golden file と exact comparison する。
3. その直後に `grep -q` で複数の exact key/value lines を再検証する。

現時点で確認できる重複例:

- `src_next_envelope_status: computed`
- `src_next_envelope_allocated: 1000`
- `src_next_envelope_actual_spent: 350`
- `src_next_envelope_remaining: 650`
- `src_next_envelope_unassigned_remaining: ¯1800`
- `src_next_envelope_unassigned_status: OVER_ALLOCATED`
- `src_next_envelope_funding_base: 0`
- `src_next_envelope_allocated_total: 1070`
- `src_next_envelope_cash_backed_unassigned: ¯1070`
- `src_next_envelope_ledger_cash_delta: 730`
- `src_next_envelope_backing_status: OVER_ALLOCATED`
- execution planned fields
- source/provenance lines

これらは golden summary に exact values として存在し、同じ check script 内で exact `grep -q` により再所有されています。

## 3. Root-cause hypothesis

現時点の仮説:

> Exact expected summary values の ownership が golden file と shell assertions に分散しているため、期待値変更時に複数箇所の同期が必要になり、AI の手戻りと fragile failure を増やしている。

ただし、すべての `grep` を削除すればよいとは仮定しません。

Shell check には、golden comparison と異なる責務を持つ assertions が存在する可能性があります。

例:

- forbidden field absence
- unknown role が active total/provenance に漏れないこと
- command wiring
- key existence
- generic format / shape
- human report surface checks

したがって、この plan は「grep を減らす」ではなく「owner を決める」ことを目的とします。

## 4. Ownership hypothesis to validate

### Candidate owner: golden file

Golden file が主所有者候補となるもの:

- machine summary の exact key/value
- exact row ordering
- exact source/provenance rows
- exact sentinel/status values when they are part of the fixture snapshot

### Candidate owner: shell check

Shell check が主所有者候補となるもの:

- command success / non-zero failure
- fixture/expected file existence
- forbidden field absence
- invariant-style negative checks
- golden snapshotでは表現しにくい exclusion boundary
- generic key existence or generic format checks, when independently valuable
- human report assertions not covered by the machine summary golden

この ownership 仮説は implementation 前に確認します。

## 5. Scope

最初の planning / implementation candidate は次だけに限定します。

Primary scope:

- `checks/check-src-next-envelope-computation.sh`
- `fixtures/src-next-envelope-computation/expected/src_next_summary.txt`

Read-only supporting scope:

- `tools/report-next-summary`
- envelope summary generation path needed to understand the check contract
- relevant docs/check registration only if necessary to verify ownership

## 6. Non-goals

この plan では次を行いません。

- 全 repository の golden/check cleanup
- 全 `grep` assertion の棚卸し
- test framework の新設
- check scaffolder の作成
- generic golden framework の再設計
- BQN calculation semantics の変更
- envelope calculation の意味変更
- human report contract の再設計
- config semantics の変更
- source TSV の変更
- expected values 自体の更新を目的化しない
- A4 / 22 / 20 など他 classification item の同時実装

## 7. Required review before implementation

Implementation plan を authorized にする前に、対象 check の assertions を次へ仕分けします。

| Class | Meaning | Expected owner |
|---|---|---|
| exact snapshot assertion | fixture の exact machine output | golden |
| invariant assertion | 値変更に依存しない意味境界 | shell/check または dedicated test |
| negative boundary | 出てはいけないもの、漏れてはいけないもの | shell/check |
| wiring assertion | command/section/export が接続されること | shell/check |
| human surface assertion | human output contract | current human check、今回の scope では原則維持 |
| duplicate exact assertion | golden と同値を再検証 | removal candidate |

各 removal candidate について、削除後も同じ regression が golden diff で検出されることを確認します。

## 8. Candidate implementation slice

Planning 時点の候補:

1. `diff -u "$expected" "$actual_summary"` を machine summary exact values の主所有者として維持する。
2. golden と完全に重複する exact summary `grep -q` を removal candidates として列挙する。
3. negative / exclusion / later-work leakage checks は維持する。
4. human report assertions は今回の scope では原則維持する。
5. generic existence check が必要な場合は、exact value duplication を避ける。

これは candidate slice であり、まだ実装指示ではありません。

## 9. Files that may change in implementation

Expected:

- `checks/check-src-next-envelope-computation.sh`

Only if review proves necessary:

- related test/check documentation
- `docs/archive/active-plans/GOLDEN_ASSERTION_OWNERSHIP_PLAN-2026-07-04.md` for review result/status

Golden file itselfは、ownership変更だけを理由に expected values を変更しません。

## 10. Files that must not change

- real `data/*.tsv`
- `journal.tsv`
- `plan.tsv`
- `budget_alloc.tsv`
- `accounts.tsv`
- BQN computation modules
- config semantics
- unrelated checks
- unrelated golden fixtures
- `TODO.md`, unless moko separately chooses to promote this work there

## 11. Acceptance criteria for the implementation slice

Implementation を行う場合、最低限次を満たします。

1. 対象 check 内の exact machine-summary assertions が ownership class で説明できる。
2. Golden と完全重複する exact assertions は、維持理由がない限り removal candidate として処理される。
3. Negative boundary checks は失われない。
4. Unknown `envelope_role` leakage prevention は失われない。
5. Later-work field leakage prevention は失われない。
6. Human report checks は今回の scope で意図せず弱めない。
7. Envelope calculation semantics は変えない。
8. Expected golden values は ownership cleanup のためだけに変更しない。
9. Targeted check が pass する。
10. 可能なら repository full check が pass する。
11. Diff review で変更が A5 scope に限定されている。

## 12. Recommended checks

Targeted:

```bash
bash checks/check-src-next-envelope-computation.sh
```

Repository-level when available:

```bash
rtk bash ./tools/check.sh
```

Diff review:

```bash
rtk git diff
```

必要に応じて、golden comparison が duplicate exact assertion 削除後も regression を検出することを小さく確認します。

## 13. Review / Learning after implementation

Implementation 後、元の A5 friction に対して次を確認します。

- exact expected value の主所有者が減ったか。
- golden 更新時に shell exact assertion の追随が不要になったか。
- failure diagnosis が悪化していないか。
- shell check が generic/invariant responsibility を保てているか。
- 新しい helper や二重正本を増やしていないか。

推奨 result status:

- `resolved`
- `mitigated`
- `observe-more`
- `rejected`

結果は必要に応じて `AI_WORKING_FEEDBACK_LOG.md` または classification follow-up へ戻します。

## 14. Handoff draft

```text
Read first:
1. docs/AI_WORKING_FEEDBACK_PROCESS.md
2. docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md
3. docs/archive/active-plans/GOLDEN_ASSERTION_OWNERSHIP_PLAN-2026-07-04.md
4. checks/check-src-next-envelope-computation.sh
5. fixtures/src-next-envelope-computation/expected/src_next_summary.txt

Task:
- Review A5 only.
- Classify assertions in checks/check-src-next-envelope-computation.sh by ownership.
- Treat the golden summary as the candidate owner of exact machine-summary values.
- Preserve negative/invariant checks and human output checks unless a specific duplication is proven.
- Do not change BQN calculation semantics, source TSV data, config semantics, or unrelated checks.
- Before implementation, report the exact removal candidates and why each is redundant.
- Implement only after the plan is explicitly authorized.

Verification:
- bash checks/check-src-next-envelope-computation.sh
- rtk bash ./tools/check.sh when available
- rtk git diff
```

## 15. Current decision

A5 is selected as the first process trial because it is:

- based on an observed real friction
- small enough for one narrow slice
- easy to review
- low risk to source data and accounting semantics
- suitable for testing the full intake → classification → planning → execution → review loop

Next step:

> Review this plan and explicitly decide whether to authorize the implementation slice.
