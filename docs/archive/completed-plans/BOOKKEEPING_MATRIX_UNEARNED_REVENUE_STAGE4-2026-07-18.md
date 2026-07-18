# Bookkeeping Matrix Study: Unearned Maintenance Revenue Receipt and One-Month Revenue Recognition Stage 4

Status: completed research fixture
Owner: other
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; future accounting or adapter topics require separately selected slices
Date: 2026-07-18

## 目的

簿記行列研究のStage 4として、年間保守サービス代金12,000 JPYの前受けと1か月分1,000 JPYの収益認識を、journal取引ブロック、event × account行列、running balances、BQN assertionsと手計算説明の四つで一致させた。

本作業はpublic synthetic fixtureによるtest-only研究であり、production機能ではない。

## 二件の仕訳

### 年間保守サービス代を前受け（2026-11-01）

```text
借方  assets:bank                    12000
貸方  liabilities:unearned-revenue  12000
```

符号付きposting:

```text
assets:bank                     12000
liabilities:unearned-revenue   -12000
```

サービス未提供のため、この時点では`income:maintenance`を動かさない。

### 1か月分の保守収益を認識（2026-11-30）

```text
借方  liabilities:unearned-revenue  1000
貸方  income:maintenance             1000
```

符号付きposting:

```text
liabilities:unearned-revenue    1000
income:maintenance             -1000
```

前受収益から収益への振替であり、`assets:bank`を動かさない。

## Posting IR符号規約

借方方向を正、貸方方向を負とする。

- 資産の増加: 正
- 負債の増加: 負
- 負債の減少: 正
- 収益の増加: 負

## event × account行列

```text
event_key	layer	assets:bank	liabilities:unearned-revenue	income:maintenance	row_total
maintenance-advance-received	actual	12000	-12000	0	0
maintenance-month-earned	actual	0	1000	-1000	0
```

各event行の合計は0であり、取引ごとの貸借一致を保持する。

## running balances

BQNのscan `` +` `` をevent × account行列へ適用して導出する。

```text
event_key	assets:bank	liabilities:unearned-revenue	income:maintenance
maintenance-advance-received	12000	-12000	0
maintenance-month-earned	12000	-11000	-1000
```

## 前受収益と時間差の意味

現金を受け取っても、未提供サービスに対応する部分は収益ではなく顧客へサービスを提供する義務であるため、前受収益という負債として保持する。サービス提供後、その期間に対応する金額だけ負債を減らし、収益を認識する。

最終残高は次のとおり。

```text
assets:bank                     12000
liabilities:unearned-revenue   -11000
income:maintenance             -1000
```

符号付き保存関係と金額の保存関係はそれぞれ次のとおり。

```text
-11000 + -1000 = -12000
11000 + 1000 = 12000
12000 + -11000 + -1000 = 0
```

## 4方向の有限研究セット

Stage 1からStage 4により、次の最初の4方向が完了した。

- 売掛金: 収益認識から現金回収
- 未払金: 費用認識から現金支払い
- 前払費用: 現金支払いから費用認識
- 前受収益: 現金受領から収益認識

各fixtureとテストは独立し、相互依存しない。

## 実装ファイル

- `fixtures/bookkeeping-matrix-unearned-revenue/profile.journal`
- `fixtures/bookkeeping-matrix-unearned-revenue/expected-event-account-matrix.tsv`
- `fixtures/bookkeeping-matrix-unearned-revenue/expected-running-balances.tsv`
- `fixtures/bookkeeping-matrix-unearned-revenue/README.md`
- `tests/test_bookkeeping_matrix_unearned_revenue.bqn`
- `docs/archive/completed-plans/BOOKKEEPING_MATRIX_UNEARNED_REVENUE_STAGE4-2026-07-18.md`

## 検証コマンド

```text
bqn tests/test_bookkeeping_matrix_unearned_revenue.bqn
bqn tests/test_bookkeeping_matrix_prepaid_insurance.bqn
bqn tests/test_bookkeeping_matrix_payable.bqn
bqn tests/test_bookkeeping_matrix_receivable.bqn
bqn tests/test_src_next_journal_profile_stage1.bqn
bash tools/check.sh
bash tools/coverage
git diff --check origin/main...HEAD
```

## parser変更なし・production非接続境界

- `src_next/journal_profile_stage1.bqn`を変更していない
- production loader、editor、reports、Posting IR production adapter、Cube、TBDSへ接続していない
- source TSVやprivate dataを読み書きしていない
- 自動収益認識、スケジュール、recurrence、月末締め、writer、source migrationを実装していない
- parserは既存のStage 1 supported subsetをそのまま使用した

Journal Posting IR adapter parity Stage 2は同じsliceで開始しない。Stage 4の独立PRが完了・レビュー・マージされた後も、別の有限sliceとして改めて選定されるまでは未着手とする。
