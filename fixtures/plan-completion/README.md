# Fixture: plan-completion

この fixture は、`plan_id` による予定（Plan）の履行済み判定および未履行予定（`plan_open`）の抽出規則を検証するためのものです。

## 意図と検証シナリオ

基準日（`as-of`）を `2026-01-16` とした時、`plan.tsv` にある予定は以下の通りに処理されなければなりません。

1. **Unfulfilled phone** (日付: `2026-01-10` / 過去 / `plan_id` あり / 実績になし)
   - 過去の予定ですが、`journal.tsv` に同じ `plan_id` の実績が存在しないため、Plan Statusでは **`overdue_open`** として残ります。未来支払い一覧からは除外されます。
2. **Rent** (日付: `2026-01-15` / 過去 / `plan_id` あり / 実績にあり)
   - `journal.tsv` に同じ `plan_id` の実績がすでに記録されているため、**履行済み**として未履行リスト（`plan_open`）から除外されます。
3. **Planned book** (日付: `2026-01-24` / 未来 / `plan_id` あり / 実績になし)
   - 未来の未履行予定であるため、**未履行**（`plan_open`）として見通しに残ります。
4. **Unplanned food** (日付: `2026-01-25` / 未来 / `plan_id` なし)
   - `plan_id` を持っていませんが、日付が今日（16日）以降の未来予定であるため、**未履行**として見通しに残ります（非常口としての互換性の検証）。

## 期待される結果

`Planned Payments`（セクション `planned`）を出力した際、未来の2行（`Planned book`, `Unplanned food`）だけが表示されます。

Plan Statusには全4行が表示され、`Unfulfilled phone` は `overdue_open`、`Rent` は `completed` になります。

Residualでは、`as_of`時点で観察対象の `Unfulfilled phone` と `Rent` が比較対象になり、`future_open` の `Planned book` / `Unplanned food` はまだ除外されます。
