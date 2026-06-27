# plan_id backfill record

Status: **applied to source TSV**  
Date: 2026-06-18  
Source: `plan.tsv`  
Applied commit: `fb81276d7c87f6a7a0f5102bd9bedc304301504b`

この文書は、既存 `plan.tsv` 行へ `plan_id=` を後付けした内容の記録である。

採用済み命名規則:

```text
plan-YYYY-MM-DD-<series>
```

- `YYYY-MM-DD` は `plan.tsv` 上の予定日。
- `<series>` は既存の `series=<id>` を使う。
- 衝突時のみ `-02`, `-03` を付ける。
- 予定日と実績日がずれても、`plan_id` は予定日のまま `journal.tsv` へ引き継ぐ。

---

## Backfill applied

| line | date | memo | series | applied plan_id | note |
|---:|---|---|---|---|---|
| 4 | 2026-06-24 | google-one | google-one | `plan-2026-06-24-google-one` | applied |
| 7 | 2026-07-15 | gpt-plus | gpt-plus | `plan-2026-07-15-gpt-plus` | applied |
| 8 | 2026-07-16 | wifi | wifi | `plan-2026-07-16-wifi` | applied |
| 9 | 2026-07-10 | povo | povo | `plan-2026-07-10-povo` | applied |
| 10 | 2026-07-24 | google-one | google-one | `plan-2026-07-24-google-one` | applied |
| 13 | 2026-08-14 | 年金 | pension | `plan-2026-08-14-pension` | applied |
| 14 | 2026-08-14 | 支援給付金 | support | `plan-2026-08-14-support` | applied |
| 15 | 2026-08-14 | 家賃 | rent | `plan-2026-08-14-rent` | applied |
| 16 | 2026-08-14 | 光熱費(2ヶ月見込) | utilities | `plan-2026-08-14-utilities` | applied |
| 17 | 2026-08-14 | 借金返済 | debt | `plan-2026-08-14-debt` | applied |
| 18 | 2026-08-15 | 健康保険料 | health-insurance | `plan-2026-08-15-health-insurance` | applied |

Collision check: none.

---

## Resulting source rows

```tsv
# 2026-06 after income-day payments
2026-06-24	google-one	assets:smbc	expenses:AIサブスク	1450	recur=monthly	series=google-one	plan_id=plan-2026-06-24-google-one

# 2026-07 monthly payments in next cycle
2026-07-15	gpt-plus	assets:smbc	expenses:AIサブスク	3000	recur=monthly	series=gpt-plus	plan_id=plan-2026-07-15-gpt-plus
2026-07-16	wifi	assets:smbc	expenses:通信	4812	recur=monthly	series=wifi	plan_id=plan-2026-07-16-wifi
2026-07-10	povo	assets:smbc	expenses:通信	330	recur=monthly	series=povo	plan_id=plan-2026-07-10-povo
2026-07-24	google-one	assets:smbc	expenses:AIサブスク	1450	recur=monthly	series=google-one	plan_id=plan-2026-07-24-google-one

# 2026-08 next income anchor
2026-08-14	年金	income:年金	assets:smbc	225276	recur=cycle	series=pension	plan_id=plan-2026-08-14-pension
2026-08-14	支援給付金	income:支援給付金	assets:smbc	11240	recur=cycle	anchor=income:年金	offset=0	series=support	plan_id=plan-2026-08-14-support
2026-08-14	家賃	assets:smbc	expenses:家賃	64000	recur=cycle	anchor=income:年金	offset=0	series=rent	plan_id=plan-2026-08-14-rent
2026-08-14	光熱費(2ヶ月見込)	assets:smbc	expenses:光熱費	21002	recur=cycle	anchor=income:年金	offset=0	series=utilities	plan_id=plan-2026-08-14-utilities
2026-08-14	借金返済	assets:smbc	expenses:借金返済	10000	recur=cycle	anchor=income:年金	offset=0	series=debt	plan_id=plan-2026-08-14-debt
2026-08-15	健康保険料	assets:smbc	expenses:保険料	2000	recur=cycle	anchor=income:年金	offset=1	series=health-insurance	plan_id=plan-2026-08-15-health-insurance
```

---

## After applying

After this source TSV change, run the normal checks before treating downstream reports as verified.
