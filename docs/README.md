# docs README

このディレクトリは、`bqn-ledger` の仕様・設計・運用ルールを置く場所です。

重要: ここでは **現行仕様 / 進行中計画 / 履歴メモ** を分けて扱います。
古いTODOや完了済み計画を、現行仕様として読まないでください。

---

## moko が普段読む場所

普段は全部読まなくてよい。まずこの6つだけを見ます。

1. `TODO.md` - 今やること、次に着手すること
2. `docs/QUALITY_BAR.md` - 判断基準
3. `docs/ARCHITECTURE.md` - 全体構造と責務境界
4. `docs/AI_CODEMAP.md` - コード地図
5. `docs/SAFETY_PROFILE.md` - 壊れた時に止める規格
6. `docs/REAL_DATA_TRIAL_SAFETY.md` - 実データ運用を試す前の安全な観察手順

迷ったら `TODO.md` へ戻ります。過去の長い計画や判断記録は、必要になった時だけ辿ります。

---

## まず読む（pit向け最短ルート）

毎回の入口はこの5つだけでよいです。

1. [AI_CODEMAP.md](AI_CODEMAP.md) - pit向けコード地図、データフロー、触る場所の索引
2. [../TODO.md](../TODO.md) - 現在進行中・次に着手する作業だけ
3. [QUALITY_BAR.md](QUALITY_BAR.md) - production-grade personal tool として扱う品質基準
4. [SRC_NEXT_CURRENT.md](SRC_NEXT_CURRENT.md) - 現在の `src_next` 普段使い入口と旧 migration docs の扱い
5. [ARCHITECTURE.md](ARCHITECTURE.md) - 現行データフローとモジュール責務

その後は作業内容に応じて読むものを足します。

- 会計エンジン / レポート計算: [CANONICAL_DAILY_CUBE.md](CANONICAL_DAILY_CUBE.md), [POSTING_IR_CONTRACT.md](POSTING_IR_CONTRACT.md), [TBDS_CONTRACT.md](TBDS_CONTRACT.md), [TIME_AS_AXIS.md](TIME_AS_AXIS.md)
- レポート section 変更: [REPORT_CONTRACTS.md](REPORT_CONTRACTS.md), [REPORT_SECTION_CONTRACT_CHECKLIST.md](REPORT_SECTION_CONTRACT_CHECKLIST.md)
- 封筒予算 / backing policy / execution envelope: [ENVELOPE_ROLE_DESIGN.md](ENVELOPE_ROLE_DESIGN.md), [ENVELOPE_FUNDING_BASE_INVARIANT.md](ENVELOPE_FUNDING_BASE_INVARIANT.md), [ENVELOPE_EXECUTION_AND_PLAN_POLICY.md](ENVELOPE_EXECUTION_AND_PLAN_POLICY.md), [ENVELOPE_ADJUSTMENT_ROW_POLICY.md](ENVELOPE_ADJUSTMENT_ROW_POLICY.md), [ENVELOPE_CYCLE_SEED_POLICY.md](ENVELOPE_CYCLE_SEED_POLICY.md), [ENVELOPE_BUDGET_POOL_METADATA_POLICY.md](ENVELOPE_BUDGET_POOL_METADATA_POLICY.md)
- source TSV / メタデータ変更: [CONVENTIONS.md](CONVENTIONS.md), [JOURNAL_META.md](JOURNAL_META.md), [DATA_DIR_SETUP.md](DATA_DIR_SETUP.md)
- editor / 日常入力: [BQN_EDITOR_USAGE.md](BQN_EDITOR_USAGE.md), [ADD_UI_USAGE.md](ADD_UI_USAGE.md), [PLAN_ID_LIFECYCLE.md](PLAN_ID_LIFECYCLE.md), [UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md](UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md)
- UI / structured export 境界: [STRUCTURED_UI_EXPORT_CONTRACT.md](STRUCTURED_UI_EXPORT_CONTRACT.md), [PLANNED_SECTION_JSON_EXPORT_DESIGN.md](PLANNED_SECTION_JSON_EXPORT_DESIGN.md), [SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md](SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md), [ENVELOPES_SECTION_JSON_EXPORT_DESIGN.md](ENVELOPES_SECTION_JSON_EXPORT_DESIGN.md), [archive/active-plans/SHELL_MEANING_INVENTORY-2026-07-01.md](archive/active-plans/SHELL_MEANING_INVENTORY-2026-07-01.md)
- safety / fail closed: [SAFETY_PROFILE.md](SAFETY_PROFILE.md), [SAFETY_PROFILE_INVARIANT_MAP.md](SAFETY_PROFILE_INVARIANT_MAP.md), [UNAVAILABLE_SENTINEL_CONTRACT.md](UNAVAILABLE_SENTINEL_CONTRACT.md), [REAL_DATA_TRIAL_SAFETY.md](REAL_DATA_TRIAL_SAFETY.md)
- 今後の改善候補: [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md), [AUDIT_IMPROVEMENT_BACKLOG.md](AUDIT_IMPROVEMENT_BACKLOG.md), [FINTECH_ENGINEERING_REVIEW_BACKLOG.md](FINTECH_ENGINEERING_REVIEW_BACKLOG.md), [EXTENSION_BOUNDARY.md](EXTENSION_BOUNDARY.md), [PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md](PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md)
- AI作業品質・トークン効率の改善: [AI_WORKING_FEEDBACK_PROCESS.md](AI_WORKING_FEEDBACK_PROCESS.md) を先に読み、[AI_WORKING_FEEDBACK_LOG.md](archive/active-plans/AI_WORKING_FEEDBACK_LOG.md) を intake、[AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md](archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md) を review snapshot として扱う

迷ったら [../TODO.md](../TODO.md) と [AI_CODEMAP.md](AI_CODEMAP.md) に戻ります。

---

## Done / Current Baseline (完了済み・現行仕様として機能)

- [QUALITY_BAR.md](QUALITY_BAR.md)
  - production-grade personal tool として扱うための品質基準。
- [SAFETY_PROFILE.md](SAFETY_PROFILE.md) / [SAFETY_PROFILE_INVARIANT_MAP.md](SAFETY_PROFILE_INVARIANT_MAP.md)
  - 予測可能性、fail closed、正データ保護、不変条件の安全規格とその対応表。
- [REAL_DATA_TRIAL_SAFETY.md](REAL_DATA_TRIAL_SAFETY.md)
  - 実データ運用前に sandbox rehearsal、real-data preflight、dry-run、確認付き書き込み、観察ログで小さく試すための現行運用ガイド。
- [AI_WORKING_FEEDBACK_PROCESS.md](AI_WORKING_FEEDBACK_PROCESS.md)
  - AI作業中の摩擦を intake → classification → planning → execution → review へ流し、feedback や classification を勝手な実装指示にしない現行プロセス。
- [EXTENSION_BOUNDARY.md](EXTENSION_BOUNDARY.md)
  - Canonical engine を plugin 化せず、machine export 下流の read-only adapter を許す拡張境界。
- [PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md](PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md)
  - Homebrew、CI/CD、packaging、Docker、公開OSS化、plugin、marketing 等の広い改善提案を現在の設計境界で分類する review filter。
- [BQN_EDITOR_USAGE.md](BQN_EDITOR_USAGE.md)
  - BQN 製 source TSV editor (`tools/edit` / `tools/edit-bqn`) と `tools/add-ui.sh` の使い方。
- [CONVENTIONS.md](CONVENTIONS.md)
  - 勘定科目の命名、TSVスキーマ、メタデータ定義などの規約。
- [JOURNAL_META.md](JOURNAL_META.md)
  - `journal.tsv` / `plan.tsv` で使用できるメタデータの一覧。
- [MAINTENANCE.md](MAINTENANCE.md)
  - データのバックアップやメンテナンス手順。
- [CYCLE.md](CYCLE.md)
  - サイクル集計期間の変更・設定マニュアル。
- [ADD_UI_USAGE.md](ADD_UI_USAGE.md)
  - 日常の取引入力UI (`tools/add-ui.sh`) のマニュアル。
- [SRC_NEXT_CURRENT.md](SRC_NEXT_CURRENT.md)
  - `src_next/` が現在の普段使い report engine であること、`tools/report` / `tools/report-next-summary` / `tools/report-next` の使い分け。
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
  - tag / release note / public checkpoint 前の確認手順。
- [REPORT_CONTRACTS.md](REPORT_CONTRACTS.md)
  - 現行 report contract の入口。古い archived contract をそのまま現行仕様として読まないための境界メモ。
- [STRUCTURED_UI_EXPORT_CONTRACT.md](STRUCTURED_UI_EXPORT_CONTRACT.md)
  - UI が human report 文字列を parse せず、BQN-owned structured export を使うための境界契約。
- [PLANNED_SECTION_JSON_EXPORT_DESIGN.md](PLANNED_SECTION_JSON_EXPORT_DESIGN.md)
  - `planned` section を最初の report section JSON export slice として扱うための docs-only 設計メモ。
- [SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md](SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md)
  - `snapshot` section の JSON export ViewModel スキーマおよび検証方向性を定めた設計メモ。
- [UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md](UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md)
  - `tools/edit plan list --format tsv` の unfinished plan candidate export 契約。
- [ENVELOPE_ROLE_DESIGN.md](ENVELOPE_ROLE_DESIGN.md) / [ENVELOPE_FUNDING_BASE_INVARIANT.md](ENVELOPE_FUNDING_BASE_INVARIANT.md) / [ENVELOPE_EXECUTION_AND_PLAN_POLICY.md](ENVELOPE_EXECUTION_AND_PLAN_POLICY.md)
  - 封筒予算の Dynamic / Execution / Unassigned 分類、hybrid backing policy、予定支払い coverage 診断の現行設計。
- [ENVELOPE_ADJUSTMENT_ROW_POLICY.md](ENVELOPE_ADJUSTMENT_ROW_POLICY.md) / [ENVELOPE_CYCLE_SEED_POLICY.md](ENVELOPE_CYCLE_SEED_POLICY.md) / [ENVELOPE_BUDGET_POOL_METADATA_POLICY.md](ENVELOPE_BUDGET_POOL_METADATA_POLICY.md)
  - adjustment row、cycle seed、将来の `budget_pool=main` metadata に関する運用方針。

---

## 履歴・アーカイブ

不要になった過去のドキュメントや移行期の資料、現在非アクティブな計画書は、すべて [archive/](archive/) ディレクトリに整理・退避されています。

*   **[archive/active-plans/](archive/active-plans/)**: 現在進行中、または待機中(Backlog)の計画書・設計メモ。ディレクトリ内には historical / completed な古いメモも残っているため、まず [archive/active-plans/README.md](archive/active-plans/README.md) の棚卸し表で `active` / `parked` / `historical` を確認します。Goエディタ関連のギャップ解消計画は historical として扱い、現行の書き込み導線は BQN editor (`tools/edit` / `tools/edit-bqn`) を正とします。AI作業品質・トークン効率の気づきは [AI_WORKING_FEEDBACK_LOG.md](archive/active-plans/AI_WORKING_FEEDBACK_LOG.md) に intake として一時収集し、現行フローは [AI_WORKING_FEEDBACK_PROCESS.md](AI_WORKING_FEEDBACK_PROCESS.md) を正とします。
*   **[archive/completed-plans/](archive/completed-plans/)**: 実装完了済みの計画書・意思決定メモ。
*   **[archive/src-next-migration/](archive/src-next-migration/)**: 旧エンジンから `src_next` への移行フェーズに関わる検証・ログ類。現在の入口は [SRC_NEXT_CURRENT.md](SRC_NEXT_CURRENT.md) を正とし、この下の `bqn main.bqn` / default switch / Stage 4b 未開始などの記述は履歴として読む。読み方は [archive/src-next-migration/README.md](archive/src-next-migration/README.md) と [archive/audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md](archive/audits/SRC_NEXT_DOCS_INVENTORY-2026-06-29.md) にまとめる。
*   **[archive/audits/](archive/audits/)**: 過去に実施した一時的な drift 監査や section 監査のワークシート。AI作業摩擦の分類 review snapshot もここへ置き、active implementation plan と分離します。
*   **[archive/handoffs/](archive/handoffs/)**: 過去の開発セッション間ハンドオフファイル。
