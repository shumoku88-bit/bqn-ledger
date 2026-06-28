# Meal log experiment draft

Status: **draft / experimental / docs-only / no production behavior change**

## 1. Purpose

This document explores adding an experimental meal log alongside the existing
household accounting data.

The goal is to make food-spending consultation more useful by connecting money
records with simple meal observations.

Current reports can show whether food spending is fast, slow, safe, or unsafe.
A meal log may help answer softer workflow questions such as:

- Are expensive food days connected with outside meals?
- Are low-spending days still supported by actual meals?
- Are home meals, supermarket meals, convenience meals, or treated meals changing the food budget pattern?
- Are late-night or outing-related meals common enough to matter?

This is an observation layer, not a replacement for the accounting ledger.

## 2. Design stance

The meal log should remain separate from canonical accounting data.

Initial rules:

- Do not mix meal records into `journal.tsv`.
- Do not mix meal records into `plan.tsv`.
- Do not treat meal records as the source of truth for money totals.
- Do not change existing production report behavior.
- Do not add a 13th production report section as part of this draft.
- Do not make `src_next` production-ready because of this experiment.
- Keep real meal records outside the repository unless a later decision changes that.

The accounting ledger remains the source of truth for money.
The meal log is a household observation log.

## 3. Why not breakfast / lunch / dinner

The user's eating pattern does not necessarily follow a fixed three-meal model.

Examples:

- Buy discounted bread before going out.
- Eat outside if someone else pays.
- Return home and cook if no outside meal happens.
- Skip a later meal if not hungry.
- Eat late at night if awake and hungry.

Therefore, the log should record meal events in the order they happened, not as
`breakfast`, `lunch`, and `dinner`.

## 4. Proposed event shape

Use one row per meal event.

Proposed file name for a private/local experiment:

```text
data_private/meal_log.tsv
```

Public example data, if needed later, should use fabricated fixture rows:

```text
fixtures/meal-log-basic/meal_log.tsv
```

Proposed columns:

```tsv
date	eat_no	food	source	context	payer	fullness	satisfaction	note
```

Column meanings:

| column | meaning | initial rule |
|---|---|---|
| `date` | Calendar date of the meal event. | Required. `YYYY-MM-DD`. |
| `eat_no` | Meal event number within the day. | Required. Integer, usually `1` to `5`. |
| `food` | Human-readable meal content. | Required enough to be useful. Not a detailed nutrition database. |
| `source` | Where the meal came from. | Controlled label, but policy-level. |
| `context` | Situation around the meal. | Controlled label, but flexible. |
| `payer` | Who paid for the meal. | Helps separate self-funded meals from treated meals. |
| `fullness` | How filling the meal was. | Simple label. |
| `satisfaction` | Subjective satisfaction. | Optional small number, e.g. `1` to `5`. |
| `note` | Free note. | Optional. |

## 5. Five-slot idea

The first version should support up to five meal events per day by using
`eat_no = 1..5`.

This does not mean that every day must have five rows.

Preferred rule:

```text
Record only meal events that actually happened.
```

Missing meals should not require blank placeholder rows.

Examples:

- A one-meal day has one row with `eat_no=1`.
- A three-event day has rows `eat_no=1`, `eat_no=2`, `eat_no=3`.
- A late-night extra meal can be `eat_no=4` or `eat_no=5`.

If a later BQN report wants a fixed shape, it can project sparse event rows into:

```text
Day × EatSlot
```

where `EatSlot` is initially 5.

## 6. Initial controlled labels

These labels are suggestions for observation only. They should not become hard-
coded engine concepts without a later contract.

### source

```text
home
supermarket
convenience
eatout
delivery
gift
other
unknown
```

### context

```text
after_wakeup
before_outing
outside
after_return
late_night
snackish
no_cook
other
unknown
```

### payer

```text
self
other
shared
unknown
```

### fullness

```text
low
medium
high
unknown
```

### satisfaction

Use an integer scale if recorded:

```text
1 = poor
2 = low
3 = okay
4 = good
5 = very_good
```

## 7. Example rows

These examples are fabricated and must not be treated as real user data.

```tsv
date	eat_no	food	source	context	payer	fullness	satisfaction	note
2026-06-24	1	安売りパン	supermarket	before_outing	self	medium	4	出かける前に食べた
2026-06-24	2	定食	eatout	outside	other	high	5	おごってもらった
2026-06-24	3	ごはん、味噌汁、卵	home	after_return	self	medium	4	軽く自炊
2026-06-25	1	うどん	home	late_night	self	high	4	夜中にお腹が減った
```

## 8. Possible future report questions

A future experimental report could derive:

- Number of days with any meal log.
- Number of meal events per day.
- Source breakdown: home / supermarket / convenience / eatout / gift.
- Treated meals vs self-funded meals.
- Late-night meal count.
- Days with low fullness or low satisfaction.
- Food spending pace alongside meal-event count.
- Notes useful for AI consultation.

These are exploratory observations, not production accounting totals.

## 9. Privacy boundary

Meal records can be personal lifestyle data.

Real meal records should stay private/local by default.
Do not commit real meal records to the repository as part of this draft.
Use fabricated fixtures if examples are needed.

## 10. Non-goals

- Do not implement meal logging in BQN yet.
- Do not change `main.bqn`.
- Do not change `src_next`.
- Do not change source TSV formats.
- Do not change production report sections.
- Do not add real meal data.
- Do not make food budget calculations depend on meal log data yet.

## 11. Open questions

- Should `eat_no` allow more than 5 if an unusual day needs it?
- Should `time` be added later, or is order within the day enough?
- Should `source` and `context` labels live in a small metadata file?
- Should a meal log be private-only, with only fabricated fixtures in the repo?
- Should future AI consultation use summarized meal observations rather than raw notes?

## 12. Related documents

- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — current production report sections must not be silently reduced.
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — household labels should remain configurable policy data, not hard-coded engine concepts.
- `docs/ARCHITECTURE_NEXT.md` — `bqn-ledger` as a cycle-oriented report engine.
