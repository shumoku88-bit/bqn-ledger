# AGENTS.md

このリポジトリの開発・保守作業入口です。

新しく clone した利用者の初期導入を支援する AI は、maintainer 向けのこの手順から始めず、まず `docs/AI_ASSISTED_ADOPTION_GUIDE.md` を読んでください。利用者固有の設定と private data は、public repository の保守規則へ混ぜません。

## pit 初回到着時の手順

1. **L1 必読（3ファイル）**: `docs/AI_CODEMAP.md` → `TODO.md` → `docs/QUALITY_BAR.md`
2. `rtk git status` と `TODO.md` で「今何が進行中か」を把握する
3. ユーザーの依頼に応じて、下の「タスク別 L2」から該当項目を読む
4. 作業完了前に `rtk bash ./tools/check.sh` を実行する

## 読み方: 3層構造

| 層 | いつ読む | 内容 |
|---|---------|------|
| **L1 必読** | タスク内容に関わらず毎回 | 全体構造・今の優先順位・品質基準 |
| **L2 タスク別** | やりたいことに応じて選ぶ | 計算・レポート・設定・相談・外装など |
| **L3 参照** | 必要になったときだけ | 安全規格・命名規約・履歴 |

### L1: 必読（全タスク共通）

| # | 読むもの | 内容 |
|---|---------|------|
| 1 | `docs/AI_CODEMAP.md` | データフロー・正データ・コード地図。ここが一番大事 |
| 2 | `TODO.md` | 現在進行中・次に着手する作業だけ |
| 3 | `docs/QUALITY_BAR.md` | 品質基準。「一般向けではないが production-grade」の判断軸 |

### L2: タスク別（依頼の種類に応じて選ぶ）

| 作業の種類 | 読むもの |
|---|---|
| **封筒・予算の計算変更** | `docs/ARCHITECTURE.md`, `docs/CANONICAL_DAILY_CUBE.md` |
| **レポートの出力変更** | `src_next/report.bqn`, 該当 `src_next/*.bqn`, `docs/REPORT_CONTRACTS.md`, `docs/AI_CODEMAP.md` |
| **時間・Daily Trend・Outlookの変更** | `docs/TIME_AS_AXIS.md`, `docs/DAILY_TREND_TEMPORAL_CURRENT.md`, `docs/OUTLOOK_TEMPORAL_CURRENT.md`, 必要な場合のみ `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md` |
| **家計相談（封筒ペース・節約）** | `docs/archive/active-plans/AI_BUDGET_CALCULATOR_DESIGN.md`, `tools/envelope-calc --help` |
| **新規利用者の導入支援** | `docs/AI_ASSISTED_ADOPTION_GUIDE.md` |
| **設定駆動化** | `docs/archive/completed-plans/GENERALIZATION_TODO.md` |
| **Go source TSV editor (退役)** | `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN.md`（現在Go退役済み）, `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md`（historical） |
| **複数ポスティング** | `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md` |
| **AI効率化・開発体験改善** | `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`, `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` |
| **docs整理** | `docs/README.md`, `docs/DOCS_LIFECYCLE_CONTRACT.md`; 過去auditは必要な調査時だけ |
| **TODO整理・外部監査再評価** | `docs/archive/audits/EXTERNAL_STATIC_AUDIT_REASSESSMENT_SOURCE-2026-07-11.md`, `docs/DOCS_LIFECYCLE_CONTRACT.md` |
| **ANSIカラー制御** | `docs/archive/active-plans/DECISION_TERMINAL_COLOR_CONFIG.md` |
| **devtoolsの使い方** | このファイル末尾の「AI開発ツール（devtools）の使い方」 |

### L3: 参照（必要になったときだけ）

| 読むもの | 内容 |
|---|---|
| `docs/SAFETY_PROFILE.md` | 予測可能性、fail closed、正データ保護、不変条件 |
| `docs/ENGINEERING_ROADMAP.md` | プロ級へ詰める長期的導線 |
| `docs/CONVENTIONS.md` | 勘定科目の命名、TSVスキーマ、メタデータ定義 |
| `docs/JOURNAL_META.md` | journal.tsv / plan.tsv で使えるメタデータ一覧 |
| `docs/MAINTENANCE.md` | データのバックアップ・メンテナンス手順 |
| `docs/archive/` | 履歴・完了済み計画（必要なときだけ） |
| `docs/README.md` | docs全体の目次 |

## 作業開始時の確認

ユーザーから大きめの作業相談が来たら、まず次のどれを進める話か確認する。

1. 通常TODO / active plan（`TODO.md`, `docs/ENGINEERING_ROADMAP.md`, `docs/archive/completed-plans/GENERALIZATION_TODO.md`）
2. Safety Profile / fail closed / invariant 強化（`docs/SAFETY_PROFILE.md`）
3. docs整理 / archive候補の移動（`docs/README.md`, `docs/DOCS_LIFECYCLE_CONTRACT.md`）
4. Go source TSV editor 設計（退役・historical。設計案は `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN.md` / `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md` に残るが、現在Go自体が退役済み）
5. 複数ポスティング導入のA-1実装準備（`docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`）
6. アプリ操作導線設計（現行入口は `tools/bl` / 履歴は `docs/archive/completed-plans/COMMAND_HUB_DESIGN.md`）
7. 新規利用者の導入支援（`docs/AI_ASSISTED_ADOPTION_GUIDE.md`。maintainer作業と混ぜない）

Go は退役済みであり、現在 Go editor 関連の新規実装・稼働は行いません。
複数ポスティングは、本体ではA-1を採用し、A-2は余地を残し、A-3は別repo/フォークで研究する方針とする。
アプリ外装は、BQN editor の責務を奪わず、表示・選択・入力補助・ナビゲーションに徹する。
Quality Bar は、一般向けプロダクト化ではなく、自分の生活会計を預ける道具としての品質を優先するための判断基準として扱う。
Safety Profile は、便利さよりも「変な入力で、きれいな間違いを出さない」ことを優先する作業として扱う。
Docs整理では、いきなり削除せず、まず current route、incoming link、lifecycle metadata、archive先を確認し、小さなコミットで移動する。
Current routing docs は archived decision record より優先する。archive や superseded stub を、新しいruntime sliceの実装指示として扱わない。

## 境界削減の不変条件 (Seam Reduction Invariants)

1. **言語数を減らすことを目的にしない。**
   目的は、家計簿としての意味を知っている場所を減らすこと。
2. **Bash は UI と選択だけを担当する。**
   Bash は `accounts.tsv` / `meta_schema.tsv` / `journal.tsv` の意味を解釈しない。
   候補一覧は BQN export または設定由来の一覧を読む。
3. **Go は退役済みである。**
   現在 Go 関連ツールは active ではなく、Operation IR や TSV 操作を含め稼働していません。将来的に Go (または別言語ツール) を再導入する場合も、BQN側が正本として会計/生活ルールを所有し、外部ツール側にドメインルールを持たせない原則を維持します。
4. **BQN は source TSV の検査・意味解釈・計算・export の正本である。**
   新しい意味はまず BQN 側の契約か docs に置く。
5. **新しい概念を追加する時は、最初に「誰が知るべきか」を決める。**
   実装前に Bash / Go / BQN / config / docs の所有者を分類する。
6. **BQN-only report path を維持する。**
   source TSV (`<base>/*.tsv`; 公開 repo の `data/` は sandbox、実運用は `LEDGER_DATA_DIR` で外出し)、config TSV (`<base>/config.tsv`, `config/system_defaults.tsv`, `config/default_config.tsv`, `config/meta_schema.tsv`) と `src_next/**/*.bqn` で canonical report / export を生成できる状態を保つ。
   `checks/*` は検証用であり、Go editor / Bash UI / gum / fzf / helper scripts / helper-generated cache と同じく、正本レポート計算の必須依存にしない。

## 作業ルール

- AIは、実データ TSV（base directory 配下の `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`。例: `LEDGER_DATA_DIR=moko/data`）を絶対に直接編集・新規作成・削除してはならない。公開 repo の `data/` は匿名 sandbox だが、実データと同じ schema のため無用な変更は避ける。特に実運用 `journal.tsv` を含むこれら正本データへの書き込み操作は、AIのいかなる手段（sed, echo, overwrite, 追記等）を用いても厳禁とする。AIができるのは、あくまで「人間への編集依頼案（diffの提示）」の作成までである。ただしユーザーから明示的に指示をされた場合は編集できるものとする。
- 変更は小さく、1目的ずつ。
- 初回 push / PR 前に一度、intended scope と actual proposed diff を突き合わせる。changed filenames と、状態に応じた working tree / staged / intended base...HEAD の full diff（既コミット分を含む）を見て、無関係な追加・削除・復元漏れ、scope leakage、semantic side effect を確認する。これは短い human/pit self-review であり、lint / parser / CI gate / permanent form / metrics service にしない。
- 外部 audit snapshot / classification / backlog は実装指示ではない。current `main` で再検証し、元の優先順位を `TODO.md` へコピーせず、昇格する場合も一度に一つの finite candidate に絞る。
- TSVの先頭5列を壊さない。拡張は6列目以降の `key=value` で行う。
- journal-like TSV を読み込む際は、空の memo フィールド等で列がずれないよう、必ず `lib.SplitKeepEmpty` を使用すること。
- `src_next/report.bqn` のセクション構成や `src_next/summary.bqn` の機械向けフィールドを変更した場合は、必ず `docs/AI_CODEMAP.md` と該当する現行 report docs / check を更新すること。`docs/REPORT_FIELD_MAP.md` と `docs/MAIN_SECTIONS.md` は旧エンジン履歴として扱う。
- 封筒、トレンド、サイクルの境界に関わる変更では、`tools/check-tx-updates.bqn` だけでなく、個別の境界テスト（fixture）の追加を検討すること。
- BQNの純粋関数（モジュール内の関数など）を追加・修正した場合は、必ず `tests/` ディレクトリに単体テスト（`test_*.bqn`）を追加・更新して動作確認を行うこと。
- 拡張列（メタデータ）のキーや許容値を増やす場合は、必ず `config/meta_schema.tsv` と `docs/JOURNAL_META.md` を更新してから実装すること。
- 生活上のルールや日付（給料日、サイクル基準日など）は BQN コードや public `AGENTS.md` に利用者共通ルールとしてハードコードせず、利用者の private data、`cycle.tsv`、`accounts.tsv`、または明示的な設定へ置くこと。特定利用者の収入周期や固定費規則を他の clone 利用者へ推測適用しない。
- 設定駆動化を進める場合は `docs/archive/completed-plans/GENERALIZATION_TODO.md` のPhase順と境界を守ること。Canonical Daily Cubeのshape・Layer契約は利用者設定にせず、異なる座標や意味は同じEvent IRから別projection/viewとして作ること。
- `role=`移行では実データ `accounts.tsv` を先に変更しない。明示role・Prefix fallbackの契約とfixtureを先に作り、実データ移行はユーザー確認後の別Phaseで行うこと。
- 新しい計算・表示は原則 `src_next/` 配下のモジュールを使う。
- base directory 配下の `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` が正データであり、それ以外は派生であることを忘れないこと。公開 repo の `data/` は sandbox、実運用は `LEDGER_DATA_DIR` を優先する。個人的な非公開メモや検証ログは root の `private/` ではなく gitignore 済みの `moko/private/` に寄せる。
- Safety Profile に関わる変更では、黙って補正するより、error / warning / skipped / unavailable として明示する方を優先すること。
- docs整理では、現行仕様と履歴メモを混ぜない。完了済み計画は `docs/archive/completed-plans/` へ移す候補として扱い、移動前に導線を確認すること。
- 仕様変更時は docs も更新する。
- `TODO.md` の current Active work finite slice を終える変更では、同じ PR で TODO の routing も更新する。難しい場合は completed work を Active のまま残さず、明示的な routing follow-up を置く。
- 変更後は可能なら `./tools/check.sh` を実行する。pit環境では通常 `rtk bash ./tools/check.sh` を使う。**新しい BQN モジュールや check スクリプトを追加した場合は、`check.sh` に含まれる `devtools-check.sh` が repo-index の未索引を検出するので、`./tools/repo-index --baseline` で更新すること。**
- ユーザーが他AI（DeepSeek, Gemini, Codex, pi agent 等）へ渡す作業指示書を作る場合は、明示的に local-only / no-push と指定されない限り、作業範囲に `git status`、必要なチェック、`git add`、`git commit`、`git push` までを含める。push後は commit hash と実行したチェック結果を報告させる。
- `pi agent` や `gemini` CLI などのAI（pit）環境では、出力が長くなりそうなコマンド（git/npm/test等）はトークン節約のため `rtk` または `sqz` を使うこと。任意コマンドの前置きには原則 `rtk` を使う（例: `rtk git diff`, `rtk bash ./tools/check.sh`）。この環境の `sqz` は stdin圧縮型なので、使う場合は `some-command 2>&1 | sqz compress --cmd <name>` の形にする。
- AIの作業効率化、デバッグツール、または開発体験の改善に関する相談や作業を行う際は、必ず `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` と `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` をロードすること。作業中に得た小さな改善案は必要に応じて feedback log へ追記し、溜まったらレビューしてツール化・ルール化・不採用を判断する。
- **UIツールの責務分離**: レポート表示系の機能は `tools/main-ui.sh` に追加する。ファイル操作系（仕訳追加・取消・予定管理など）の機能は `tools/add-ui.sh` に追加する。両者の責務を混ぜないこと。
- **作業完了時の検証とprivate-data境界**: 完了確認は公開fixture / sandboxを既定とする。実運用 `LEDGER_DATA_DIR` に対する確認は、ユーザーが明示的に依頼した場合だけread-onlyで行い、正本TSVを変更しない。privateな行、金額、口座名、report本文をpublic PR・issue・commit・チャットへ貼らず、実行したcheck、構造的な結果、必要なredactionだけを報告する。実データ確認を行っていない場合は、production validation済みと主張しない。

## AI開発ツール（devtools）の使い方

### `rtk` — 長出力コマンドのトークン節約ラッパー

```bash
rtk git diff          # 差分確認
rtk git status        # 状態確認
rtk bash ./tools/check.sh  # テスト実行
```

`rtk` は出力を自動truncateする。長い出力が予想されるコマンド全般に使う。

### `sqz` — 出力圧縮・トークン管理

```bash
# stdin圧縮型: 長いコマンド出力を圧縮
some-command 2>&1 | sqz compress --cmd <name>

# トークン使用量確認
sqz status
```

`rtk` と `sqz` の使い分け: 普段は `rtk`、出力が特に長くて圧縮価値がある時は `sqz compress`。

### `bqn-eval` — BQN式の簡易評価

```bash
bash tools/bqn-eval '≢ "OK"'        # shape確認
bash tools/bqn-eval '<"OK"'         # 値の表示
bash tools/bqn-eval '⟨<"OK", <"WARN"⟩'  # 複合値
printf '•Out "test"' | bash tools/bqn-eval  # stdinも可
```

Phase 1 scope: repo moduleロード不可、TSVロード不可、text/raw出力のみ。

### `bqn-dump` — BQN値の型・shape診断

```bash
bash tools/bqn-dump '5'                # kind: number
bash tools/bqn-dump '"OK"'             # kind: string
bash tools/bqn-dump '⟨<"OK", <"WARN"⟩' # kind: list_boxed
```

出力フォーマット: kind / shape / preview / boxed hint。homogenization / Enclose / Disclose のデバッグ用。

### `query` — report-next-summaryのフィルタ

```bash
tools/query <base> <key>           # 単一キー
tools/query <base> --list           # 全キー:値
tools/query <base> --keys           # キー一覧
tools/query <base> --grep <pat>     # キー名grep
tools/query <base> --grep-val <pat> # 値grep
```

計算しない。machine-readable出力のフィルタのみ。

### `envelope-calc` — 封筒予算の対話的計算

```bash
tools/envelope-calc list                        # 封筒一覧
tools/envelope-calc pace 食費                   # ペース診断(SAFE/WARN/SHORT)
tools/envelope-calc recover 食費 550            # 1日550円制限→復帰まで何日
tools/envelope-calc recover-target 食費 7       # 7日復帰→1日上限いくら
tools/envelope-calc deplete 一般生活             # 枯渇予測(あと何日・不足日数)
tools/envelope-calc --machine deplete 一般生活   # 機械可読出力 (key:value)
tools/envelope-calc --debug pace 食費            # 中間値ダンプ付き（stderr相当）
```

家計相談（封筒ペース・節約・枯渇予測）の計算用。`src_next/calc/envelope_calc.bqn` の P1〜P4 プリミティブを使用。
`query` と違い、計算を伴う（純粋関数、read-only）。
`--machine` でAIが直接パース可能な key:value 出力になる。
`--debug` で cycle, elapsed, 全封筒の raw 値を `[debug]` プレフィックス付きで出力（`--machine` 併用時は抑制）。
設計 doc: `docs/archive/active-plans/AI_BUDGET_CALCULATOR_DESIGN.md`

### `repo-index` — リポジトリ索引

```bash
tools/repo-index                  # TSV索引をstdoutに出力
tools/repo-index --baseline        # 現在の索引をbaselineとして保存
tools/repo-index --diff            # baselineとの差分（追加/削除）
```

### `scaffold-check.sh` — checkスクリプトのboilerplate生成

```bash
tools/scaffold-check.sh <check-name>
# → checks/check-<name>.sh を生成（repo root解決、trap、assert helpers付き）
```

### ツールの自己検証

```bash
bash ./tools/devtools-check.sh  # 全devtoolsの健全性チェック
```

このメタチェックは `check.sh` の [4/4] に組み込み済み。新しいBQNモジュール・checkを追加した時は、AIが自動的にこのチェックで検知し、必要に応じて `repo-index --baseline` の更新を行うこと。
