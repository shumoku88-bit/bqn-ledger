# TODO

## Active design direction: canonical engine hardening

Current plan: `docs/CANONICAL_ENGINE_HARDENING_TODO.md`

- Goal: keep BQN as the canonical numeric engine (秤), not a consultation/decision engine.
- Fixed core: Event IR, Projection IR, Canonical Daily Cube (`Day × Account × Layer`), and its layer contracts.
- Near-term priority: canonical TSV export, canonical formulas, report invariants, and report contracts.
- Do not change current output values unless the difference is intentional, explained, and approved.
- Do not mix consultation arithmetic into canonical output.

## Active design direction: lifestyle configuration

Current plan: `docs/GENERALIZATION_TODO.md`

- Goal: lifestyle changes should normally require TSV configuration changes, not code-wide edits.
- Fixed core: Event IR, Projection IR, Canonical Daily Cube (`Day × Account × Layer`), and its four Layer contracts.
- Configurable policy: account roles, cycle, envelopes, special budget accounts, and mappings into existing projections.
- Different coordinates or meanings use separate projections/views, not extra Daily Cube axes.
- Next scoped task: document the `role=` contract and Prefix fallback, then add one non-Prefix account fixture.
- Do not modify real-data `accounts.tsv` during the contract/fixture phases.

## 2026-06-11 Safety quarantine and redesign

Design: `docs/SAFE_WORKFLOW_REDESIGN.md`

- [x] Replace unsafe `tools/finish.go` with a preview-only command
- [x] Remove `past-cycle` from report dispatch, aliases, list output, and UI
- [x] Reject `--offset` and disabled past-cycle requests explicitly
- [x] Remove the broken runtime zero-sum warning from report generation
- [x] Add a regression check proving disabled features cannot mutate or render
- [ ] Remove dormant past-cycle fields and offset-aware resolver code after quarantine verification
- [ ] Add an event-level zero-sum failure fixture with source/line diagnostics
- [ ] Implement a pure `incomeAnchor` historical-cycle resolver with explicit unavailable state
- [ ] Add historical-cycle boundary and insufficient-history fixtures
- [x] Implement preview-only plan completion with explicit actual date
- [ ] Decide idempotency, recurrence, metadata, concurrency, and recovery contracts
- [ ] Add failure-injection tests before any apply mode is implemented

### Review

- The previous `finish.go` prototype is not safe to execute against real data.
- Historical cycle output must never widen to all history when anchors are missing.
- Runtime report generation is not the correct place for diagnostic warnings that
  can contaminate machine output.
- Re-enable criteria are defined in `docs/SAFE_WORKFLOW_REDESIGN.md`.
- Verification: `./tools/check.sh`, the preview no-mutation fixture, and
  `go vet tools/finish.go` pass.

## Current checkpoint

- [x] `main.bqn` の表示ロジック分割は完了（`report_sections.bqn` へ移動）
- [x] TSV/lint 安全化の山場は完了（空フィールド保持、必須列、date/amount、accounts整合性）
- [x] `tools/lint.bqn` の accounts.tsv 検査を `tools/lint_accounts.bqn` へ内部分割
- [x] `report_engine.bqn` 分割計画を明文化（履歴: `docs/archive/refactor-2026-06/REPORT_ENGINE_SPLIT_PLAN.md`）
- [x] `report_engine.bqn` 分割完了（`report_meta`, `report_readiness`, `report_balances`, `report_cycle_metrics`, `report_outlook`, `report_trend`）
- [x] 配列監査メモを作る（履歴: `docs/archive/refactor-2026-06/ARRAY_AUDIT.md`）
- [x] 内部中間形として `tx_updates : T×256×2` と `tx_meta : T×N` を導入
- [x] `report_tx_updates.bqn` に `BuildDays` を実装（`day_updates`, `day_balances`）
- [x] `tools/check-tx-updates.bqn` / `tools/check-trend-liquid.bqn` で整合性を確認
- [x] `report_trend.bqn` を完全に配列由来（`day_updates`, `day_balances`）に置換
- [x] `budget:*` 科目の Actual 層を `report_tx_updates` 側で一括マスク
- [x] `report_balances.bqn` を集約器としてリファクタリングし、`report_engine.bqn` に統合
- [x] `report_engine.bqn` のデータロード・パース責務を `report_tx_updates.bqn` に一元化
- [x] 全テストパス（`tools/check.sh`）
- [x] `cycle-consult` を `report_cycle_consult.bqn` へ計算・表示ロジック共に切り出し完了
- [x] `tools/lint.bqn` から journal-like 共通バリデーションを `tools/lint_journal_like.bqn` へ分離
- [x] `date` の暦妥当性チェック（閏年対応、存在しない日付の検知）を lint に追加

## 2026-06-09 Canonical Daily Cube 監査対応

進め方: 1タスク=1目的。先に invariant / fixture を足し、必要な実装修正と docs 同期を小さく行う。

- [x] 監査報告を `docs/archive/AUDIT_REPORT-2026-06-09.md` に追加する
- [x] Actual layer から `budget_alloc.tsv` を外し、`budget:*` が cube layer0 に出ない invariant を検査する
- [x] `report_envelope_trend.bqn` の future variable plan 控除を、`accounts.tsv` の `budget=...` projection に合わせて修正する
- [x] `plan.tsv` / `journal.tsv` の `budget:*` 行を lint/strict check で禁止し、docs/test に固定する
- [x] future-only / empty journal / as_of before cube の envelope bootstrap fixture を追加する
- [x] cycle 表示を `start〜end_exclusiveの前日` に統一し、表示 regression check を追加する
- [x] `docs/AI_CODEMAP.md` / `docs/ARCHITECTURE.md` を cube-first にさらに寄せ、`BuildDays` を互換 view と明示する
- [x] `fixtures/basic` を現行 envelope 方針（daily/flex/reserve、固定費封筒外）へ寄せる
- [x] `REPORT_FIELD_MAP` / `MAIN_SECTIONS` の docs drift 検査を検討する

## Event Projection Engine

詳細計画: `docs/EVENT_PROJECTION_PLAN.md`

進め方:

- 1タスク=1目的
- 各Phaseの開始前にmokoと確認する
- 実データTSVは変更しない
- 現行入力・レポート互換を先にfixtureで固定する
- 複雑さが増えた場合は実装を止めて計画へ戻る
- `report_tx_updates.bqn` の `Build` / `BuildDays` などの legacy 互換コードは、テストやエクスポートの互換用に一時的に残す（B. 互換用に一時的に残す）。今後 Phase 6 以降で整理予定。

### 計画レビュー

- [x] 現行`BuildCube`の責務と既存中間形をコードで確認する
- [x] Event IR → Projection IR → Materialize → Accumulateの段階計画を書く
- [x] 現行互換の契約、採用条件、撤回条件を明文化する
- [x] 実装前のTODOをPhase別に作成する

### Phase 0: 現行挙動の固定

- [x] **BQN集約戦略の選定**: `long projection rows -> daily cube` への変換において、`Group` などの高階関数をどう組み合わせるか、読みやすさと性能のバランスを小規模なベンチマークで確認する
- [x] journal / plan / budget allocationの代表Eventからcube deltaまでを追跡するfixtureを決める
- [x] actual / plan / budget / forecastのlayer契約をfixtureで固定する
- [x] `cube_dates`, `cube_ordinals`, `cube_updates`, `cube_balances`の比較方法を決める
- [x] empty / future-only / cycle境界を含めて`./tools/check.sh`が通ることを基準値として記録する

### Phase 1: Event IR

- [x] Event IRのfield contractを文書化する
- [x] journal / plan / budget allocationを共通Event形で読める実験を作る
- [x] 6列目以降のmetaを保持する
- [x] 既存strict validationとfile / line errorを維持する
- [x] Event IRをread-onlyで観察できるcheckまたはexportを作る
### Phase 2: Exact Projection IR

- [x] journal actual projectionを純粋変換として分離する
- [x] journal budget consumption projectionを分離する
- [x] budget allocation projectionを分離する
- [x] plan projectionを分離する
- [x] **Plan合成規則の明文化**: Layer 1 (Plan) が Actual と Intent の和であることを、ソースコード上のマジックナンバーではなく投影契約として定義する
- [x] **時間依存規則の投影化**: `budget_start_dn` による Intent 抑制を、Projection Contract の「フィルター規則」として定義する
- [x] forecast zero projectionの契約を固定する
- [x] 投影結果にsource / line / projection kindを対応づける
- [x] Event単位でaccount軸zero-sumを検査する
- [x] `budget_start_dn`規則を1か所へ集約する
- [x] actualの`budget:*` mask規則を1か所へ集約する


### Phase 3: Daily Materializer

- [x] Projection IRからdense ordinal axisを生成する
- [x] 同一日・account・layerのdeltaを合算する
- [x] empty projectionを`0×256×4`で扱う
- [x] 現行`BuildCube`のdates / ordinals / updatesと完全一致させる
- [x] MaterializerがTSVやFrom / Toを知らないことを確認する

### Phase 4: Accumulator

- [x] daily updatesからdaily balancesを作る関数を分離する
- [x] empty cubeのshapeを固定する
- [x] 現行`cube_balances`と完全一致させる
- [x] `report_engine`以下を変更せず全checkを通す

### Phase 5: 置換判断

- [x] 現行実装と新パイプラインの条件分岐・重複計算を比較する
- [x] 各段階のinput / output shapeを一文で説明できるか確認する
- [x] `BuildCube`を薄いorchestratorへできるか判断する
- [x] 採用条件と撤回条件に基づきmokoと統合可否を決める
- [x] 採用する場合のみ現行`BuildCube`内部を置き換える

### Phase 6: 複数時間projection

- [x] クレジットカード用の最小fixtureを作る
- [x] 通常5列入力から引落予定日をaccount metaで導出する
- [x] `due_on=...`を例外上書きとして試す
- [x] cashflow projectionがactualへ加算されないことを検査する
- [x] 同じEvent IRからdaily exact / cashflow dueを生成する
- [x] 既存Daily Cubeとreportを変更せず新しいviewを追加できることを証明する

### 完了時

- [x] `docs/ARCHITECTURE.md`を実装に同期する
- [x] `docs/AI_CODEMAP.md`を実装に同期する
- [x] `docs/CANONICAL_DAILY_CUBE.md`をmaterialized viewの位置づけへ更新する
- [x] `docs/EVENT_FIRST_PROJECTION_DRAFT_V3.md`の状態を更新する
- [x] `docs/EVENT_PROJECTION_PLAN.md`にレビュー結果を記録する
- [x] `./tools/check.sh`を実行して全検査を通す

## Time as an axis

基幹原則: `docs/TIME_AS_AXIS.md`

- [x] coordinate time、observation time、period viewの責務を文書化する
- [x] `as_of`はEvent日付ではなく観察者時点と明文化する
- [x] cycleをCube軸ではなく時間座標上のwindowと明文化する
- [x] Plan / Envelope / Residual / Scenarioの時間上の位置づけを文書へ同期する
- [x] `system_today`をCube座標ではなく既定`as_of`の外部供給元として文書化する
- [x] `generated_at` / `data_cutoff` / `last_recorded_on` / `horizon_end`の責務候補を分離する
- [x] 主要レポート経路のOS時計取得が`report_engine.Build`の既定`as_of`変換に集約されていることを確認する
- [ ] 各report sectionが`as_of`をどう適用するか一覧化する
- [ ] report系の`dt.Today`直接参照を増やさず、入口で確定した`as_of`を渡す規則を検査可能にする
- [ ] timezone込み`system_now`と`generated_at`が本当に必要になるexport要件を決める
- [ ] `data_cutoff`と`horizon_end`は具体的な入力遅延・予測範囲fixtureができるまで実装しない
- [ ] `last_journal_date`を行末日付のまま扱うか、最大coordinateの`last_recorded_on`へ改めるか決める
- [ ] `as_of`より後のjournal行を含むfixtureを作り、snapshot / YTD / cycle / trendの現行挙動を固定する
- [ ] YTDとcycle集計を`as_of`で切るべきか、全期間確定値として残すべきかをsectionごとに決める
- [ ] `as_of`境界を変更する場合は既存report互換と表示文言をfixtureで確認する
- [ ] `occurred_on / due_on / paid_on / belongs_to_period`の本番契約は具体的ユースケースごとに小さく決める

## Next candidates

行動ブレ観察レポート:
- [x] Plan / Actual / Residual / Scenarioの候補と判断基準を文書化する
- [x] `plan.tsv`とEnvelopeの責務衝突、二重管理リスクを文書化する
- [ ] Plan / Actualの対応単位を比較fixtureで検討する
- [x] 同じActualでEnvelope viewとPlan / Residual viewの役割を比較する
- [x] 日常反復支出をすべてPlan入力しない方針を決める
- [ ] Residualの数式、status、期間終了前後の扱いを決める
- [x] Envelopeを生活管理の主役、Plan / Residualを補助観察とする
- [x] 通院・学習をEnvelope対象とする方針を決める
- [x] 通院は独立Envelope、学習はflex Envelopeとする
- [ ] 通院用の費目名、Envelope名、配賦額を決める
- [ ] ScenarioをCube軸にするか派生long viewにするか決める
- [x] `fixtures/behavior-drift-comparison`を作り、通院独立・学習flex・通院配賦0を固定する
- [x] 同じActualのEnvelope viewとPlan / Residual候補をcheckで比較する
- [ ] Event単位・cycle集計・任意`plan_id`の出力差を比較する
- [ ] Plan / Actual / Residual reportを実装する
- [ ] residual派生TSVを追加する
- [ ] fixtureで必要性を確認した後にbehavior class / Scenario viewを検討する

資金繰り・判断ビュー:
- [x] `outlook` / `envelopes` / `daily-trend` を束ねる `cashflow` モック section を追加する

優先度高め（2026-06-08 監査レポートからのフィードバック対応）:
- [x] ドキュメント同期: `docs/REPORT_FIELD_MAP.md` を実際の63フィールド（`env_*` 含む）に更新する
- [x] ドキュメント同期: `docs/AI_CODEMAP.md` の `cycle-consult` と `report_balances.bqn` の説明を現状の実装に合わせて更新する
- [x] ドキュメント同期: `README.md` の `BuildMatrix` の記述を削除/修正し、`ROADMAP.md` の `export-ledger.bqn` を `.sh` に直す
- [x] 仕様の明文化: `budget_alloc.tsv` と `plan.tsv` の budget move 境界仕様（どちらが正データか）をドキュメントに明示する
- [x] 仕様の明文化: 封筒予測が安全側保証ではなくヒューリスティックであること、`plan.tsv` の事前控除の扱いがセクションごとに異なることを明記する -> 統一済み
- [x] テスト追加: `tools/check.sh` に `main.bqn --section envelopes` の実行を追加する
- [x] テスト追加: `export-ledger.sh` で memo にセミコロン `;` が含まれるケースの検証と対応（エスケープ等） -> 全角に自動変換済み
- [x] テスト追加: `journal.tsv` が空（empty journal bootstrap）の場合の起動テストと方針の明示
- [x] ルール追加: `AGENTS.md` に journal-like TSV 読み込み時の `SplitKeepEmpty` 使用ルール、フィールド変更時のドキュメント更新義務、`export-ledger.sh` の目的の限定（実績の最小exportであること）を追記する

完了済みタスク:
- [x] 封筒の健康診断（枯渇予測）を `report_envelope_trend.bqn` として実装・統合
- [x] 封筒フロー予測の精度向上（特定の支出除外、未来予定の統合など）

余裕があれば:
- [x] lint エラーをさらに複数件まとめて出すか検討する
- [x] 無駄コード候補レポートを検討する（履歴: `docs/archive/DEAD_CODE_REPORT.md`）

## 2026-06-15 Directory Reorganization Phase 1
- [x] engine モジュールを `engine/` ディレクトリへ移動 (declutter root)
- [x] `core.bqn` に `LoadChars` を追加し、相対パス読み込みの基盤を整備

## Next Steps: Data Generalization (Phase 2)
- [ ] TSV ファイル群 (`*.tsv`, `config.tsv`) を `data/` (または `my-ledger/`) ディレクトリへ移動
- [ ] すべてのツール (`tools/*.bqn`) を `--base <dir>` 対応にし、カレントディレクトリへの依存を排除
- [ ] 実データとアプリケーション本体の完全な分離を証明する

## Refactor: ファイル分割計画

完了済み。

## Data integrity / lint

完了済み（Stage 3 統合を含む）。

## Done
- [x] `report_outlook.bqn` を「見通し」サマリ形式に変更
- [x] `accounts.tsv` を `key=value` のメタ情報形式に拡張（`type=...`, `budget=...`）
- [x] 予算レイヤ（`budget:*`）のオンザフライ導出
- [x] 確定申告に耐える `journal.tsv` 拡張余地の確保（6列目以降メタ）
- [x] レポートを目次/セクション単位で表示（`main.bqn --toc/--section`）
- [x] `daily-trend` セクション追加
- [x] `tools/add.bqn` の強化
- [x] 3D配列エンジンの完全統合
- [x] Canonical Daily Cube の不変条件（invariant）修 正（Actual layer の純度向上、Plan layer の budget 包含）
- [x] `report_envelope_trend.bqn` を Cube Layer 1 由来にリファクタリングし、再計算を排除
- [x] `StrictCheck` の強化（`budget:*` 科目の journal/plan 混入を厳格に禁止）
- [x] docs drift の解消（`REPORT_FIELD_MAP.md`）
