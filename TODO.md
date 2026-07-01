# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。

Last hygiene pass: 2026-07-01 — active-plans 棚卸しを `docs/archive/active-plans/README.md` に追加。contributor docs / report policy externalization の完了ログを `docs/archive/TODO_HISTORY-2026-07-01.md` へ退避。

---

## Now: 次に選ぶ作業

### 最重要: 封筒予算の backing invariant 設計

Status: urgent docs/design before relying on envelope surplus figures.

背景:
- 封筒レポートに `role=budget kind=unassigned` 由来の未割当表示を追加したが、これは **予算台帳上の未配賦額** であり、可用資金（`type=liquid`）で裏付けられた「使ってよい余り」ではない。
- 「封筒レポート通りに使ったら現金が足りない」を防ぐには、プログラム全体で可用資金の定義と封筒予算対象資産を先に決める必要がある。
- 固定費は最初の運用では `budget:固定費` のような封筒へ集約し、予定支出引当との二重計上を避ける案が有力。

次の小さい slice:
- [ ] `docs/BUDGET_BACKING_INVARIANT.md` などで、可用資金 (`type=liquid`) / budget-backed liquid assets / 未割当 / 封筒残高 / 固定費封筒の用語を定義する
- [ ] `未割当(予算台帳)` と `cash-backed surplus` を明確に分け、現状表示を要修正・暫定扱いにする
- [ ] `budget:未割当 + active envelope remaining` が何とバランスすべきかを決める
- [ ] 固定費を封筒に含める方式と、予定支出引当として別枠にする方式の二重計上リスクを整理する
- [ ] 実装に進む前に fixture/check 方針を決める

---

直近の structured UI export 境界整理は main にマージ済み。次は下のどれかを小さく選ぶ。

### 候補 C: TODO / docs hygiene 継続

導線:
- `docs/archive/completed-plans/DOCS_HYGIENE_AUDIT-2026-06-22.md`
- `docs/README.md`

- [ ] `TODO.md` が再び完了ログ置き場になっていないか確認する
- [ ] 完了済み計画は archive へ移し、現行仕様・進行中計画・履歴メモを混ぜない
- [ ] いきなり削除せず、小さな移動・短い stub・導線確認を優先する

### 候補 D: report structured JSON 層の次 slice

導線:
- `docs/STRUCTURED_UI_EXPORT_CONTRACT.md`
- `docs/REPORT_CONTRACTS.md`
- `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`

完了済み境界:
- `tools/report-section-metadata` は TSV default / `--format json` に対応済み。
- `tools/main-ui.sh` は human report 文字列ではなく section metadata export を使う。

次に選ぶなら小さく分ける:
- [ ] `tools/report --section <key> --format json` の入口方針を設計する（いきなり全 section 実装しない）
- [ ] 最初の対象 section を1つ選び、ViewModel JSON の required fields / unavailable 表現 / check 方針を決める
- [ ] JSON helper を `src_next/json.bqn` 等へ共通化するか、metadata 専用のまま保留するか判断する
- [ ] human `FormatHuman` は維持し、UI は human report を parse しない境界を守る

### 候補 E: Fintech engineering review backlog の取捨選択

導線:
- `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md`
- `docs/archive/active-plans/FINTECH_ENGINEERING_REVIEW_BACKLOG-2026-07-01.md`

- [ ] 候補を一つだけ選び、`adopt-now` / `adopt-later` / `observe` / `reject` を決める
- [ ] 採用する場合も実装へ直行せず、docs-only の小さな設計PRに切り出す
- [ ] 不採用・保留の場合も理由を残し、同じ候補が曖昧なTODOとして戻らないようにする

---

## Active guardrails / reminders

### CI / workflow drift stabilization

- [ ] workflow / docs / check の変更時は `tools/check.sh` と GitHub Actions の両方を再確認する
- [ ] GitHub Actions の workflow に stale Go editor 前提が混ざらないよう、`checks/check-workflow-drift.sh` を維持する

### Lifestyle configuration

- [ ] 新しい設定項目を増やす場合、未知値・欠損・重複を検査する lint と fixture を先に設計する
- [ ] 生活上のルールや日付は BQN コード内にハードコードせず、config / metadata / cycle へ追い出す
- [ ] role / policy / report 表示設定を増やす場合、実データ TSV は先に変更しない

### Source TSV safety

- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` の実データは勝手に変更しない
- [ ] source TSV 契約を変える場合は docs / fixture / check を同じ単位で更新する
- [ ] journal-like TSV の先頭5列を壊さない。拡張は6列目以降の `key=value` で行う

---

## Hold / later

### 多通貨対応

Status: 保留。必要性が具体化してから設計する。

導線: `docs/ENGINEERING_ROADMAP.md` の「多通貨・為替」。

- [ ] Phase A に入る前に schema / Posting IR / TBDS への影響を設計する
- [ ] `currency=` / `base_amount=` などのメタデータを増やす場合は `config/meta_schema.tsv` と `docs/JOURNAL_META.md` を先に更新する

---

## 作業完了時

- [ ] 可能なら `rtk bash ./tools/check.sh` を実行する
- [ ] 新しい BQN module / check script を追加した場合は `tools/repo-index --baseline` を確認する
- [ ] 完了済み TODO は短く archive へ移し、このファイルには「今やること」だけを残す
