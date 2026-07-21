# TODO

このファイルは次の4種類だけを置く場所です。

1. **Active work** — 現在進行中または次に終わらせる有限作業
2. **Next candidates** — まだ着手を決めていない小さな候補
3. **Continuous maintenance** — 終了させない基礎保守ループ
4. **Hold / later** — 具体的必要が出るまで保留するもの

完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避します。

Last hygiene pass: 2026-07-19
- journal migration architecture and source identity decision complete
- Minimal BQN Journal Profile Stage 0 characterization complete
- test-only Minimal BQN Journal parser Stage 1 complete
- Journal Posting IR adapter parity Stage 2A success path complete
- loader/util ownership normalization complete
- Outlook checked numeric-owner Slices A/B complete
- Outlook human envelope purpose split complete (life groups keep `/day`; reserve groups show remaining only)
- Daily Trend plan numeric-owner migration complete
- Cycle Summary remaining-plan characterization complete
- Cycle Summary remaining-plan compatibility decision complete
- Cycle Summary remaining-plan runtime migration complete
- receivable bookkeeping matrix study Stage 1 research complete (test-only research fixture; not a production feature)
- payable bookkeeping matrix study Stage 2 research complete (test-only research fixture; not a production feature)
- prepaid insurance bookkeeping matrix study Stage 3 research complete (test-only research fixture; not a production feature)
- unearned maintenance revenue bookkeeping matrix study Stage 4 research complete (test-only research fixture; not a production feature)
- the initial four-direction bookkeeping matrix set is complete: receivable, payable, prepaid expense, and unearned revenue
- Journal Posting IR identity/provenance parity Stage 2B test-only implementation complete
- Journal Posting IR comparable rejection parity Stage 2C test-only implementation complete
- Journal native three-posting semantic-coordinate parity test-only implementation complete
- Journal read-path trial-balance rehearsal test-only implementation complete
- no next finite Journal, report, or bookkeeping study slice is selected
- envelope allocation / execution-plan coverage characterization remains an unselected candidate
- other unrelated candidates remain unselected

---

## Active work

The latest AI working feedback record was completed by PR #227 and is an evidence input only; it is not an automatic implementation queue.

### Configurable AI-assisted household ledger and report

Status: selected highest-priority development direction. The docs-only foundation synthesis, PR #219 dependency, and config ownership inventory are complete; no next program slice is selected.

Purpose: keep human-readable TSV and configuration as source truth; make user-specific currencies, accounts, life cycles, classifications, budget policy, presentation, and privacy boundaries configurable when they truly belong to configuration; let BQN generate evidence-bearing derived data and reports; and keep AI as an explanatory/proposal partner whose accepted changes pass through human judgment and the existing safe editor.

Completed foundation slices:

- **Configurable AI-assisted ledger foundation synthesis**. Current routing map: `docs/archive/active-plans/CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md`.
- **Config ownership inventory**. Completion record: `docs/archive/completed-plans/CONFIG_OWNERSHIP_INVENTORY-2026-07-14.md`.
- **USD registry-backed exact decimal support**. Exact decimal parsing and validation for journal, plan, and budget, and plan edit/finish lifecycle are complete.

Routing order after readiness and the completed feedback evidence:

1. PR #219 built-in currency policy integration — completed and recorded in `docs/archive/TODO_HISTORY-2026-07-13.md`;
2. foundation synthesis docs — completed by PR #228;
3. config ownership inventory — completed by `docs/archive/completed-plans/CONFIG_OWNERSHIP_INVENTORY-2026-07-14.md`;
4. privacy-safe AI context-bundle contract;
5. one read-only AI consultation report;
6. safe proposal-to-editor handoff;
7. PR #211 Ledger Observatory synthetic evidence-trace connection last.

Rows 4–7 are routing candidates only and no next program slice is selected. Feedback entries do not authorize work. Candidate 6, strict-source Steps 2–5, M4, Projection Workbench, Currency axis, FX/valuation, automatic advice/TODOs/writes, and private production-data access remain unselected. Report projection alignment is separately selected below; it does not authorize unrelated broad report rewrites.

### Report projection alignment

Status: selected report-engine direction. Actual Comparison, Outlook Slices A/B, Daily Trend, and Cycle Summary remaining-plan numeric-owner runtime migrations are complete. **Envelope allocation and execution-plan coverage characterization is also complete.** Records: `docs/archive/completed-plans/CYCLE_REMAINING_PLAN_NUMERIC_OWNER_CHARACTERIZATION-2026-07-16.md`, `docs/archive/completed-plans/CYCLE_REMAINING_PLAN_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-17.md`, `docs/archive/completed-plans/CYCLE_REMAINING_PLAN_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-17.md`, and `docs/archive/completed-plans/ENVELOPE_ALLOCATION_AND_EXECUTION_PLAN_COVERAGE_CHARACTERIZATION-2026-07-17.md`. **No next finite report slice is selected.**

Purpose: move eligible report numeric calculations from independent source re-parsing to checked Posting IR, Cube, or TBDS while preserving source-evidence paths for plan identity, memo, completion, and temporal semantics.

- The Cube remains `Day × Account × Layer`; this is not a request to add metadata axes or force every section onto the Cube.
- Ordered targets are `actual-comparison`, `outlook` / `actual_snapshot`, `daily-trend`, then `envelopes` / cycle remaining-plan calculation.
- Actual Comparison now exposes `BuildAt ⟨ctx,O⟩`; explicit `O` is the hard cutoff, current/baseline amounts come from checked Posting IR through local TBDS period views, and counts/anchors/diagnostics use separated posting source identity evidence.
- Applicable rejected actual evidence fails Actual Comparison closed as `error`; missing previous anchor or an empty current window is `unavailable`; runtime vocabulary is `ok / unavailable / error` and numeric rows are absent for error/unavailable.
- Outlook Slice A derives cumulative inclusive-O actual balances from checked Posting IR through a local TBDS view; applicable rejected actual evidence fails closed.
- Outlook Slice B derives remaining-plan money from admitted plan Posting IR, retains plan-ID completion evidence, reserves valid anchored outflows when unmet, admits valid anchored inflows only after matching actual income through O, and treats applicable invalid anchor evidence as `error`.
- Daily Trend keeps current-source coordinate replay (`O_row = D`): fixed reserve money comes from admitted `plan.tsv` Posting IR joined by `source_row`, while plan ID and row-local completion remain source evidence. Applicable rejected, missing, or structurally unjoinable plan evidence fails the section closed; existing `overlap.PlanId` fallback and exact-any-match completion behavior remain unchanged.
- Cycle Summary excludes completed plans, preserves `O <= D < C.end_exclusive`, derives remaining expense money from admitted `plan.tsv` Posting IR joined by `source_row`, and fails the whole section closed on applicable invalid, rejected, missing, or structurally unjoinable plan evidence.
- Cycle Summary machine/human output exposes state/reason/source-row diagnostics and emits no normal numeric or breakdown rows on error; empty plan and no-actual cases remain valid `ok` results.
- Envelope allocation and coverage characterizations are complete.
- Envelope runtime compatibility decision, completion-aware Cube modification, linkage filter implementation, and fail-closed migration are parked / unselected.
- Journal migration architecture and source identity decision is complete; record: `docs/archive/completed-plans/JOURNAL_MIGRATION_ARCHITECTURE_AND_SOURCE_IDENTITY_DECISION-2026-07-18.md`.
- Minimal BQN Journal Profile Stage 0 characterization is complete; record: `docs/archive/completed-plans/MINIMAL_BQN_JOURNAL_PROFILE_STAGE0_CHARACTERIZATION-2026-07-18.md`.
- Test-only Minimal BQN Journal parser Stage 1 is complete; record: `docs/archive/completed-plans/MINIMAL_BQN_JOURNAL_PARSER_STAGE1-2026-07-18.md`.
- `tools/to-hledger` remains a generated one-way compatibility projection while TSV is source truth; it is not the future parser or writer.
- Journal Posting IR adapter parity Stage 2A success path is complete; record: `docs/archive/completed-plans/JOURNAL_POSTING_IR_ADAPTER_PARITY_STAGE2A_PLAN-2026-07-18.md`.
- Journal Posting IR identity/provenance parity Stage 2B is complete as a pure test-only carrier; record: `docs/archive/completed-plans/JOURNAL_POSTING_IR_IDENTITY_PROVENANCE_PARITY_STAGE2B_PLAN-2026-07-19.md`.
- Journal Posting IR comparable rejection parity Stage 2C is complete as public-synthetic test-only evidence; record: `docs/archive/completed-plans/JOURNAL_POSTING_IR_COMPARABLE_REJECTION_PARITY_STAGE2C_PLAN-2026-07-19.md`.
- Stage 2C covers only invalid date, invalid exact-integer amount, and unknown account, with structural rejection parity and no diagnostic-code equality or production normalization.
- Journal native three-posting semantic-coordinate parity is complete as public-synthetic test-only evidence; record: `docs/archive/completed-plans/JOURNAL_NATIVE_THREE_POSTING_SEMANTIC_COORDINATE_PARITY_PLAN-2026-07-19.md`.
- The focused proof preserves native Journal 3-row versus legacy TSV 4-row topology while matching `(date, account_key, layer_name) -> sum(delta)` and numeric Cube payload.
- Journal read-path trial-balance rehearsal is complete as public-synthetic test-only evidence; record: `docs/archive/completed-plans/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md`.
- The focused test proves `Parse -> Stage 2A -> BuildPeriodView -> trial_balance.Build` with three Journal-derived Posting IR rows and a zero-sum actual-layer Trial Balance, without production routing.
- No next finite Journal slice is selected.
- Broader rejection/red-path parity, production routing, writer work, shadow read, conversion, cutover, and any later Journal stage remain unselected.
- PR #273 remains parked background design evidence, not implementation authorization.
- production journal parser routing, writer, production conversion, and source-of-truth migration are unselected.
- Do not infer helper renaming, generic temporal kernel, report-wide `--as-of`, source TSV migration, Daily Capacity connection, envelope/cycle policy expansion, or automatic write.

### Journal source migration

Status: selected architecture direction. The docs-only architecture/source-identity decision, Minimal BQN Journal Profile Stage 0 characterization, test-only parser Stage 1, Posting IR adapter parity Stage 2A success path, identity/provenance parity Stage 2B, comparable rejection parity Stage 2C, native three-posting semantic-coordinate parity, Journal read-path trial-balance rehearsal, and Journal read-path report-context rehearsal are complete. **No next finite Journal slice is selected.** Production parser routing, writer, conversion, shadow-read activation, source-of-truth implementation, and broader rejection parity remain unselected.

Purpose: preserve the current safe TSV daily path while defining a future native journal source that enters through Transaction IR and checked Posting IR rather than being flattened back into `from / to / amount` rows.

- Current source truth remains `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, and `accounts.tsv`.
- The owner-confirmed automatic TSV-to-journal sync and `tools/to-hledger` are compatibility projection and shadow-read evidence.
- The future target boundary is `journal text -> Transaction IR -> checked Posting IR -> Cube / TBDS -> reports`.
- Current A-1 `txn_id` grouping remains the TSV-era compatibility policy; it is not a permanent prohibition on native journal transaction blocks.
- Future identity separates semantic `source_event_id` from physical source spans; posting identity is deterministic within each event.
- Stage 0 distinguishes compact human input from explicit durable source: ordinary actuals may omit `event-id`, while plans, allocations, stable editing, and durable references require explicit identity; durable postings remain explicit.
- Stage 0 adds a public synthetic `event x account` matrix characterization so row balance, layer masks, and account-column reduction remain first-class BQN/accounting evidence.
- Stage 1 parses only that public supported subset into a test-only Transaction IR, preserves ordered postings and links, fails closed for covered invalid evidence, and reproduces the expected signed matrix.
- The first four independent bookkeeping matrix studies are complete: receivable, payable, prepaid expense, and unearned revenue.
- Stage 1 and the bookkeeping studies are not connected to production source loading, the editor, reports, private data, conversion, or cutover.
- Existing `source_row` joins remain legacy compatibility surfaces and must migrate consumer by consumer before cutover.
- Migration must remain one-directional. Do not create dual daily writes, reverse sync, or an automatic conflict resolver.
- A future cutover must freeze an immutable final TSV snapshot and switch writers once, after parity and recovery gates.
- Journal Posting IR adapter parity Stage 2A success path is complete as bounded test-only work.
- Stage 2B completed structural identity/provenance invariant parity with a separate test-only carrier while preserving the current 16-field Posting IR row and legacy `source_row` compatibility surface. It did not select Stage 2 as a whole or any production connection.
- Stage 2C completed test-only structural rejection parity for invalid date, invalid exact-integer amount, and unknown account without a production helper or connection. It did not select a broader parser red-path campaign.
- The completed three-posting slice compares `(date, account_key, layer_name) -> sum(delta)` and numeric Cube coordinates while preserving Journal 3-row versus legacy TSV 4-row topology. It adds no production normalizer, route, writer, shadow read, conversion, cutover, or consumer migration.
- The completed read-path rehearsal reuses that Journal fixture and proves the existing `BuildPeriodView` and Trial Balance builders accept the three Journal-derived rows. It changes no `BuildContext`, source loading, production report, or source truth.
- The completed report-context rehearsal extends the read-path rehearsal by connecting the Journal-derived context to `balances.Build`, proving the generated balance entries exactly match the legacy TSV projection and successful execution of `balances.Format` and `balances.FormatHuman`, with zero production routing or source truth changes.

## Next candidates

### Journal Posting IR adapter parity

- Stage 2A success-path adapter: completed
- Stage 2B identity/provenance parity: completed; record: `docs/archive/completed-plans/JOURNAL_POSTING_IR_IDENTITY_PROVENANCE_PARITY_STAGE2B_PLAN-2026-07-19.md`
- Stage 2C comparable rejection parity: completed; record: `docs/archive/completed-plans/JOURNAL_POSTING_IR_COMPARABLE_REJECTION_PARITY_STAGE2C_PLAN-2026-07-19.md`
- Journal native three-posting semantic-coordinate parity: completed test-only; record: `docs/archive/completed-plans/JOURNAL_NATIVE_THREE_POSTING_SEMANTIC_COORDINATE_PARITY_PLAN-2026-07-19.md`
- completed primary boundary: `(date, account_key, layer_name) -> sum(delta)`; secondary boundary: numeric Cube equality while preserving Journal 3-row / legacy 4-row topology
- Journal read-path trial-balance rehearsal: completed test-only; record: `docs/archive/completed-plans/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md`
- completed path: existing public Journal fixture -> Parse -> Stage 2A -> BuildPeriodView -> actual-layer Trial Balance
- Journal read-path report-context rehearsal: completed test-only; record: `docs/archive/completed-plans/JOURNAL_READ_PATH_REPORT_CONTEXT_REHEARSAL_PLAN-2026-07-21.md`
- completed path: existing public Journal fixture -> Parse -> Stage 2A -> BuildPeriodView -> balances.Build / Format / FormatHuman
- broader red-path/rejection parity: unselected
- production routing, writer work, shadow read, conversion, cutover, and later stages: unselected

### Bookkeeping matrix study extension

Status: unselected research direction. Use public synthetic, hand-checkable evidence only.

- [ ] Select one accounting topic at a time, such as receivables/payables, accruals, depreciation, inventory, adjustments, closing, trial balance, or financial statements.
- [ ] Keep journal evidence, expected event-account matrix, manual accounting explanation, and BQN projection together.
- [ ] Do not turn this direction into a broad accounting-engine rewrite or production feature campaign automatically.

### Daily Capacity evidence adapter characterization

Status: unselected runtime follow-up. The pure seam, 31-case calculation characterization, pre-implementation ownership audit, and test-only assembler characterization are complete. Current contracts/evidence: `docs/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md`, `docs/archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md`, and `docs/archive/completed-plans/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION-2026-07-15.md`.

- [ ] Do not treat the test-only `AssembleDailyCapacityInputFromResolvedEvidence` reference evaluator as a selected production module.
- [ ] A future candidate must separately select either promotion of this pure seam, Candidate B O-bounded account-balance facts, or Candidate C pool/reservation facts; do not combine them.
- [ ] Do not infer owner policy from account names, prefixes, role/type alone, country, income cadence, configured envelope names, or aggregate envelope equality.
- [ ] Do not add config or metadata, access private data, wire Outlook/report output, or migrate `simple` / `conservative` automatically.

### Friend travel atomic finalization writer (Israel candidate 6)

Status: unselected / parked candidate. The pure one-row JPY preview is implemented and independently verified; see `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`.

- [ ] Preserve `docs/archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md` as a reusable parked proposal for atomicity, recovery manifest, backup, rollback, stale-check, and retry design.
- [ ] Do not treat the former synthetic transaction implementation selection as current authorization.
- [ ] Pending friend source-event storage and safe append may be considered first under the Israel travel sequence; they are not selected by this routing change.
- [ ] Production use, strict-source Steps 2–5, and M4 remain independently unselected.

Mixed-ledger daily-use の後続候補とslice境界は `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` を参照する。M3は実装・検証済みで、strict-source Step 1（policy carrier / pure admission core）は完了済み。strict-sourceのSteps 2–5（writer closure、compatibility preparation、production activation、post-implementation verification）とM4は未選定であり、自動選定しない。

### Ledger Observatory long-term program

Status: active long-term direction; no runtime slice selected. Canonical plan: `docs/archive/active-plans/LEDGER_OBSERVATORY_LONG_TERM_PLAN-2026-07-13.md`.

- [ ] 次に選定可能なのは、synthetic inputだけを使う source-row → Posting IR → Cube coordinate evidence trace の docs-only finite design。
- [ ] evidence trace の input/output shape、privacy-safe identity、all-or-nothing rejection、fixture/test boundaryを先に決め、production source read・CLI・report/UI統合は含めない。
- [ ] scenario overlay、Cube Theatre、BQN Ledger Kata、Projection Workbench、新しいAI観測基盤は、この長期計画だけを理由に自動選定しない。
- [ ] Projection Workbenchは、独立した具体consumerが少なくとも2つ完成し、同じprojection contractが実証されるまで開始しない。

### M4: Expense breakdown grouped by meaning and currency

Status: candidate only。Daily-use observationと既存expense/cycle consumer contractの再確認前に実装しない。strict-source decisionまたは将来のstrict runtime completionはM4を自動選定しない。

### `budget_pool=main` metadata

Current baseline:
- docs-only future direction adopted
- current fallback remains valid

- [ ] implementation plan を小さく切る
- [ ] source TSV を先に変更せず、fixture / check / fallback compatibility を先に決める

### Fintech engineering review backlog

導線:
- `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md`
- `docs/archive/active-plans/FINTECH_ENGINEERING_REVIEW_BACKLOG-2026-07-01.md`

- [ ] 候補を一つだけ選び、`adopt-now` / `adopt-later` / `observe` / `reject` を決める
- [ ] 採用する場合も実装へ直行せず、docs-only の小さな設計PRに切り出す
- [ ] 不採用・保留の場合も理由を残し、同じ候補が曖昧なTODOとして戻らないようにする

---

## Continuous maintenance

このセクションは **完了させない** 基礎保守です。
チェック項目は「永久に未完」という意味ではなく、変更や観察シグナルに応じて繰り返し確認する review lane です。

### AI work quality / efficiency / accuracy

目的:
- AI作業の精度を上げる
- token / debug iteration / unnecessary reread を減らす
- failure evidence を見えるようにする
- repo固有の安全境界をAIが誤解しにくくする

Recurring review prompts:
- [ ] AI作業中の摩擦、誤解、無駄な反復、高token消費、debug blind spot を観察する
- [ ] concrete signal が出たら `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` など適切な intake owner に残す
- [ ] 定期的に current repo を再観察し、古い改善案を自動TODOキューとして扱わず再分類する
- [ ] 改善候補は一度に一つを優先し、必要なら docs-only plan → Execution → Review / Learning の小さいループを回す
- [ ] green path は静かに保ち、red path では command / exit code / stdout / stderr など十分な failure evidence が見えるか確認する
- [ ] AI向け導線、repo index、contracts、checks が current architecture を指しているか確認する

### External audit reassessment

目的:
- 外部監査を実装キューではなく、current main と TODO の偏りを点検する観測資料として使う
- 古い ZIP 時点の指摘、current policy、current runtime、daily-use evidence を混同しない
- 有効な指摘だけを小さな finite slice として一件ずつ昇格する

導線:
- `docs/archive/audits/EXTERNAL_STATIC_AUDIT_REASSESSMENT_SOURCE-2026-07-11.md`

Review triggers:
- major finite campaign が閉じた時
- `TODO.md` hygiene pass を行う時
- concrete friction が繰り返された時
- broad refactor / CI / privacy / i18n / observability / release work を検討する時
- moko が再評価を依頼した時

Recurring review prompts:
- [ ] finding を current `main` で再検証し、古い ZIP の状態を current truth として扱わない
- [ ] `confirmed-current` / `policy-choice` / `already-resolved` / `stale` / `unclear-needs-evidence` に再分類する
- [ ] 監査レポートの元の優先順位を TODO へコピーしない
- [ ] concrete consumer / daily-use / maintenance / CI evidence があるか確認する
- [ ] TODO へ昇格する場合も一度に一つの finite candidate に絞る
- [ ] broad campaign や新 infrastructure を、監査提案だけを理由に開始しない

### Documentation currency / lifecycle

導線:
- `docs/DOCS_LIFECYCLE_CONTRACT.md`
- `docs/README.md`
- `docs/archive/active-plans/README.md`

Recurring review prompts:
- [ ] 実装・運用・正本契約と docs の drift を確認する
- [ ] `TODO.md` を完了ログ置き場に戻さない
- [ ] 完了済み plan は archive へ移し、current spec / active plan / historical note を混ぜない
- [ ] `docs/README.md` の canonical routing が現状を指しているか確認する
- [ ] いきなり削除せず、小さな移動・短い stub・導線確認を優先する
- [ ] new / changed docs が lifecycle contract と `checks/check-docs-lifecycle.sh` の期待を満たすか確認する

### Configuration externalization

Current baseline:
- A4 config resolution workstream is `complete enough for now`
- config ownership inventory is complete; it does not authorize key-by-key migration
- remaining config questions are independent future problems, not an automatic key-by-key migration

Recurring review prompts:
- [ ] 新しい生活ルール、日付、分類、policy を BQN コードへ安易にハードコードしない
- [ ] config / metadata / cycle / source schema のどこが semantic owner か先に判断する
- [ ] 新しい設定項目では unknown / missing / duplicate / empty の扱いを設計する
- [ ] 必要な lint / fixture / check を先に設計する
- [ ] role / policy / report 表示設定を増やす場合、実データ TSV を先に変更しない

### Structured output boundary

Current baseline:
- `tools/report --section <key> --format json` entry exists
- JSON output exists for `planned`, `balances`, `snapshot`, and `envelopes`
- shared JSON helper exists in `src_next/json.bqn`
- UI must not parse human report strings

Recurring review prompts:
- [ ] 新しい report section / UI consumer / AI consumer で structured output が必要か判断する
- [ ] human `FormatHuman` と machine output の意味が drift していないか確認する
- [ ] UI が human report text parsing に逆戻りしていないか確認する
- [ ] JSON key / type / nullability / status vocabulary の変更を明示的な contract change として扱う
- [ ] 全セクションJSON化を目的化せず、実際の consumer requirement から小さく追加する

### CI / workflow drift stabilization

Recurring review prompts:
- [ ] workflow / docs / check の変更時は `tools/check.sh` と GitHub Actions の両方を再確認する
- [ ] GitHub Actions workflow に stale Go editor 前提が混ざらないよう `checks/check-workflow-drift.sh` を維持する
- [ ] local green と CI green の差が出たら、環境差を曖昧な再実行で隠さず evidence を残す

### Source TSV safety

Recurring review prompts:
- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` の実データは勝手に変更しない
- [ ] source TSV 契約を変える場合は docs / fixture / check を同じ単位で更新する
- [ ] journal-like TSV の先頭5列を壊さない。拡張は6列目以降の `key=value` で行う
- [ ] readonly projection / diagnostic / export のために source meaning を書き換えない

---

## Hold / later

### Plan completion workflow observation

Status: daily-use observation。broad workflow campaign は開始しない。

Current baseline:
- tactical routing fix merged
- PR #124 で optional actual amount override merged
- PR #125 で explicit CLOSED postcondition guard merged
- current stance: `plan = expectation`, `actual = observed fact`, `process exit 0 != proof that actual append happened`

導線:
- `docs/archive/active-plans/PLAN_COMPLETION_WORKFLOW_DESIGN_INTAKE-2026-07-08.md`
- `tools/plan-finish-replenish-ui.sh`
- `tools/lib/plan-finish-workflow.sh`

Reopen only on concrete evidence:
- [ ] metadata inheritance loss / wrong inheritance が実際に観察された場合
- [ ] actual append success + follow-up failure の recovery confusion が実際に観察された場合
- [ ] next-date suggestion が wrong / unsafe future plan を作る具体例が出た場合
- [ ] responsibility boundary confusion または別の reproducible workflow defect が出た場合

Do not auto-start:
- [ ] broad Plan Completion Workflow Contract
- [ ] metadata inheritance redesign
- [ ] partial failure recovery redesign
- [ ] next-date rule redesign

### Daily Trend residual temporal candidates

Status: 保留。major temporal campaign は closure review で終了。以下は独立候補であり、自動実装しない。

導線:
- `docs/archive/audits/DAILY_TREND_TEMPORAL_CAMPAIGN_CLOSURE_REVIEW-2026-07-08.md`
- `docs/TIME_AS_AXIS.md`
- `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`

- [ ] `vm.as_of = L` は、実 consumer / API confusion / product drift の concrete evidence が出た場合だけ独立再検討する
- [ ] empty-identity reserve branch は、valid current source reachability または具体的 product effect が示された場合だけ独立再検討する
- [ ] shared temporal kernel は、同じ temporal contract を持つ second independent consumer が確認された場合だけ再検討する
- [ ] `L -> O` / `L -> D` / `L -> K` を自動変換しない

### Temporal execution coverage snapshot

Status: 保留。以前の plan temporal-status × envelope-coverage work とは別候補。

- [ ] old “Slice B” wording を自動 authorization として扱わない
