# Docs / Implementation Drift Follow-up TODO 2026-06-26

Status: handoff TODO / not started
Source:

- `docs/DRIFT_AUDIT-2026-06-26.md`
- `docs/DRIFT_FIX_PLAN-2026-06-26.md`
- `docs/SAFETY_PROFILE_INVARIANT_MAP.md`

## Goal

Continue after the completed docs/implementation drift fix pass.

Do not edit source TSV unless moko explicitly asks.

## Follow-up TODO

### 1. Add or identify `budget:*` Actual layer zero check ✅ DONE (2026-06-26)

- [x] `checks/check-src-next-budget-actual-zero.sh` created.
- [x] Verifies `src_next/main.bqn` output: no `budget:*` account appears in nonzero actual totals.
- [x] Connected to `tools/check.sh`.
- [x] `docs/SAFETY_PROFILE_INVARIANT_MAP.md` updated: `DOC_ONLY/PARTIAL` → `GUARDED`.

### 2. Add or identify direct-clock-reference check ✅ DONE (2026-06-26)

- [x] `checks/check-src-next-clock-boundary.sh` created.
- [x] Verifies only `src_next/date.bqn` reads the system clock; `date.bqn` exports `Today` as the approved entry point.
- [x] Connected to `tools/check.sh`.
- [x] `docs/SAFETY_PROFILE_INVARIANT_MAP.md` updated: `PARTIAL` → `GUARDED`.

### 3. Decide uniform section status strategy for `src_next` ✅ DECIDED (2026-06-26)

**決定: 段階的統一 (Option C)**

- [x] 語彙（OK/WARN/ERROR/SKIPPED/UNAVAILABLE）は `docs/REPORT_SECTION_STATUS_POLICY.md` で固定済み。
- [x] 既存セクションの key/value 出力（`src_next_actual_comparison_status`, `src_next_envelope_status` 等）は当面維持。
- [x] 新セクション追加時、または既存セクションのステータス強化時に統一フォーマット（`section<TAB>status<TAB>message`）を適用する。
- [x] 旧 `section_status_*` レコードは復活しない。

### 4. Decide whether to restore an output squeezer ✅ IMPLEMENTED (2026-06-26)

**決定: 薄い wrapper として復活（`tools/query`）**

- [x] `tools/query` 作成。`tools/report-next-summary` の `src_next_*` machine-readable 出力に対して key 検索・一覧・grep を行う。
- [x] 計算はしない。既存出力のフィルタのみ。
- [x] 用途: pit/AI が1つの値だけ必要なときにフルレポートを走らせる無駄を省く。

```bash
tools/query <base> <key>          # 値だけ返す
tools/query <base> --list          # 全 key=value
tools/query <base> --keys          # 全 key 名のみ
tools/query <base> --grep <pat>    # key 名で grep
```

### 5. Fully refresh repo-index docs for `src_next` ✅ DONE (2026-06-26)

- [x] Replaced stale old-engine examples in `docs/REPO_INDEX_DESIGN.md`.
- [x] Replaced stale old-engine examples in `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md`.
- [x] All examples now reference current `src_next`, `check-src-next-*`, and `tools/repo-index` behavior.

## Suggested validation

For code/check changes:

```bash
rtk bash -lc 'cd editor && go test ./...'
rtk bash ./tools/check.sh
```

For docs-only changes:

```bash
rtk git diff
rg "report_engine|src/reports|lint_cli|check-forecast-zero|check-section-status" docs
```
