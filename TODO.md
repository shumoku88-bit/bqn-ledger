# TODO

このファイルは **現在進行中・次に着手する作業だけ** を置く場所です。
完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避済みです。


## Real-data trial safety observation

- [x] `docs/REAL_DATA_TRIAL_SAFETY.md` を追加し、sandbox rehearsal / real-data preflight / dry-run / 確認付き書き込み / 観察ログの最小手順を定義する
- [x] sandbox rehearsal を1回通す（2026-06-30: `tools/doctor`, `tools/report fixtures/src-next-golden`, `tools/add-ui.sh --check`, sandbox `tools/edit ... --dry-run` 確認）
- [x] 実データで `tools/doctor`, `tools/report`, `tools/add-ui.sh --check` を確認する（2026-06-30: read-only OK。base dir は `../ledger-data/data` 表示のため、本番書き込み前は absolute `LEDGER_DATA_DIR` 推奨）
- [x] 最初の実データ書き込みは `--dry-run` 後、`--yes` なしの確認付き経路で行う（2026-06-30: `real-data-trial-delete-me` 1円、human confirmation、backup 作成、post-check OK。観察後に人間が実データから削除し、report 復帰を確認）
- [x] 数回の sandbox/temp copy 書き込みで、base dir / backup / post-check / report drift を観察する（2026-06-30: temp copy に journal add 3回、backup 3件、post-check OK、report OK）
- [x] 実データの追加観察は廃止する（2026-06-30: 日常入力時の CLI 操作負荷が高いため、観察 TODO としては閉じる。追加の安全策は実際の不具合・要望が出た時に別タスク化する）

## CI / workflow drift stabilization

- [x] GitHub Actions の workflow から Go / editor 前提の残骸が混ざらないように、`checks/check-workflow-drift.sh` を維持する（2026-06-30: workflow drift check に CBQN policy guard を追加し、active docs の stale Go editor 記述を修正）
- [x] CBQN の CI 取得 commit と `docs/CBQN_REPRODUCIBILITY.md` の記述を同期する（2026-06-30: CI は `CBQN_REF: master` を取得し exact commit をログ、docs も master tracking と明記）
- [ ] workflow / docs / check の変更時は `tools/check.sh` と GitHub Actions の両方を再確認する

## Post-merge follow-up: plan finish replenishment helper

PR #24 は merge 済み。smoke check は `tools/check.sh` で合格済み。
残りは実データへ書かずに確認できる範囲を優先し、必要なら fixture / check 化する。

- [x] `tools/plan-finish-replenish-ui.sh` の BQN エディタ環境（BQN_EDITOR=1 / ハイブリッド）での動作確認（2026-06-30: `checks/check-plan-finish-replenish-ui.sh` の preflight を default env / `BQN_EDITOR=1` の両方で確認）
- [x] 補填モード（翌月作成、最新アクティブプラン後への延長）の対話的挙動を sandbox / dry-run 相当で確認する（2026-06-30: expect + temp sandbox で `extend` → `1m` → `series=phone` 継承、journal/plan 追記、post-check OK を確認）
- [x] `series=...` メタデータの継承・生成処理が正常に機能するか確認する（2026-06-30: `meta series` → `plan_id` series → exact fallback の順に統一）
- [x] 関連予定一覧の表示と設計を確認/実装する（2026-06-30: `tools/plan-finish-replenish-ui.sh` で実装）
  - [x] 補充前に、選択した予定と同じ `series` の未消化予定一覧を表示する
  - [x] `series` 判定順序を厳格に守る:
    1. meta の `series=...`
    2. `plan_id=plan-YYYY-MM-DD-<series>` から series 部分を抽出
    3. fallback として `memo`/`from`/`to`/`amount` 完全一致
  - [x] 表示フィールドに `date` / `memo` / `from -> to` / `amount` / `plan_id` を含める
  - [x] `extend` モードの基準日を、関連予定一覧の最新日付にする
  - [x] 関連予定がない場合に `No related active future plans found` と出力する
  - [x] fuzzy な意味推測を行わない
  - [x] source TSV format および plan finish / plan add の低層仕様を変更しない


### 制約

- `tools/add-ui.sh` のインタラクションモデルは変えない
- `tools/edit` の CLI 互換を保持する
- source TSV 契約は変えない
- `tools/edit-bqn` は現在の BQN+shell editor 入口として扱い、安易に巨大 dispatcher 化しない。`journal add` / `budget add` は共通 parsing / BQN command invocation / protocol parsing / safe append 呼び出しを共有する。`issue add` は専用 parser と同じ append protocol を使う。`plan add` 等へ広げる前に、追加の共通境界を設計する。

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

- [x] stale Go docs cleanup: 現行導線を BQN editor / shell safe-write として明記し、Go editor 前提の現行docs記述を historical 扱いへ修正する（2026-06-30）

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
- [x] `issues.tsv` への安全な懸案事項追加は、既存の安全な editor 経路に委譲する。
- [x] gum/fzf/color は presentation-only とし、plain 出力を canonical に残す。
- [x] hub自体は source TSV を直接変更しない。書き込みは既存安全経路へ委譲する。
- [x] 単一 `events.tsv` への統一方針ではない。
- [x] `docs/MAIN_UI_SECTION_PREVIEW_CACHE_ISSUE-2026-06-27.md` — fzf section preview を一時セクションキャッシュで復元する案を追跡する。
