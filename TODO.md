# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。

## Next: プロ級へ詰める（継続）

導線: `docs/ENGINEERING_ROADMAP.md`

### 3つのプロクオリティ宿題（最優先）

- [ ] **BQNコード内の日本語表示文字列の完全追放 (Presentationの外部化)**
  - `src_next/` 配下のBQNファイルから、人間向けの日本語表示ラベルや見出し文字を一掃する。
  - 計算エンジン側はデータ射影キーのみを出力し、表示層（`color-filter` 等）で適切な日本語やスタイルを当てる設計にする。
  - 監査台帳: [docs/REPORT_ASSUMPTION_AUDIT.md](file:///Users/user/Projects/moko/bqn-ledger/docs/REPORT_ASSUMPTION_AUDIT.md)
- [ ] **Prefix Fallback（接頭辞による暗黙の役割推測）の完全廃止**
  - アカウント名（`expenses:`, `income:` 等）による暗黙判定を廃止し、explicit `role=` を厳格に適用する。
  - [docs/ACCOUNT_ROLE_CONTRACT.md](file:///Users/user/Projects/moko/bqn-ledger/docs/ACCOUNT_ROLE_CONTRACT.md) の契約に準拠。
- [ ] **Command Hub（日常操作ランチャー）による安全な導線一元化**
  - 閲覧・追加・修正のCLIインターフェースを1つに統合（例：`gbk` や `kakei` コマンド等）。
  - エラー時の Fail-Closed や操作ログの安全性をCLIのラッパーレベルで一元保証する。
  - 設計メモ: [docs/COMMAND_HUB_DESIGN.md](file:///Users/user/Projects/moko/bqn-ledger/docs/COMMAND_HUB_DESIGN.md)

### その他保留事項

- lifestyle configuration / report policy externalization の残り整理
- safety / docs hygiene の小さい整合性修正
- 多通貨対応（保留）

---

## Docs hygiene status

Status: **major hygiene pass complete / large originals preserved**

Current docs map:
```text
docs/README.md
docs/DOCS_HYGIENE_AUDIT-2026-06-22.md
docs/STALE_DOCS_STATUS-2026-06-22.md
```

- [x] `docs/GENERALIZATION_TODO.md` を短い active remainder stub に圧縮完了。
- [x] `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` を archive に移動完了。
- [x] `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` を判断完了（必要に応じて stub/archive 化）。

方針:
- docs hygiene のために source TSV や実装コードを触らない。

---

## Active plan: lifestyle configuration

- [x] Prefix fallback をいつ廃止するか決める。（`docs/ACCOUNT_ROLE_CONTRACT.md` に条件を記載、`src_next/household_metadata.bqn` で fallback 使用数を検出可能にし、`fixtures/src-next-missing-role-fallback` を追加済み）
- [ ] 新しい外部設定候補が出たら、生活ポリシー値か計算規則かを分ける。
- [ ] Canonical Daily Cube の shape や Layer 契約を設定化しない。
- [x] 新しい設定項目を増やす場合、未知値・欠損・重複を検査する lint と fixture を先に設計する。（`fixtures/src-next-lint-failures` と `check-src-next-lint.sh` にて、未知値・重複宣言・存在しないアカウントの参照時の Fail-Closed/Warning 挙動を実装済み）

---

## Independent design track: report policy externalization

Design note: `docs/REPORT_POLICY_EXTERNALIZATION_PLAN.md`
Audit note: `docs/REPORT_ASSUMPTION_AUDIT.md`
`src_next` household contract: `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`

- [x] 外部宣言を増やす場合は、未知値・欠損・重複を検査する lint と fixture を先に設計する。（`check-src-next-lint.sh` 等にて実装済み）
- [x] docs/REPORT_ASSUMPTION_AUDIT.md — レポートコード内の生活前提・表示用ラベルの棚卸し台帳を作成完了。(2026-06-27)
- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` の実データは勝手に変更しない。
- [ ] `report_sections.tsv` や `account_display.tsv` は、棚卸しが終わるまで作らない。

---

## Independent design track: command hub / daily launcher

Design note: `docs/COMMAND_HUB_DESIGN.md`

- [ ] 実装しない。まず名前・範囲・既存toolsとの接続を決める。
- [ ] コマンド名は未決（候補: `bq`, `bk`, `bqk`, `gbk`, `kakei`, `ledger`）。
- [ ] 初期実装するなら shell + gum の薄いランチャー候補。
- [ ] hub自体は source TSV を直接変更しない。
- [ ] 単一 `events.tsv` への統一方針ではない。
- [x] `docs/MAIN_UI_SECTION_PREVIEW_CACHE_ISSUE-2026-06-27.md` — fzf section preview を一時セクションキャッシュで復元する案を追跡する。
