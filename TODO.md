# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。

## Next: プロ級へ詰める（継続）

導線: `docs/ENGINEERING_ROADMAP.md`

### 3つのプロクオリティ宿題（最優先）

- [x] **BQNコード内の日本語表示文字列の完全追放 (Presentationの外部化)**
  - `src_next/` 配下のBQNファイルから、人間向けの日本語表示ラベルや見出し文字を一掃する。
  - 計算エンジン側はデータ射影キーのみを出力し、表示層（`color-filter` 等）で適切な日本語やスタイルを当てる設計にする。
  - 監査台帳: [docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md](docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md)
  - 2026-06-28: first boundary as `config/report_labels.tsv` + `src_next/report_labels.bqn` を追加。
  - 2026-06-28: section titles / table headers も `report_labels.tsv` 経由へ拡張。
  - 2026-06-28: envelope fixture の日本語ラベル/selector 値も `report_labels.tsv` に外出し。
  - 2026-06-28: `src_next` の runtime 日本語表示文字列は外部化完了。docs の日本語は維持する。
- [x] **Prefix Fallback（接頭辞による暗黙の役割推測）の完全廃止**
  - アカウント名（`expenses:`, `income:` 等）による暗黙判定を廃止し、explicit `role=` を厳格に適用する。
  - [docs/archive/completed-plans/ACCOUNT_ROLE_CONTRACT.md](docs/archive/completed-plans/ACCOUNT_ROLE_CONTRACT.md) の契約に準拠。
  - 2026-06-28: `src_next/projection.bqn` の kind inference を explicit role 優先へ移行。
  - 2026-06-28: Prefix fallback を完全に廃止。`projection.bqn` と `readiness_check.bqn` から fallback を除去し、`valid_roles` から空文字 `""` を削除。
  - 2026-06-28: テスト用の fixture 全体に explicit role をマージし、`check-src-next-household-metadata.sh` で `prefix_fallback_total_count == 0` をアサートする Fail-Closed な validation を有効化。
- [ ] **Command Hub（日常操作ランチャー）による安全な導線一元化**
  - 閲覧・追加・修正のCLIインターフェースを1つに統合（`bl` コマンド）。
  - [x] **Phase 1: 閲覧・確認用の軽量ハブを `tools/bl` として実装完了。**
  - [ ] **Phase 2: アクション（仕訳追加・取消など）の既存ツールへのルーティングと安全性の検証。**
  - 設計メモ: [docs/archive/active-plans/COMMAND_HUB_DESIGN.md](docs/archive/active-plans/COMMAND_HUB_DESIGN.md)
  - 表示サブトラック: [docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md](docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md)


### その他保留事項

- [x] TUI (Terminal UI) 開発は一旦凍結（2026-06-28 ユーザー指示）
- lifestyle configuration / report policy externalization の残り整理
- safety / docs hygiene の小さい整合性修正
- 多通貨対応（保留）

---

## Docs hygiene status

Status: **major hygiene pass complete / large originals preserved**

Current docs map:
```text
docs/README.md
docs/archive/completed-plans/DOCS_HYGIENE_AUDIT-2026-06-22.md
docs/archive/completed-plans/STALE_DOCS_STATUS-2026-06-22.md
```

- [x] `docs/GENERALIZATION_TODO.md` を短い active remainder stub に圧縮完了。
- [x] `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` を archive に移動完了。
- [x] `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` を判断完了（必要に応じて stub/archive 化）。

方針:
- docs hygiene のために source TSV や実装コードを触らない。

---

## Active plan: lifestyle configuration

- [x] Prefix fallback をいつ廃止するか決める。（`docs/archive/completed-plans/ACCOUNT_ROLE_CONTRACT.md` に条件を記載、`src_next/household_metadata.bqn` で fallback 使用数を検出可能にし、`fixtures/src-next-missing-role-fallback` を追加済み）
- [ ] 新しい外部設定候補が出たら、生活ポリシー値か計算規則かを分ける。
- [ ] Canonical Daily Cube の shape や Layer 契約を設定化しない。
- [x] 新しい設定項目を増やす場合、未知値・欠損・重複を検査する lint と fixture を先に設計する。（`fixtures/src-next-lint-failures` と `check-src-next-lint.sh` にて、未知値・重複宣言・存在しないアカウントの参照時の Fail-Closed/Warning 挙動を実装済み）

---

## Independent design track: report policy externalization

Design note: `docs/archive/active-plans/REPORT_POLICY_EXTERNALIZATION_PLAN.md`
Audit note: `docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md`
`src_next` household contract: `docs/archive/completed-plans/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`

- [x] 外部宣言を増やす場合は、未知値・欠損・重複を検査する lint と fixture を先に設計する。（`check-src-next-lint.sh` 等にて実装済み）
- [x] docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md — レポートコード内の生活前提・表示用ラベルの棚卸し台帳を作成完了。(2026-06-27)
- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` の実データは勝手に変更しない。
- [ ] `report_sections.tsv` や `account_display.tsv` は、Phase 1/2 の判断と fixture/check 方針が決まるまで作らない。

---

## Independent design track: command hub / daily launcher

Design note: `docs/archive/active-plans/COMMAND_HUB_DESIGN.md`
Presentation subtrack: `docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md`

- [ ] 実装しない。まず名前・範囲・既存toolsとの接続を決める。
- [ ] コマンド名は未決（候補: `bq`, `bk`, `bqk`, `gbk`, `kakei`, `ledger`）。
- [ ] 初期実装するなら shell + gum の薄いランチャー候補。
- [ ] gum/fzf/color は presentation-only とし、plain 出力を canonical に残す。
- [ ] hub自体は source TSV を直接変更しない。
- [ ] 単一 `events.tsv` への統一方針ではない。
- [x] `docs/MAIN_UI_SECTION_PREVIEW_CACHE_ISSUE-2026-06-27.md` — fzf section preview を一時セクションキャッシュで復元する案を追跡する。
