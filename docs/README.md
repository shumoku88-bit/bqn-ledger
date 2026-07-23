# docs README

Status: current docs router
Owner: docs
Canonical: yes
Exit: keep current while docs are routed from this file; revise when the docs directory layout changes

このディレクトリは、`bqn-ledger` の仕様・設計・運用ルールを置く場所です。

重要: ここでは **現行仕様 / 進行中計画 / 履歴メモ** を分けて扱います。
古いTODOや完了済み計画を、現行仕様として読まないでください。

---

## moko が普段読む場所

普段は全部読まなくてよい。まずこの7つだけを見ます。

1. `TODO.md` - 今やること、次に着手すること
2. `docs/QUALITY_BAR.md` - 判断基準
3. `docs/ARCHITECTURE.md` - 全体構造と責務境界
4. `docs/AI_CODEMAP.md` - コード地図
5. `docs/SAFETY_PROFILE.md` - 壊れた時に止める規格
6. `docs/REAL_DATA_TRIAL_SAFETY.md` - 実データ運用を試す前の安全な観察手順
7. `docs/DOCS_LIFECYCLE_CONTRACT.md` - docs を増やす時の状態分類・正本・退役ルール

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
- Journal source migration: leading ASCII space descriptionの旧`silent_normalization`は [JOURNAL_HEADER_DELIMITER_EXACT_CONSUMPTION_IMPLEMENTATION-2026-07-23.md](archive/completed-plans/JOURNAL_HEADER_DELIMITER_EXACT_CONSUMPTION_IMPLEMENTATION-2026-07-23.md) で修正済み。Stage 1はstatus marker後の必須ASCII SPACEを一文字だけ消費し、残りのdescription payloadをTransaction IRへexactに保存する。[JOURNAL_CONVERTER_LEADING_SPACE_ADMISSION_RELAXATION-2026-07-23.md](archive/completed-plans/JOURNAL_CONVERTER_LEADING_SPACE_ADMISSION_RELAXATION-2026-07-23.md) によりconverterも一文字・複数のleading ASCII SPACEsをexactに保存し、trailing ASCII SPACE/C0/DEL/empty rejectionとmetadata/account用`SafeValue`は維持する。Stage 2Aの16-field shapeは不変。canonical prefix converterとpublic-synthetic suffix reconstruction proofは [JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_COMPLETION-2026-07-22.md](archive/completed-plans/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_COMPLETION-2026-07-22.md) として完了済み。production source truth / report routingはTSV、cutoverはblockedのまま。private conversion / reconstructionは未実施で、現在はno finite Journal slice selected。external-plan prerequisiteは [JOURNAL_EXTERNAL_PLAN_REFERENCE_PROFILE_PREREQUISITE_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_EXTERNAL_PLAN_REFERENCE_PROFILE_PREREQUISITE_PLAN-2026-07-22.md)、metadata prerequisiteは [JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN-2026-07-22.md)、native append editorは [JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN-2026-07-22.md) を参照する
- headless kernel / event projection evolution: [HEADLESS_KERNEL_EVOLUTION_MAP.md](HEADLESS_KERNEL_EVOLUTION_MAP.md) を正本の作業地図とし、現在地は [../TODO.md](../TODO.md)、Phase B の選択済み契約は [PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md](PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md)、point-in-time evidence は [archive/audits/HEADLESS_KERNEL_AND_EVENT_PROJECTION_BOUNDARY_AUDIT-2026-07-11.md](archive/audits/HEADLESS_KERNEL_AND_EVENT_PROJECTION_BOUNDARY_AUDIT-2026-07-11.md) を読む
- レポート section 変更: [REPORT_CONTRACTS.md](REPORT_CONTRACTS.md), [REPORT_SECTION_CONTRACT_CHECKLIST.md](REPORT_SECTION_CONTRACT_CHECKLIST.md)。numeric owner alignment の選定済み計画は [REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md](archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md)、最新のDaily Trend runtime完了記録は [DAILY_TREND_PLAN_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md](archive/completed-plans/DAILY_TREND_PLAN_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md)。temporal semantics は [TIME_AS_AXIS.md](TIME_AS_AXIS.md) を正本とし、Daily Trend は [DAILY_TREND_TEMPORAL_CURRENT.md](DAILY_TREND_TEMPORAL_CURRENT.md)、Outlook は [OUTLOOK_TEMPORAL_CURRENT.md](OUTLOOK_TEMPORAL_CURRENT.md) をcurrent entryとして読む
- Daily Capacity / Outlook policy calculation: [DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md](DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md) を純粋runtime契約、[DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md](DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md) をtest-only assembler契約、`src_next/daily_capacity.bqn` を未接続の計算seam、[DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md](archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md) をadapter所有権の最新audit evidence、[OUTLOOK_TEMPORAL_CURRENT.md](OUTLOOK_TEMPORAL_CURRENT.md) を現在の時間境界、[TIME_AS_AXIS.md](TIME_AS_AXIS.md) を時間の正本として読む。adapter runtime、config、metadata、output migrationは [../TODO.md](../TODO.md) で別途選定する
- 封筒予算 / backing policy / execution envelope: [ENVELOPE_ROLE_DESIGN.md](ENVELOPE_ROLE_DESIGN.md), [ENVELOPE_FUNDING_BASE_INVARIANT.md](ENVELOPE_FUNDING_BASE_INVARIANT.md), [ENVELOPE_EXECUTION_AND_PLAN_POLICY.md](ENVELOPE_EXECUTION_AND_PLAN_POLICY.md), [ENVELOPE_ADJUSTMENT_ROW_POLICY.md](ENVELOPE_ADJUSTMENT_ROW_POLICY.md), [ENVELOPE_CYCLE_SEED_POLICY.md](ENVELOPE_CYCLE_SEED_POLICY.md), [ENVELOPE_BUDGET_POOL_METADATA_POLICY.md](ENVELOPE_BUDGET_POOL_METADATA_POLICY.md)。Journalでのresolved envelope assignment永続化の完了記録は [JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN-2026-07-22.md)。確認付き event linkage の実装記録は [ENVELOPE_EVENT_LINKAGE_AUTOMATION_PLAN-2026-07-14.md](archive/completed-plans/ENVELOPE_EVENT_LINKAGE_AUTOMATION_PLAN-2026-07-14.md) と [INCOME_BUDGET_LINKAGE_COMPLETION-2026-07-14.md](archive/completed-plans/INCOME_BUDGET_LINKAGE_COMPLETION-2026-07-14.md) を参照する
- source TSV / メタデータ変更: [CONVENTIONS.md](CONVENTIONS.md), [JOURNAL_META.md](JOURNAL_META.md), [DATA_DIR_SETUP.md](DATA_DIR_SETUP.md)
- currency awareness planning: [CURRENCY_AWARENESS_CAMPAIGN_MAP.md](CURRENCY_AWARENESS_CAMPAIGN_MAP.md), [CURRENT_CURRENCY_ASSUMPTION_MAP.md](CURRENT_CURRENCY_ASSUMPTION_MAP.md), [CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md](CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md), [CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md](CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md), [CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md](CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md), [CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md](CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md), [CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_ADMISSION_DECISION.md](CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_ADMISSION_DECISION.md), [CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md](CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md), [CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md](CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md), [CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md](archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md), [STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md](archive/active-plans/STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md), [FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md](archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md), [FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md](archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md), [ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md](archive/completed-plans/ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md), [ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md](archive/completed-plans/ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md)（Stage 2をsingle-currency exact foundation、mixed-ledger backlogをM1〜M3検証済みのconsumer history、strict-source decisionを独立したproduction/compatibility boundary、friend-travel planをconsumer semantics、atomic designをparked candidate 6 / future recovery proposal、Israel daily-capture planとpredeparture completionをcompleted recordsとして読む。現在のfinite selectionはTODOを正とし、candidate 6、production use、strict-source Steps 2〜5、M4は自動選定しない）
- editor / 日常入力: [PRODUCTION_EDITOR_DIRECTION.md](PRODUCTION_EDITOR_DIRECTION.md) を現行のownership policy、[BQN_EDITOR_USAGE.md](BQN_EDITOR_USAGE.md) を利用手順、[EDIT_BQN_DISPATCHER.md](EDIT_BQN_DISPATCHER.md) をdispatcher実装の補助資料として読み、必要に応じて [ISRAEL_TRAVEL_EDITOR_USAGE.md](ISRAEL_TRAVEL_EDITOR_USAGE.md), [ADD_UI_USAGE.md](ADD_UI_USAGE.md), [MCP_RECEIPT_ENTRY.md](MCP_RECEIPT_ENTRY.md), [PLAN_ID_LIFECYCLE.md](PLAN_ID_LIFECYCLE.md), [UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md](UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md) を足す
- UI / structured export 境界: [STRUCTURED_UI_EXPORT_CONTRACT.md](STRUCTURED_UI_EXPORT_CONTRACT.md), [PLANNED_SECTION_JSON_EXPORT_DESIGN.md](PLANNED_SECTION_JSON_EXPORT_DESIGN.md), [SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md](SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md), [ENVELOPES_SECTION_JSON_EXPORT_DESIGN.md](ENVELOPES_SECTION_JSON_EXPORT_DESIGN.md), [archive/active-plans/SHELL_MEANING_INVENTORY-2026-07-01.md](archive/active-plans/SHELL_MEANING_INVENTORY-2026-07-01.md)
- safety / fail closed: [SAFETY_PROFILE.md](SAFETY_PROFILE.md), [SAFETY_PROFILE_INVARIANT_MAP.md](SAFETY_PROFILE_INVARIANT_MAP.md), [UNAVAILABLE_SENTINEL_CONTRACT.md](UNAVAILABLE_SENTINEL_CONTRACT.md), [REAL_DATA_TRIAL_SAFETY.md](REAL_DATA_TRIAL_SAFETY.md)
- runtime / development dependencies: [THIRD_PARTY_DEPENDENCIES.md](THIRD_PARTY_DEPENDENCIES.md) を現行inventoryとして読む
- 今後の改善候補: [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md), [AUDIT_IMPROVEMENT_BACKLOG.md](AUDIT_IMPROVEMENT_BACKLOG.md), [FINTECH_ENGINEERING_REVIEW_BACKLOG.md](FINTECH_ENGINEERING_REVIEW_BACKLOG.md), [EXTENSION_BOUNDARY.md](EXTENSION_BOUNDARY.md), [PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md](PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md)
- AI作業品質・トークン効率の改善: [AI_WORKING_FEEDBACK_PROCESS.md](AI_WORKING_FEEDBACK_PROCESS.md) を先に読み、[AI_WORKING_FEEDBACK_LOG.md](archive/active-plans/AI_WORKING_FEEDBACK_LOG.md) を intake、[AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md](archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md) を review snapshot として扱う
- 設定可能なAI協働型家計簿・レポート基盤: [CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md](archive/active-plans/CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md) を統合routing mapとして読む。Israel readinessを先に、PR #219 built-in currency policy統合とfoundation synthesisを完了済みの土台として、config/privacy/read-only consultationを後続候補、PR #211 Observatoryを最後に置く。実装権限は常に [../TODO.md](../TODO.md) のfinite sliceを正とする
- docs を増やす/退役させる/正本を決める作業: [DOCS_LIFECYCLE_CONTRACT.md](DOCS_LIFECYCLE_CONTRACT.md) を読み、`Status` / `Owner` / `Canonical` / `Exit` を先に決める

迷ったら [../TODO.md](../TODO.md) と [AI_CODEMAP.md](AI_CODEMAP.md) に戻ります。

---

## テーマ別ルーティング（正本）

この表は「この話題なら、まずこの正本を読む」ためのルーティングです。補助文書や archive を読む前に、ここで current path を確認します。

| テーマ | まず読む正本 | 補助 / 注意 |
|---|---|---|
| 今やること | [../TODO.md](../TODO.md) | 完了ログは TODO に溜めない。 |
| 全体構造・コード地図 | [AI_CODEMAP.md](AI_CODEMAP.md), [ARCHITECTURE.md](ARCHITECTURE.md) | pit はまず AI_CODEMAP。 |
| headless kernel / event projections | [HEADLESS_KERNEL_EVOLUTION_MAP.md](HEADLESS_KERNEL_EVOLUTION_MAP.md), [PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md](PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md) | 現在の有限スライスは [../TODO.md](../TODO.md)。Phase B contract は runtime implementation ではない。監査は evidence であり自動実装指示ではない。 |
| 品質判断 | [QUALITY_BAR.md](QUALITY_BAR.md) | 一般向けではなく personal production-grade。 |
| safety / fail closed | [SAFETY_PROFILE.md](SAFETY_PROFILE.md), [SAFETY_PROFILE_INVARIANT_MAP.md](SAFETY_PROFILE_INVARIANT_MAP.md) | 実データ試行は [REAL_DATA_TRIAL_SAFETY.md](REAL_DATA_TRIAL_SAFETY.md)。 |
| source TSV / メタデータ | [CONVENTIONS.md](CONVENTIONS.md), [JOURNAL_META.md](JOURNAL_META.md), [DATA_DIR_SETUP.md](DATA_DIR_SETUP.md) | source TSV は正データ。 |
| currency awareness | [CURRENCY_AWARENESS_CAMPAIGN_MAP.md](CURRENCY_AWARENESS_CAMPAIGN_MAP.md), [CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md](CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md), [CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md](CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md), [CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md](CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md), [CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md](CURRENCY_STAGE2_BUILDPERIODVIEW_DOWNSTREAM_BOUNDARY_DECISION.md), [CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_ADMISSION_DECISION.md](CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_ADMISSION_DECISION.md), [CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md](CURRENCY_STAGE2_EXPLICIT_SINGLE_CURRENCY_EXACT_DECIMAL_IMPLEMENTATION_PLAN.md), [CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md](CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md), [CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md](archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md), [STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md](archive/active-plans/STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md), [FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md](archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md), [FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md](archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md), [ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md](archive/completed-plans/ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md), [ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md](archive/completed-plans/ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md), [CURRENT_CURRENCY_ASSUMPTION_MAP.md](CURRENT_CURRENCY_ASSUMPTION_MAP.md) | Stage 2 docs are the single-currency exact foundation. M1 through M3 are implemented and separately verified. The Israel semantic and predeparture capture plans are completed records; current finite selection remains in `TODO.md`. The friend-travel atomic recovery design remains parked as candidate 6. Production use, strict-source Steps 2–5, and M4 are not automatically selected. Existing Stage 2 decisions remain current. |
| src_next report engine | [SRC_NEXT_CURRENT.md](SRC_NEXT_CURRENT.md), [REPORT_CONTRACTS.md](REPORT_CONTRACTS.md) | Numeric-owner alignment is selected as a gated sequence in [archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md](archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md). Temporal section semantics route through [DAILY_TREND_TEMPORAL_CURRENT.md](DAILY_TREND_TEMPORAL_CURRENT.md) and [OUTLOOK_TEMPORAL_CURRENT.md](OUTLOOK_TEMPORAL_CURRENT.md). |
| Daily Trend temporal semantics | [TIME_AS_AXIS.md](TIME_AS_AXIS.md), [DAILY_TREND_TEMPORAL_CURRENT.md](DAILY_TREND_TEMPORAL_CURRENT.md) | Exact current dependencies remain in [DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md](DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md); detailed implemented decisions are history, not mandatory entry docs. |
| Outlook temporal semantics | [TIME_AS_AXIS.md](TIME_AS_AXIS.md), [OUTLOOK_TEMPORAL_CURRENT.md](OUTLOOK_TEMPORAL_CURRENT.md) | `--outlook-as-of` is Outlook-specific; detailed household-question, transport, frontier, and production-source decisions are implementation history. |
| Daily Capacity policy calculation | [DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md](DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md), [DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md](DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md), [OUTLOOK_TEMPORAL_CURRENT.md](OUTLOOK_TEMPORAL_CURRENT.md) | Pure calculator and test-only assembler characterization are unconnected. Latest ownership evidence: [adapter pre-implementation audit](archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md). Adapter runtime, config, metadata, report, JSON, and compatibility migration remain separately selectable. |
| 会計 core contracts | [CANONICAL_DAILY_CUBE.md](CANONICAL_DAILY_CUBE.md), [POSTING_IR_CONTRACT.md](POSTING_IR_CONTRACT.md), [TBDS_CONTRACT.md](TBDS_CONTRACT.md), [TIME_AS_AXIS.md](TIME_AS_AXIS.md) | 数字の意味を変える時に読む。 |
| Journal source migration | [../TODO.md](../TODO.md), [JOURNAL_CONVERTER_LEADING_SPACE_ADMISSION_RELAXATION-2026-07-23.md](archive/completed-plans/JOURNAL_CONVERTER_LEADING_SPACE_ADMISSION_RELAXATION-2026-07-23.md), [JOURNAL_HEADER_DELIMITER_EXACT_CONSUMPTION_IMPLEMENTATION-2026-07-23.md](archive/completed-plans/JOURNAL_HEADER_DELIMITER_EXACT_CONSUMPTION_IMPLEMENTATION-2026-07-23.md), [JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_COMPLETION-2026-07-22.md](archive/completed-plans/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_COMPLETION-2026-07-22.md), [JOURNAL_EXTERNAL_PLAN_REFERENCE_PROFILE_PREREQUISITE_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_EXTERNAL_PLAN_REFERENCE_PROFILE_PREREQUISITE_PLAN-2026-07-22.md), [JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_LEGACY_METADATA_PROFILE_EXTENSION_PLAN-2026-07-22.md) | Status: Stage 1 exact delimiter consumption and converter leading-space exact preservation completed. Empty/trailing-space/control rejection, metadata/account `SafeValue`, and Stage 2A shape remain unchanged; no finite Journal slice selected. Production routing/source truth remain TSV, private operations were not performed, and cutover remains blocked. |
| 封筒予算 | [archive/completed-plans/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN-2026-07-22.md](archive/completed-plans/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN-2026-07-22.md), [ENVELOPE_ROLE_DESIGN.md](ENVELOPE_ROLE_DESIGN.md), [ENVELOPE_FUNDING_BASE_INVARIANT.md](ENVELOPE_FUNDING_BASE_INVARIANT.md), [ENVELOPE_EXECUTION_AND_PLAN_POLICY.md](ENVELOPE_EXECUTION_AND_PLAN_POLICY.md) | resolved assignmentの履歴安定性はtest-only完了。runtime運用細部は adjustment / seed / budget_pool policy を参照。 |
| editor / 日常入力 | [PRODUCTION_EDITOR_DIRECTION.md](PRODUCTION_EDITOR_DIRECTION.md), [BQN_EDITOR_USAGE.md](BQN_EDITOR_USAGE.md) | ownership policyは `PRODUCTION_EDITOR_DIRECTION.md`、利用手順は `BQN_EDITOR_USAGE.md`。dispatcherの実装詳細は [EDIT_BQN_DISPATCHER.md](EDIT_BQN_DISPATCHER.md) を補助として読む。MCP receipt pathは既存BQN editorへ委譲し、Go editor関連はhistorical。 |
| UI / structured export | [STRUCTURED_UI_EXPORT_CONTRACT.md](STRUCTURED_UI_EXPORT_CONTRACT.md) | section JSON docs は対象 section の補助設計。 |
| runtime / development dependencies | [THIRD_PARTY_DEPENDENCIES.md](THIRD_PARTY_DEPENDENCIES.md) | CBQN、Bash、optional UI、MCP dependencyの現行inventory。README、CI、lockfileと同期する。 |
| AI 開発品質・トークン効率 | [AI_WORKING_FEEDBACK_PROCESS.md](AI_WORKING_FEEDBACK_PROCESS.md) | intake は [archive/active-plans/AI_WORKING_FEEDBACK_LOG.md](archive/active-plans/AI_WORKING_FEEDBACK_LOG.md)。classification は audit snapshot。 |
| 設定可能なAI協働型家計簿・レポート基盤 | [archive/active-plans/CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md](archive/active-plans/CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md) | PR #219 currency policyとfoundation synthesisは完了済み。privacy-safe contextとread-only consultationは未選定の後続候補、PR #211 Observatoryは最後に接続する。現在のauthorizationは [../TODO.md](../TODO.md)。 |
| docs lifecycle / docs hygiene | [DOCS_LIFECYCLE_CONTRACT.md](DOCS_LIFECYCLE_CONTRACT.md) | 新規 docs は `Status` / `Owner` / `Canonical` / `Exit` を先に決める。 |
| 今後の広い改善候補 | [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md), [AUDIT_IMPROVEMENT_BACKLOG.md](AUDIT_IMPROVEMENT_BACKLOG.md), [FINTECH_ENGINEERING_REVIEW_BACKLOG.md](FINTECH_ENGINEERING_REVIEW_BACKLOG.md) | backlog は実装指示ではない。小さい slice に切る。 |

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
- [DOCS_LIFECYCLE_CONTRACT.md](DOCS_LIFECYCLE_CONTRACT.md)
  - docs の `Status` / `Owner` / `Canonical` / `Exit`、正本/補助/履歴の分離、退役条件を定める現行 docs policy。
- [EXTENSION_BOUNDARY.md](EXTENSION_BOUNDARY.md)
  - Canonical engine を plugin 化せず、machine export 下流の read-only adapter を許す拡張境界。
- [PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md](PUBLIC_PRODUCTIZATION_REVIEW_FILTER.md)
  - Homebrew、CI/CD、packaging、Docker、公開OSS化、plugin、marketing 等の広い改善提案を現在の設計境界で分類する review filter。
- [PRODUCTION_EDITOR_DIRECTION.md](PRODUCTION_EDITOR_DIRECTION.md)
  - BQN editorのproduction write-path ownershipと責務境界を定める現行policy。
- [BQN_EDITOR_USAGE.md](BQN_EDITOR_USAGE.md)
  - BQN 製 source TSV editor (`tools/edit` / `tools/edit-bqn`) と `tools/add-ui.sh` の使い方。[EDIT_BQN_DISPATCHER.md](EDIT_BQN_DISPATCHER.md) はdispatcher実装の補助資料。
- [CONVENTIONS.md](CONVENTIONS.md)
  - 勘定科目の命名、TSVスキーマ、メタデータ定義などの規約。
- [JOURNAL_META.md](JOURNAL_META.md)
  - `journal.tsv` / `plan.tsv` で使用できるメタデータの一覧。
- [MAINTENANCE.md](MAINTENANCE.md)
  - データのバックアップやメンテナンス手順。
- [THIRD_PARTY_DEPENDENCIES.md](THIRD_PARTY_DEPENDENCIES.md)
  - runtime / development dependency、optional UI、MCP dependency、CBQN reproducibilityの現行inventory。
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
- [DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md](DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md)
  - owner-selected asset / obligation scopes、cycle horizon、single-currency arithmetic、per-obligation reservation provenance、deficit resultと、未接続の純粋runtime seamを定める現行契約。adapterとoutput migrationは別途選定する。
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
