# Docs / Implementation Drift Audit TODO 2026-06-26

Status: planned / docs-only audit
Date: 2026-06-26

## Goal

- docs と実装のズレを洗い出す。
- すぐ直さず、まず drift 台帳を作る。
- source TSV は触らない。
- 実装変更は原則しない。必要になった場合は、監査後の別作業に切り出す。

## Non-goals

- `data/journal.tsv` / `data/plan.tsv` / `data/budget_alloc.tsv` / `data/accounts.tsv` の編集。
- Go editor の書き込み範囲拡大。
- 古い docs の削除。
- 大きい docs 再編。
- 監査中に見つけたズレをその場でまとめて修正すること。

## Output

Primary output:

- `docs/DRIFT_AUDIT-2026-06-26.md`

Drift table format:

| priority | area | doc | implementation | drift | suggested fix |
|---|---|---|---|---|---|

Priority:

- P0: 正データ破壊・誤操作につながる。
- P1: pit が作業を間違える。
- P2: 読者が混乱する。
- P3: archive / hygiene 候補。

---

## Phase 0: baseline

- [x] `rtk git status --short` で作業前状態を確認する。
- [x] `rtk bash ./tools/check.sh` で現行チェックの状態を確認する。
- [x] `sqz ./tools/check.sh` / `rtk ./tools/check.sh` がこの環境では失敗したため baseline issue として記録する。
- [x] 監査中は source TSV を編集しないことを再確認する。

## Phase 1: entry docs audit

対象:

- [ ] `README.md`
- [ ] `AGENTS.md`
- [ ] `TODO.md`
- [ ] `docs/README.md`
- [ ] `docs/AI_CODEMAP.md`
- [ ] `docs/ENGINEERING_ROADMAP.md`

確認:

- [ ] active / completed / historical の分類が正しいか。
- [ ] `src_next` default 化後の説明になっているか。
- [ ] old engine 前提の指示が現役扱いで残っていないか。
- [ ] pit 向け導線が現実の作業順と一致しているか。
- [ ] `docs/README.md` と `TODO.md` の active plan 一覧が食い違っていないか。

## Phase 2: file existence / code map audit

照合対象:

- [ ] `src_next/*.bqn` と `docs/AI_CODEMAP.md`
- [ ] `tools/*` と docs のコマンド説明
- [ ] `checks/*` と `tools/check.sh`
- [ ] `fixtures/*` と docs の fixture 説明
- [ ] `tests/*` と docs / check の説明

確認:

- [ ] docs にあるが存在しない tool/check/module を記録する。
- [ ] 存在するが docs にない重要 tool/check/module を記録する。
- [ ] `tools/check.sh` に接続済みと書かれた check が本当に接続されているか確認する。
- [ ] fixture 追加済みと書かれたものが実在し、check に接続されているか確認する。

## Phase 3: contract docs audit

対象:

- [ ] `docs/ARCHITECTURE.md`
- [ ] `docs/CANONICAL_DAILY_CUBE.md`
- [ ] `docs/POSTING_IR_CONTRACT.md`
- [ ] `docs/TBDS_CONTRACT.md`
- [ ] `docs/PLAN_ID_LIFECYCLE.md`
- [ ] `docs/REPORT_SECTION_STATUS_POLICY.md`
- [ ] `docs/SAFETY_PROFILE.md`
- [ ] `docs/SAFETY_PROFILE_INVARIANT_MAP.md`

確認:

- [ ] Posting IR / Cube / TBDS の説明が実装と一致しているか。
- [ ] cycle が読み込み境界として扱われていないか。
- [ ] `Day × Account × Layer` 契約が実装と一致しているか。
- [ ] fail closed / unavailable / warning の扱いが docs と実装でズレていないか。
- [ ] `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` の状態定義が実装と一致しているか。
- [ ] Safety Profile の invariant map が現在の check / lint / fixture と対応しているか。

## Phase 4: old engine / historical drift audit

検索語句:

- [ ] `report_engine`
- [ ] `main.bqn`
- [ ] `src/core`
- [ ] `src/reports`
- [ ] `src/views`
- [ ] `BuildAt`
- [ ] `256 slot`
- [ ] `256スロット`
- [ ] `old engine`
- [ ] `旧エンジン`

確認:

- [ ] 上記語句が現役 docs に現役仕様として残っていないか確認する。
- [ ] `docs/REPORT_FIELD_MAP.md` が historical として扱われているか。
- [ ] `docs/MAIN_SECTIONS.md` が historical として扱われているか。
- [ ] AGENTS / TODO に旧更新ルールが残っていないか。
- [ ] archive / completed-plan に移す候補を P3 として記録する。

## Phase 5: user command / path audit

対象:

- [ ] `README.md`
- [ ] `docs/GO_EDITOR_USAGE.md`
- [ ] `docs/MAINTENANCE.md`
- [ ] `docs/CONVENTIONS.md`
- [ ] `docs/JOURNAL_META.md`
- [ ] `docs/APPLICATION_FOUNDATION.md`
- [ ] `docs/COMMAND_HUB_DESIGN.md`

確認:

- [ ] `data/*.tsv` パスが正しいか。
- [ ] `tools/report` の説明が実装と一致しているか。
- [ ] `tools/report-next` / `tools/report-next-summary` の扱いが現状と一致しているか。
- [ ] `tools/edit` の説明が実装と一致しているか。
- [ ] `tools/add-ui.sh` / `tools/main-ui.sh` の説明が実装と一致しているか。
- [ ] Go editor の書き込み許可範囲が docs と一致しているか。
- [ ] source TSV を直接触らない原則が docs 間で一貫しているか。

## Phase 6: drift table creation

- [x] `docs/DRIFT_AUDIT-2026-06-26.md` を作る。
- [x] 各ズレを priority / area / doc / implementation / drift / suggested fix で記録する。
- [x] P0/P1 は修正候補を具体化する。
- [x] P2/P3 は docs hygiene としてまとめる。
- [ ] 「実装が正しい」「docs が正しい」「要判断」を分けて記録する。

## Phase 7: fix planning

- [x] P0/P1 だけ先に直す候補を切り出す → `docs/DRIFT_FIX_PLAN-2026-06-26.md`。
- [x] docs-only 修正と check/tool 修正を分ける。
- [x] 大きい docs 整理は別 TODO に分ける。
- [ ] 必要なら `TODO.md` / `docs/README.md` の導線更新を別作業にする。
- [x] source TSV は触らない。

## Suggested commands

Use `rtk` / `sqz` for potentially long output.

```bash
rtk git status --short
rtk bash ./tools/check.sh
find src_next -maxdepth 1 -type f | sort
find checks -maxdepth 1 -type f | sort
find tools -maxdepth 2 -type f | sort
rg "report_engine|main\\.bqn|src/core|src/reports|src/views|BuildAt|256 slot|256スロット|old engine|旧エンジン" README.md AGENTS.md TODO.md docs
rg "check-docs-drift|sqz-report|bqn-eval|repo-index|tools/edit|tools/report" README.md AGENTS.md TODO.md docs
```
