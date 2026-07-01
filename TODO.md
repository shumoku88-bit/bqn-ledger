# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。

Last hygiene pass: 2026-07-01 — editor boundary / real-data trial / replenishment follow-up の完了ログを `docs/archive/TODO_HISTORY-2026-07-01.md` へ退避。

---

## Now: 次に選ぶ作業

直近の大きな editor boundary 整理は完了。次は下のどれかを小さく選ぶ。

### 候補 A: Contributor docs / 入口整理

導線: `docs/ENGINEERING_ROADMAP.md` の「コントリビュータ向け文書」。

- [ ] `CONTRIBUTING.md` を repo 直下に作るか判断する
  - セットアップ
  - 最初に読む docs
  - `tools/check.sh` の走らせ方
  - Go は現行 daily path の必須依存ではなく historical code 用であること
- [ ] `docs/README.md` の pit 向け「まず読む」を短くするか判断する
- [ ] `docs/AI_CODEMAP.md` に人間向け補足が必要か確認する

### 候補 B: report policy externalization の残り判断

導線:
- `docs/archive/active-plans/REPORT_POLICY_EXTERNALIZATION_PLAN.md`
- `docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md`
- `docs/archive/completed-plans/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`

- [ ] 現在残っている外部設定候補を再確認する
- [ ] 新しい外部設定候補が出たら、生活ポリシー値か計算規則かを分ける
- [ ] `report_sections.tsv` や `account_display.tsv` は、Phase 1/2 の判断と fixture/check 方針が決まるまで作らない
- [ ] Canonical Daily Cube の shape や Layer 契約は設定化しない

### 候補 C: TODO / docs hygiene 継続

導線:
- `docs/archive/completed-plans/DOCS_HYGIENE_AUDIT-2026-06-22.md`
- `docs/README.md`

- [ ] `TODO.md` が再び完了ログ置き場になっていないか確認する
- [ ] 完了済み計画は archive へ移し、現行仕様・進行中計画・履歴メモを混ぜない
- [ ] いきなり削除せず、小さな移動・短い stub・導線確認を優先する

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
