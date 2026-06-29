# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。

## 最優先: Go editor と BQNエディタの挙動統一 & Go 削除

導線: `docs/archive/active-plans/GO_BQN_GAP_ALIGNMENT_PLAN.md`, `docs/EDITOR_GO_REMOVAL_PLAN.md`, `docs/archive/active-plans/EDIT_BQN_HANDOFF.md`

Go editor の安全仕様と完全一致する BQN+shell エディタの実装・検証を行い、日常パスから Go 依存を完全に排除する。

### フェーズ進捗

- [x] **Phase 1: scaffold** — `src_edit/` + 計画文書（PR #19）
- [x] **Phase 2: BQN/Bashエディタ試作** — 8コマンドのプロトタイプ実装完了
- [x] **Phase 3a: 細い append 経路の確立** — `tools/edit-bqn journal add` / `budget add` / `issue add` を本番 `tools/edit` とは別に通す
  - [x] production `tools/edit` は Go fallback のまま維持する
  - [x] Bash dispatcher で Go互換 `journal add` / `budget add` / `issue add` flags を正規化する
  - [x] BQN出力 protocol を2行形式（`OK\tAPPEND\t<target-file>` + TSV payload）に固定する
  - [x] BQN validation error は non-zero exit + `ERROR\t<message>` に統一する
  - [x] `journal.tsv` / `budget_alloc.tsv` / `issues.tsv` への append を `tools/lib/safe-write.sh` 経由（backup / atomic rename / stale detection）で通す
  - [x] まず resulting TSV bytes の parity を見る（`checks/check-edit-bqn-journal-add.sh`）
  - [x] read-only `plan list --format tsv|text` を `tools/edit-bqn` に追加し、Go stdout byte parity と9-field TSV契約を固定（`checks/check-edit-bqn-plan-list.sh`）
  - [x] append-only `plan add` を `tools/edit-bqn` に追加し、plan_id生成/明示ID/negative fail-closed の resulting TSV parity を固定（`checks/check-edit-bqn-plan-add.sh`）
- [x] **Phase 3b: Go/BQN ギャップ解消の設計と実装** — `docs/archive/active-plans/GO_BQN_GAP_ALIGNMENT_PLAN.md`
  - [x] BQN側: `meta_schema.tsv` の動的パース（予定限定メタデータの動的除外）
  - [x] Bash側: SHA256スナップショットによる競合（Stale）検知（`tools/edit-bqn` の narrow path および `plan finish` にて実装）
  - [x] Bash側: 置換時の `oldLine` 一致アサーション primitive（`safe_replace_line_checked` + `checks/check-safe-replace-line.sh`）
  - [x] 実装: `plan finish` コマンドの実装・テスト完了（PR #22 マージ済）
  - [x] オプトイン: `BQN_EDITOR=1` による `tools/add-ui.sh` 経由のオプトイン試験環境サポート（`main` へ適用済）

- [x] **Phase 3c: BQN editor v1 (残りの機能移植と設計)**
  - [x] 設計: `plan edit` / `journal reverse` のための edit plan プロトコルの詳細設計
  - [x] 実装: `journal reverse` コマンドの実装とテスト (`checks/check-edit-bqn-journal-reverse.sh`)
  - [x] 実装: `plan edit` コマンドの実装とテスト (`checks/check-edit-bqn-plan-edit.sh`)

- [ ] **Phase 4: ブラックボックス差分テストの自動化** — `checks/check-editor-parity.sh`
- [ ] **Phase 5: ディスパッチャー正式切替** — `tools/edit` を BQN+Bash 側に切り替え
- [ ] **Phase 6: Goの完全削除** — Goソースコードの削除、および依存関係定義の更新

### 制約

- `tools/add-ui.sh` のインタラクションモデルは変えない
- `tools/edit` の CLI 互換を保持する
- source TSV 契約は変えない
- Phase 5 まで Go editor を fallback として並存させる
- `tools/edit-bqn` は append-only の narrow proof path として扱い、安易に巨大 dispatcher 化しない。`journal add` / `budget add` は共通 parsing / BQN command invocation / protocol parsing / safe append 呼び出しを共有する。`issue add` は専用 parser と同じ append protocol を使う。`plan add` 等へ広げる前に、追加の共通境界を設計する。

---

## Next: プロ級へ詰める（継続）

導線: `docs/ENGINEERING_ROADMAP.md`

### 3つのプロクオリティ宿題（最優先）

- [x] **BQNコード内の日本語表示文字列の外部化**
  - 計算エンジン側はデータ射影キーを出力し、表示層で適切な日本語やスタイルを当てる設計にする。
  - 監査台帳: [docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md](docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md)
  - 2026-06-28: `config/report_labels.tsv` + `src_next/report_labels.bqn` を追加。
  - 2026-06-28: section titles / table headers も `report_labels.tsv` 経由へ拡張。
  - 2026-06-28: envelope fixture の日本語ラベル/selector 値も `report_labels.tsv` に外出し。
  - 2026-06-28: `src_next` の runtime 日本語表示文字列は外部化完了。docs の日本語は維持する。
- [x] **Prefix Fallback（接頭辞による暗黙の役割推測）の廃止**
  - アカウント名（`expenses:`, `income:` 等）による暗黙判定を廃止し、explicit `role=` を厳格に適用する。
  - [docs/archive/completed-plans/ACCOUNT_ROLE_CONTRACT.md](docs/archive/completed-plans/ACCOUNT_ROLE_CONTRACT.md) の契約に準拠。
  - 2026-06-28: `src_next/projection.bqn` の kind inference を explicit role 優先へ移行。
  - 2026-06-28: `projection.bqn` と `readiness_check.bqn` から fallback を除去し、`valid_roles` から空文字 `""` を削除。
  - 2026-06-28: テスト用の fixture 全体に explicit role をマージし、`check-src-next-household-metadata.sh` で `prefix_fallback_total_count == 0` を確認する validation を有効化。
- [x] **Command Hub（日常操作ランチャー）による安全な導線一元化**
  - [x] **Phase 1: 閲覧・確認用の軽量ハブを `tools/bl` として実装完了。**
  - [x] **Phase 2: アクション（仕訳追加・取消など）の既存ツールへのルーティングと、新設した懸案事項（issues.tsv）の対話的・安全な追加コマンドの実装完了。**
  - 設計メモ: [docs/archive/active-plans/COMMAND_HUB_DESIGN.md](docs/archive/active-plans/COMMAND_HUB_DESIGN.md)
  - 表示サブトラック: [docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md](docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md)

### その他保留事項

- [x] Bashスクリプトの実行時クラッシュ防止策の初回対応（`tools/add-ui.sh` の `main()` 化 + dedicated Bash safety check。導線: [docs/archive/active-plans/BASH_SAFETY_ANALYSIS.md](docs/archive/active-plans/BASH_SAFETY_ANALYSIS.md)）
- [x] lifestyle configuration / report policy externalization の残り整理（2026-06-29: `docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md` を現行 remainder audit に更新。`report_sections.tsv` / `account_display.tsv` はまだ作らない判断）
- [x] `report_labels.tsv` の参照キー存在チェック（2026-06-29: `checks/check-report-labels.sh` を追加し `tools/check.sh` に接続）
- [x] future envelope target policy の docs-only sketch（2026-06-29: `docs/archive/active-plans/ENVELOPE_TARGET_POLICY_SKETCH.md` 追加。`envelope_targets.tsv` はまだ作らない）
- [x] shellcheck 警告の棚卸しと台帳作成。CIでの強制は行わず現状のインベントリのみ（2026-06-29: `docs/archive/audits/SHELLCHECK_WARNING_INVENTORY-2026-06-29.md` 追加）
- [x] safety / docs hygiene の整合性修正バッチ完了（2026-06-29: `docs/archive/completed-plans/SAFETY_DOCS_ALIGNMENT_PLAN-2026-06-29.md`）
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
- [x] `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_PLAN.md` へ移動完了。
- [x] `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN.md` を判断完了（最新境界は `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md`）。

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

## Completed track: command hub / daily launcher

Design note: `docs/archive/active-plans/COMMAND_HUB_DESIGN.md`
Presentation subtrack: `docs/archive/active-plans/GUM_FZF_COLOR_LAYER_PLAN.md`

- [x] 初期実装名は `tools/bl` とする。
- [x] `tools/bl` は日常操作ランチャーとして、閲覧、確認、既存編集ツールへのルーティングを担当する。
- [x] `issues.tsv` への安全な懸案事項追加は、既存 Go editor 経路に委譲する。
- [x] gum/fzf/color は presentation-only とし、plain 出力を canonical に残す。
- [x] hub自体は source TSV を直接変更しない。書き込みは既存安全経路へ委譲する。
- [x] 単一 `events.tsv` への統一方針ではない。
- [x] `docs/MAIN_UI_SECTION_PREVIEW_CACHE_ISSUE-2026-06-27.md` — fzf section preview を一時セクションキャッシュで復元する案を追跡する。
