# Canonical Daily Cube 監査メモ

最終更新日: 2026-06-26
ステータス: **src_next Daily Cube 現行契約 / 実装・検証あり**

## 概要

現行レポートの主要 materialized view は、**Canonical Daily Cube**（`Day × Account × Layer`）です。
`src_next/projection.bqn` で作った ledger-like projection rows を `src_next/cube.bqn` が dense cube に materialize します。
イベントログ（TSV）の柔軟性を保ちつつ、レポート計算の効率化とロジックの共通化を実現しています。

Phase 6では、同じEvent IRからDaily Cubeとは別にcashflow due long viewを生成できることを確認しました。Cubeは正データや唯一の時間モデルではなく、会計日次projectionをmaterializeしたviewです。

設計上の合言葉は次の通りです。

```text
時間はラベルではなく、座標軸である。
```

Cubeの`Day`はEventを配置したcoordinate axisです。`as_of`はCubeの軸ではなく、どの時点からsnapshotを観察するかを表す外側のobservation timeです。cycle、月、週は`Day`軸上の区間viewであり、Cubeの基本軸には追加しません。詳細は`docs/TIME_AS_AXIS.md`を参照してください。

## 群論的構造 (Group-theoretic Properties)

- **加法群の独立性**: レイヤー 0 (Actual), レイヤー 1 (Plan), レイヤー 2 (Budget) は、それぞれ独立した加法群として振る舞います。
- **不変量 (Invariant)**: `budget:*` 勘定の Actual レイヤーは常にゼロです。これは、予算管理が「現実の資産移動」とは別の座標系（レイヤー）で動いていることを意味します。
- **逆元**: ジャーナルに削除操作はなく、符号を反転させた新しい元の追記によって表現されます。

## スライス効率 (Slice Efficiency)

`report_envelope_trend.bqn` 等のレポートにおいて、従来の日付ごとのループは配列スライスに置き換えられました。
`Day` 軸は `cube_ordinals` と完全に同期しているため、`trend_mask` による一括抽出（O(1) インデックス相当）が可能です。

```bqn
# 例: 封筒（Layer 2）の残高推移を一括取得
env_history_bal ← env_idxs ⊸ ⊏ ˘ 2 ⊏ ˘ ˘ trend_mask / cube_balances
```

## 構造

### 1. 軸 (Axes)

**重要制約**: Cubeの軸は以下の3次元に厳格に限定されます。**店舗・メモ・任意カテゴリなどを軸として拡張してはいけません。** これらはあくまでTSVのメタデータ（6列目以降など）として保持し、BQNのコア配列エンジンには乗せません。

- **Day (第0軸)**: カレンダー上の連続した日付（Dense Axis）。`date.bqn` の Ordinal に基づく。
- **Account (第1軸)**: `accounts.tsv` から動的に決定される勘定科目空間。スロット数は `≠accounts`。
- **Layer (第2軸)**: 4つの情報レイヤー。


### 2. レイヤー (Layers)

| Index | Name | Source | 意味 |
|---|---|---|---|
| 0 | `actual` | `journal.tsv` | 現実の資産・収入・支出の動き。 |
| 1 | `plan` | `plan.tsv` | 予定された将来の動き。 |
| 2 | `budget` | `budget_alloc.tsv` + journal 支出 | 封筒の配賦と消費の動き。 |
| 3 | `forecast` | (TBD) | 予測値。 |

Layerは同じdaily coordinate上に並びますが、確定度や責務が同じという意味ではありません。Actualは閉じた会計値、Planは明示予定、Budgetは配賦と消費です。現行Plan Layerには通常のPlan deltaに加え、envelope対応費目の`plan_envelope` deltaも含まれます。

ResidualとScenarioは現時点でLayerへ追加しません。既存Layerと時間windowから作る派生観察viewとして検討します。

## 実装の詳細

- **場所**: `src_next/cube.bqn` の `Materialize`。
- **入力**: `src_next/projection.bqn` が作る projection row。各行は `source_file / source_row / source_id / day_index / account_key_index / layer_index / delta / kind / status / message` などを持つ。
- **Context**: `src_next/context.bqn` が accounts / config / source TSV を読み、cycle view と projection rows を組み立て、`cube.Materialize ⟨rows, day_count, ak_count⟩` を呼ぶ。
- **Dense Axis**: 現行 `src_next` では選択された period/cycle の `day_count` と、`accounts.tsv` 由来の動的 `ak_count` と、固定 `layer_count=4` で cube を作る。
- **Row acceptance boundary**: projection row は `status`, `day_index`, `account_key_index`, `layer_index` を検査し、valid rows だけを cube index として使う。skipped rows は `skipped_summary` / readiness / golden output の診断材料として残す。
- **Validation summary**: `actual_total_match`, `plan_total_match`, `actual_per_account_totals_match` を出し、`tools/check.sh` 配下の `check-src-next-*` と unit test が検証する。
- **Snapshot / TBDS**: 残高系の accounting state は `src_next/tbds.bqn` / `src_next/snapshot.bqn` が `opening / movement / closing` として扱う。cycle は source loading boundary ではなく report query boundary とする方針は `docs/TBDS_CONTRACT.md` を参照。

## 成果

1. **予定の統合**: `plan.tsv` が他のデータと同じ配列構造に乗ったため、将来の「固定費予約（Fixed Reserve）」などの計算が極めて単純化された。
2. **日付計算の簡素化**: 取引日を探すループが不要になり、`Ordinal` の差分によるインデックスアクセスに一本化された。
3. **安全側予測の統一**: `liq_safe_daily`（保守的な日割り額）を導入。将来の予定収入をあてにせず、予定支出だけを差し引いた「今日使えるお金」を明確にした。
4. **拡張性**: `forecast` 用のshapeは予約され、全ゼロでも安全に扱える。projection規則は未実装。

## 検査項目 (Invariants)

- Actual レイヤーには `budget:*` 口座の動きが含まれない（`journal.tsv` 由来の budget account actual と `budget_alloc.tsv` actual をゼロ化）。
- Budget レイヤーには `budget_alloc.tsv` の配賦と Journal 由来の支出が投影される。
- Plan レイヤーは Actual 残高に影響を与えない。
- `tests/test_src_next_cube.bqn` は skipped row が cube index として使われないこと、layer totals、per-account totals、validation summary を検査する。
- `checks/check-src-next-golden.sh` は `shape: <day_count> × <ak_count> × 4`、layer totals、projection balance、skipped rows、validation summary を golden fixture で検査する。
