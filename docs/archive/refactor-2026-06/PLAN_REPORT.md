# 家計簿システム・レポート方針メモ

## 方針（先に決める）

- 当面の入口は **`bqn main.bqn` の1コマンド**
- ただし `main.bqn` は巨大化させない：計算・整形は import 可能なモジュールに分割する
- サイクルなどの切替は TSV（設定）を正にする（コードを書き換えない）

詳細は `docs/REPORT_DESIGN.md` を参照。

## 現状（main.bqn）

現時点の `main.bqn` は概ね次のブロックを出力します。

- 資産・実績（残高一覧）
- 今サイクル集計（cycle.tsv で期間変更）
- 封筒・予算残高（budget_alloc.tsv + 自動消費）
- 未来の支払い予定（plan.tsv）
- 見通し・日割り金額（`--section outlook`）

## outlook について

見通し・日割りは `main.bqn --section outlook` に統一する。
単独の予測ロジックは持たせず、計算本体は `report_engine.bqn` / `report_outlook.bqn` に置く。
