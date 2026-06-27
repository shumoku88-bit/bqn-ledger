# TODO History 2026-06-23

退避日: 2026-06-23

## Canonical engine hardening

- [x] Safety Profile の invariant を既存 check / lint / fixture / report status へ対応づける (Safety Profile invariant mapping)
- [x] section ごとの `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` 方針決定 (`docs/REPORT_SECTION_STATUS_POLICY.md`)
- [x] `check` と `actual-comparison` への section status 初回実装
- [x] `section_status_*` の machine export (`src/reports/exporters/export-section-status.bqn`) と検証 (`checks/check-section-status.sh`)
- [x] cube shape/layer count invariant (不変条件の明確化とテスト追加)
- [x] event-level zero-sum failure fixture with source/line diagnostics を追加する。
- [x] きれいな間違いを防ぐ失敗 fixture を追加する。 (Added unknown-account failure fixture)
- [x] debug / provenance section の必要最小範囲を決める。 (Proposed docs/DEBUG_PROVENANCE_DESIGN.md)
- [x] 外部推論系を使う場合の checker / explainer / consultant 境界を決める。 (`docs/EXTERNAL_REASONING_BOUNDARY.md`)
- [x] cycle-end envelope consultation の docs-only task packet を作る。 (`docs/CYCLE_END_ENVELOPE_CONSULTATION_TASK.md`)

## Docs hygiene status

- [x] `docs/CANONICAL_ENGINE_HARDENING_TODO.md` を active remainder へ圧縮。
- [x] `docs/archive/completed-plans/CANONICAL_ENGINE_HARDENING_COMPLETED_PHASES.md` を作成。
- [x] `docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md` を作成。
- [x] `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_DECISIONS.md` を作成。
- [x] `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md` を作成。
- [x] `docs/STALE_DOCS_STATUS-2026-06-22.md` を最新状態へ同期。
- [x] `docs/DOCS_HYGIENE_AUDIT-2026-06-22.md` を最新状態へ同期。

## Independent design track: multi-posting support

- [x] 本体では A-1 (`txn_id` メタデータによる複数行束ね) を採用する。
- [x] A-2 (`virtual:suspense` 等の中継口座) は、必要になった場合に使える互換的な拡張余地として残す。
- [x] A-3 (片側仕訳 / 1行1posting寄りの構造) は本体に入れず、フォークまたは別リポジトリで研究する。

## Independent design track: Go source TSV editor

- [x] `plan list`, `plan finish`, `journal add`, `budget add`, `plan finish --apply` は実装済み。
- [x] `tools/add-ui.sh` の既定バックエンドは Go editor (`tools/edit`) へ委譲済み。
- [x] source TSV へのあり得る操作は `docs/GO_EDITOR_WRITE_SCOPE_INVENTORY.md` に棚卸し済み。

## Standing / Independent design track: AI development efficiency

- [x] 優先候補: `docs/BQN_CONVENTIONS_FOR_AI.md` を作り、BQNの同質化、Enclose / Disclose、shape、`SplitKeepEmpty` などのAI向け注意点をまとめる。
- [x] 優先候補: AI task packet / handoff template を作り、読む文書、触ってよいファイル、非目標、検査コマンドを短く指定できるようにする。 (`docs/AI_TASK_PACKET_TEMPLATE.md`)
- [x] 優先候補: Output Squeezer (`tools/sqz-report`) を正式化し、key query / `--with-meta` / `--grep` / compact diff の境界を docs 化する。 (`docs/OUTPUT_SQUEEZER_DESIGN.md`)
- [x] 優先候補: BQN REPL / probe / dumper の設計を作り、既存BQN REPLとの違い、source TSVを触らない境界、最小Phaseを固定する。 (`docs/BQN_REPL_AND_DUMPER_DESIGN.md`)
- [x] Phase 1: `tools/bqn-eval` を追加し、小さいBQN式を既存BQN実行系で評価できるようにする。repo module loading / TSV loading / source writes は行わない。

## Safety quarantine / plan completion

- [x] event-level zero-sum failure fixture with source/line diagnostics を追加する。

## Actual comparison / residual replacement

- [x] `residual` main section は削除し、`actual-comparison` を新設済み。
- [x] Plan履行確認は `planned`、互換用 residual export は当面残す。
- [x] Actual comparison は正本値ではなく再生成可能な派生観察TSVとして扱う。
