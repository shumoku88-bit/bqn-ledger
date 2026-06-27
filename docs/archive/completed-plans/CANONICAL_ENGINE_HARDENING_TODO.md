# CANONICAL_ENGINE_HARDENING_TODO

Status: **active remainder / compressed**
Date: 2026-06-22

目的: `bqn-ledger` を「生活判断AI」ではなく、いつでも同じ重さを返す **数字の正本エンジン（秤）** として固める。

合言葉:

```text
BQNは王冠ではなく、秤。
BQNは占い師ではなく、天文台。
```

## 読み方

この文書は、canonical engine hardening の **現役の残り作業** だけを置く。

完了済み / ほぼ完了済み Phase の履歴は次へ退避済み:

```text
docs/archive/completed-plans/CANONICAL_ENGINE_HARDENING_COMPLETED_PHASES.md
```

棚卸しと trust order は次を参照する:

```text
docs/CANONICAL_ENGINE_HARDENING_TODO.status.md
```

現在の作業順は `TODO.md` を優先する。

## 0. 原則・禁止事項

### 守ること

- [ ] 現在の主要出力値を原則として変えない。
- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` を正データとして扱う。
- [ ] `BuildCube` は `Day × Account × Layer` の構築責務に限定する。
- [ ] 生活相談・次サイクル予算案・おすすめ配分は canonical core に混ぜない。
- [ ] 外部推論系（Datalog / Prolog / その他候補）は、採用する場合まず BQN export を正本期待値として読む方針にする。

### 禁止

- [ ] `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` の意味を勝手に変えない。
- [ ] 封筒予算の計算式を fixture / golden なしで変更しない。
- [ ] consultation arithmetic を canonical な数値に混ぜない。
- [ ] golden output なしで `BuildCube` 周辺を大きく変更しない。
- [ ] 表示改善を理由に core の意味を変えない。
- [ ] 失敗している入力を、黙ってそれっぽいレポートにしない。

## Current active work

### 1. Safety Profile invariant mapping

目的: `docs/SAFETY_PROFILE.md` の不変条件を、既存の check / lint / fixture / report status のどこで守るか対応づける。

- [x] Safety Profile の invariant 一覧を読む。
- [x] 各 invariant について、現在の検査場所を対応づける。
- [x] 未検査の invariant を `TODO.md` の近い順へ戻す。
- [x] 既存で守れているものは、重複実装せず docs に記録する。

### 2. Section status policy

目的: report section ごとに、正常値と異常値の扱いを固定する。

使う状態語:

```text
OK
WARN
ERROR
SKIPPED
UNAVAILABLE
```

- [x] section ごとに、どの状態を出し得るか決める。
- [x] 入力不備・未来予定不足・設定不足・計算不能を区別する。
- [x] 欠損時に 0 と表示してよいケースと、`UNAVAILABLE` にすべきケースを分ける。
- [x] 主要 section の方針を `docs/REPORT_CONTRACTS.md` または別の小文書へ接続する。

### 3. Failure fixtures for pretty-wrong prevention

目的: 不正入力や仕様外状態で「きれいな間違い」を出さないことを fixture で固定する。

候補:

- [x] 未定義 account を含む journal。
- [ ] 封筒消費はあるが対応する budget mapping がないケース。
- [ ] stale plan が残っているケース。
- [ ] future anchor が欠けているケース。
- [ ] 空列保持が壊れているケース。
- [ ] 0 に見えるが、実際は unavailable とすべきケース。

完了条件:

- [x] `tools/check.sh` で failure fixture が検出される。
- [x] レポートが失敗状態を明示し、黙って polished output を出さない。

### 4. Debug / provenance sections

目的: 通常レポートを重くせず、数字の出所を追える入口を持つ。

候補 section:

- [x] `debug sources` (Proposed minimal scope for liquid_assets, envelopes, plans in docs/DEBUG_PROVENANCE_DESIGN.md)
- [ ] `debug invariants`
- [ ] `debug cube`
- [ ] `debug accounts`
- [ ] `debug formulas`

主要値の由来例:

```text
liquid_assets
  source: journal.tsv actual layer

envelope_balance
  source: budget_alloc.tsv + journal.tsv mapped spending, budget layer

planned_spending_until_cycle_end
  source: plan.tsv until cycle_end
```

完了条件:

- [x] 通常レポートは重くしない。 (Proposed detached debug-provenance section design)
- [ ] debug指定時に、AIや未来の自分が数字の出所を調査できる。 (Implementation pending feedback)

### 5. External reasoning role decision

目的: Datalog / Prolog / その他の外部推論系を canonical generator にせず、checker / explainer / consultant として使うか判断する。

現時点の方針:

- BQN export を外部推論系が読む測量杭にする。
- 外部推論系は、採用する場合でも canonical number generator にしない。
- 相談・説明・仮説生成は外側へ逃がす。

未決:

- [ ] 外部推論系を使うか、使わないか。
- [ ] 使う場合、checker / explainer / consultant / rule notebook のどれに近いか。
- [ ] 使わない場合、不要理由または別案を記録する。

### 6. Later work

Phase 11 由来の後回し項目:

- [ ] 予定消化ツール（外側ツール。BQN coreには入れない）
- [ ] 匿名化export
- [ ] 公開用レポート
- [ ] 食費など個別封筒の7日平均・burnout_date

### 7. Code structure hardening (配列思考レビュー指摘)

目的: コードの構造を配列プログラマから見ても納得できる形に整理する。
いずれも既存の動作・出力を変えない範囲の内部整理。

Source: 2026-06-23 配列思考コードレビュー (`docs/ARRAY_CODE_REVIEW_NOTES.md` 不在のため本TODOに直接記録)

#### 7a. `BuildAt` の巨大 Record 分割

現状 `report_engine.bqn.BuildAt` は 100+ フィールドの Namespace を返す。
これは事実上のグローバル状態であり、どの section がどのフィールドに依存するか追跡困難。

- [ ] `BuildAt` の戻り値を意味のあるサブ Record に分割する（例: `cube`, `snapshot`, `cycle`, `trend`, `envelopes`）。
- [ ] 各 section は必要なサブ Record だけを受け取る形にする。
- [ ] 分割後も既存の golden output が変わらないことを確認する。

#### 7b. 投影関数の繰り返し構造の共通化

`build_cube.bqn` の `ProjectActual` / `ProjectBudgetConsumption` / `ProjectBudgetAlloc` / `ProjectPlan` は、
いずれも「勘定→インデックス解決→delta付き Projection リストを返す」パターンの繰り返し。

- [x] `ResolveEvent` と `ProjOutPair`/`ProjOut1` 共通ヘルパー関数へ統合し、各投影ロジックの重複を排除完了。
- [x] 分割後も既存の golden output が変わらないことを確認する。

#### 7c. `build_cube.bqn` 内の `256` 直書き排除

`docs/ARCHITECTURE.md` で 256スロット固定の理由は説明済みだが、
コード内の `FlatIdx`、`MaterializeDaily`、空 Cube 生成で `256` が直書きされている。

- [x] `max_accounts` 定数を導入し、コード内の直書き `256` をエクスポートされた値または動的導出へ移行完了。
- [x] コード内の `256` リテラルを 1 箇所（accounts 読み込み時）に集約する。

#### 7d. 外部プロセス呼び出しの明示化

`loader.bqn` で `•SH "cat"` が使用されていた問題および純粋境界の明示。

- [x] `loader.bqn` での `•SH "cat"` 依存を native BQN の `•FChars` および例外ハンドラ `⎊` へ完全移行完了。
- [ ] `Today` は IO を含むことを命名または注釈で明示する（現状コメントで説明済み、大きな問題ではない）。

#### 7e. `report_engine.bqn` の公開 Record スキーマ分離

`report_engine.bqn` の後半約150行は公開フィールドの列挙である。
コードと宣言が混在しており、フィールド一覧の俯瞰が困難。

- [ ] 公開フィールド一覧を別ファイル（例: `report_schema.bqn`）に分離する。
- [ ] スキーマ変更時に `docs/REPORT_FIELD_MAP.md` との整合を自動確認できるようにする。

完了条件:

- [ ] 全項目で既存の `./tools/check.sh` が通る。
- [ ] golden output が変わらない。
- [ ] 各項目の着手前に `TODO.md` へ登録する。

## 今すぐ着手する順番

`TODO.md` を優先する。

近い順:

1. [x] きれいな間違いを防ぐ失敗 fixture を追加する。 (Added unknown-account failure fixture)

## pitへの作業指示テンプレ

```text
bqn-ledger の canonical engine hardening を進める。

目的:
BQNを封筒予算・流動資産・予定・実績の正本エンジンとして固定し、
意味づけ・表示・相談・検算を外側へ逃がす。

守ること:
- 現在の出力値を変えない
- BuildCubeの意味を変えない
- journal.tsv / plan.tsv / budget_alloc.tsv / accounts.tsv を勝手に変更しない
- consultation arithmetic を canonical output に混ぜない
- docs/CANONICAL_ENGINE_HARDENING_TODO.md は active remainder として読む
- 完了済みPhaseの詳細は docs/archive/completed-plans/CANONICAL_ENGINE_HARDENING_COMPLETED_PHASES.md を読む

今回の作業:
- <ここに active work 番号とタスクを書く>

完了条件:
- docs更新
- 必要ならfixture/golden追加
- ./tools/check.sh が通る
- 出力値が変わる場合は理由と差分を説明して確認を取る
```
