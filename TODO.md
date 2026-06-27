# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。

## Completed: old engine removal

全フェーズ完了。`bqn-ledger` は `src_next` だけの独立プロジェクトに移行済み。
詳細は `docs/OLD_ENGINE_REMOVAL_PLAN.md` を参照。

## Completed: 動的勘定科目空間 (2026-06-26)

`src_next/` は既に完全動的。コード変更不要。docs更新のみ。
詳細は `docs/ENGINEERING_ROADMAP.md` 項目1。

## Completed: Failure Fixtures (2026-06-26)

2 fixture 追加、6 fixture 既存確認。全 `check-src-next-golden.sh` 接続済み。
詳細は `docs/ENGINEERING_ROADMAP.md` 項目6。

- `src-next-missing-budget-mapping/` — budget mapping 欠け
- `src-next-broken-empty-columns/` — 空列保持破損

## Completed: 取消・修正UI (2026-06-26)

`journal reverse` サブコマンド追加。`add-ui.sh` に reverse モード追加。
Go テスト 8件追加。全チェック PASS。
詳細は `docs/ENGINEERING_ROADMAP.md` 項目2。

## Next: プロ級へ詰める（継続）

導線: `docs/ENGINEERING_ROADMAP.md`

現在の優先:

- Household Policy 完成
- lifestyle configuration / report policy externalization の残り整理
- safety / docs hygiene の小さい整合性修正

保留中:

- TUI設計 — 画面・操作導線が大きく、現行エンジン契約がもう少し固まってから再開する。
- 多通貨 — Posting IR / TBDS / 表示 / 設定にまたがるため、当面は単一通貨エンジンの信頼性を優先する。

### Check strictness follow-up

- [x] `tools/check.sh` 内の Go editor test が `|| true` で非 fatal になっている理由を確認する。（過去に修正済み）
- [x] 意図的でないなら、`(cd editor && go test ./...)` を fatal にして、Go editor regressions が全体チェックを落とすようにする。（反映済み）
- [x] Go 未導入環境を考慮する必要があるなら、黙って通すのではなく、明示的な skip / warning / separate check に分離する。（`tools/check.sh` に反映済み）
- [x] 変更した場合は `AGENTS.md` / `docs/QUALITY_BAR.md` / `docs/SAFETY_PROFILE_INVARIANT_MAP.md` のどこに書くべきか確認する。（`docs/SAFETY_PROFILE_INVARIANT_MAP.md` に追記済み）

## Completed: report screen review loop

全11画面 adopted、2画面 rejected。mock review フェーズ完了。
実装は `docs/ENGINEERING_ROADMAP.md` の流れで進める。

- [x] 11 screens adopted: Account Balances, Current Cycle Summary, Actual Comparison, Planned Payments, YTD Summary, Outlook/Daily Amount, Daily Trend, Trial Balance, Recent Journal, Readiness Check, Envelope & Budget
- [x] 2 screens rejected: Balance Summary, Expense Breakdown
- [x] mock review phase complete（docs-only、実装は未着手）

## Completed: src_next accounting-grade engine (Phase A–E + Household Policy Phase 0–4)

全フェーズ完了。`tools/report` が本番 default として稼働中。

- Phase A: TBDS opening/movement/closing gate ✓
- Phase B: ledger-wide context split (BuildAllRows + BuildPeriodView) ✓
- Phase C: Trial Balance / Balance Sheet / Income Statement ✓
- Phase D: accounting reports complete ✓
- Phase E: current engine vs src_next field comparison (38/38 match) ✓
- Household Policy Phase 0–3: boundary doc, assumption audit, policy schema, two-style fixture proof ✓
- Household Policy Phase 4: view toggling & anchor control ✓

## Docs hygiene status

Status: **major hygiene pass complete / large originals preserved**

Current docs map:

```text
docs/README.md
docs/DOCS_HYGIENE_AUDIT-2026-06-22.md
docs/STALE_DOCS_STATUS-2026-06-22.md
```

残り候補:

- [x] `docs/GENERALIZATION_TODO.md` を短い active remainder / historical stub に置き換えるか判断する。
- [x] `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` を全文archiveまたは短い historical stub にするか判断する。
- [x] `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` を全文archiveまたは短い historical stub にするか判断する。

方針:

- 大きい全文置換は GitHub connector 側の安全チェックで止まることがあるため、必要なら Codex / local agent に回す。
- docs hygiene のために source TSV や実装コードを触らない。

## New: 外部監査指摘対応 (2026-06-27)

導線: `docs/EXTERNAL_AUDIT-2026-06-27.md`

外部AIによるプロジェクト監査。優先順序: 公開衛生 → 自動化 → 性能 → 利便性。

高優先度（設計を壊さない・効果大）:

- [x] LICENSE 追加（ルート）
- [x] data/ を fixture/sandbox 化し実データ外出し（moko/data/, .gitignore, config）
  - 実データ → moko/data/ (gitignore)
  - サンドボックス → data/ (fixtures/household-moko の匿名データを採用)
  - moko設定: `export LEDGER_DATA_DIR=moko/data` を shell rc に追加
- [x] editor/editor を削除し .gitignore に追加（editor/, .gitignore）
- [x] GitHub Actions で `tools/check.sh` 自動実行（.github/workflows/check.yml）
- [x] CONTRIBUTING.md とセットアップ節を追加（ルート, docs/）

中優先度:

- [x] BQN 実装・推奨バージョンを明示（README, CONTRIBUTING.md）
- [x] cube.Materialize の疎表現化または grouped accumulation（src_next/cube.bqn:167-187）
  - コメント追加: 家計簿規模では十分高速。大規模化時に grouped accumulation への置換を推奨
- [x] summary.bqn / README / TODO の文言整合化（src_next/summary.bqn, docs）
  - summary.bqn ヘッダ: 旧エンジン参照削除、本番向け表現に更新
- [x] カバレッジ計測導入（Go test, check scripts）
  - tools/coverage: Go 77.8%, BQN 19/31 module tests
  - CI に coverage step 追加

低優先度:

- [x] 依存 SBOM / 実行 doctor コマンド追加（tools/doctor）
  - 依存チェック + engine smoke test + SBOM 表示
- [x] audit follow-up: `LEDGER_DATA_DIR` 既定値の不統一を修正（report/report-next/report-next-summary/envelope-calc/Go editor）
- [x] audit follow-up: `data/` を公開 sandbox、実運用を base directory (`LEDGER_DATA_DIR`) として docs 整合

## Active plan: lifestyle configuration

Current reading path:

```text
docs/GENERALIZATION_TODO.status.md
docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md
docs/GENERALIZATION_TODO.md
```

現在の芯:

- [x] Prefix fallback をいつ廃止するか決める。（`docs/ACCOUNT_ROLE_CONTRACT.md` に条件を記載、`src_next/household_metadata.bqn` で fallback 使用数を検出可能にし、`fixtures/src-next-missing-role-fallback` を追加済み）
- [ ] 新しい外部設定候補が出たら、生活ポリシー値か計算規則かを分ける。
- [ ] Canonical Daily Cube の shape や Layer 契約を設定化しない。
- [x] 新しい設定項目を増やす場合、未知値・欠損・重複を検査する lint と fixture を先に設計する。（`fixtures/src-next-lint-failures` と `check-src-next-lint.sh` にて、未知値・重複宣言・存在しないアカウントの参照時の Fail-Closed/Warning 挙動を実装済み）

## Active plan: ledger engine adoption track（完了）

全項目完了。`src_next` は本番 default として稼働中。

## Independent design track: report policy externalization

Design note: `docs/REPORT_POLICY_EXTERNALIZATION_PLAN.md`
Audit note: `docs/REPORT_ASSUMPTION_AUDIT.md`
`src_next` household contract: `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`

現在の芯:

- [x] 外部宣言を増やす場合は、未知値・欠損・重複を検査する lint と fixture を先に設計する。（`check-src-next-lint.sh` 等にて実装済み）
- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` の実データは勝手に変更しない。
- [ ] `report_sections.tsv` や `account_display.tsv` は、棚卸しが終わるまで作らない。

## Independent design track: command hub / daily launcher

Design note: `docs/COMMAND_HUB_DESIGN.md`

現在の扱い:

- [ ] 実装しない。まず名前・範囲・既存toolsとの接続を決める。
- [ ] コマンド名は未決（候補: `bq`, `bk`, `bqk`, `gbk`, `kakei`, `ledger`）。
- [ ] 初期実装するなら shell + gum の薄いランチャー候補。
- [ ] hub自体は source TSV を直接変更しない。
- [ ] 単一 `events.tsv` への統一方針ではない。
