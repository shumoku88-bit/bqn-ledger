# TODO

このファイルは次の4種類だけを置く場所です。

1. **Active work** — 現在進行中または次に終わらせる有限作業
2. **Next candidates** — まだ着手を決めていない小さな候補
3. **Continuous maintenance** — 終了させない基礎保守ループ
4. **Hold / later** — 具体的必要が出るまで保留するもの

完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避します。

Last hygiene pass: 2026-07-09 — Stage 2 post-implementation contract verification completed; active work narrowed to the downstream `BuildPeriodView` proof-boundary decision.

---

## Active work

### Currency Awareness Stage 2 downstream proof-boundary decision

Current baseline:
- PR #132 `feat: implement Stage 2 minimal domain proof runtime` has been merged into `main`
- post-implementation claim-to-evidence verification is `docs/archive/audits/CURRENCY_STAGE2_POST_IMPLEMENTATION_CONTRACT_VERIFICATION-2026-07-09.md`
- the audit found the core Stage 2 proof -> carrier -> gate chain substantially aligned with the selected decision and plan
- the normal `BuildContext` path authorizes proof before row construction and reaches `BuildPeriodView` only with gated rows
- `BuildPeriodView` remains exported with shape `BuildPeriodView ⟨rows, resolved, cy⟩` and does not receive or validate arithmetic currency proof
- `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md` describes the runtime slice implemented by PR #132; use it as a verification baseline, not as fresh authorization for broader work
- broad FX implementation remains out of scope

Current selected smallest next finite slice:
- docs-only decide whether exported `BuildPeriodView` is:
  - A. an intentional trusted post-gate function whose caller contract requires already-authorized rows
  - B. an enforced downstream boundary that must carry or require proof
  - C. a surface whose public export should be narrowed behind a checked path
- select meaning only; do not implement the selected option in the same slice
- keep Stage 3 / explicit row `currency=` / FX out of scope

導線:
- `docs/archive/audits/CURRENCY_STAGE2_POST_IMPLEMENTATION_CONTRACT_VERIFICATION-2026-07-09.md`
- `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md`
- `docs/CURRENT_CURRENCY_ASSUMPTION_MAP.md`
- `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`
- `docs/CURRENCY_STAGE2_SINGLE_CURRENCY_DOMAIN_DECISION.md`
- `docs/CURRENCY_STAGE2_MINIMAL_DOMAIN_PROOF_IMPLEMENTATION_PLAN.md`
- `docs/ENGINEERING_ROADMAP.md`
- `docs/JOURNAL_META.md`
- `docs/POSTING_IR_CONTRACT.md`

Boundary:
- docs-only decision in this slice
- no runtime / tests / fixture / source TSV changes
- no automatic proof argument / carrier / API change
- no Stage 3 authorization
- no explicit `currency=` admitted-row support / per-row multi-currency support
- no `base_amount=` / `BASE_CURRENCY` / TBDS axis auto-implementation
- no live FX API / automatic conversion / valuation semantics

Daily Trend temporal semantics の major campaign は closure review により終了しました。

導線:
- `docs/archive/audits/DAILY_TREND_TEMPORAL_CAMPAIGN_CLOSURE_REVIEW-2026-07-08.md`

---

## Next candidates

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

- [ ] `vm.as_of = L` は、実 consumer / API confusion / product drift の concrete evidence が出た場合だけ独立再検討する
- [ ] empty-identity reserve branch は、valid current source reachability または具体的 product effect が示された場合だけ再検討する
- [ ] shared temporal kernel は、同じ temporal contract を持つ second independent consumer が確認された場合だけ再検討する
- [ ] `L -> O` / `L -> D` / `L -> K` を自動変換しない

### Temporal execution coverage snapshot

Status: 保留。以前の plan temporal-status × envelope-coverage work とは別候補。

- [ ] old “Slice B” wording を自動 authorization として扱わない
- [ ] explicit current observation contract の下で derived view がまだ有用な場合だけ再検討する

---

## 作業完了時

- [ ] 可能なら `rtk bash ./tools/check.sh` を実行する
- [ ] 新しい BQN module / check script を追加した場合は `tools/repo-index --baseline` を確認する
- [ ] finite TODO が完了したら短く archive へ移し、このファイルに完了ログを積み上げない
- [ ] continuous maintenance の改善作業が一区切りついたら Review / Learning を残し、lane 自体は閉じない
