# サイクル集計の変更方法

`main.bqn` の「今サイクル集計」と「見通し・日割り」は、`cycle.tsv` を編集するだけで期間を変更できます。コード変更は不要です。

設計上、cycleはEventへ固定された属性やCubeの基本軸ではありません。時間座標上から`[start, end_exclusive)`を選ぶ区間viewです。同じEventを暦月、週、別cycleで再観察できる余地を残します。

## 基本

`cycle.tsv` は `key<TAB>value` 形式です。スペースではなく **TAB区切り** で書きます。

現在使える `mode` は以下です。

- `incomeAnchor` : 収入日基準
- `fixed` : 固定期間
- `calendarMonth` : 月初〜月末

現在の`calendarMonth`は`as_of`の月ではなく、`journal.tsv`の最終日が属する月から期間を解決します。`as_of`とcycle期間解決を統一するかは未決定です。

---

## 1. 収入日基準で見る

例：年金日を基準にする場合。

```tsv
mode	incomeAnchor
income_account	income:年金
```

意味：

- `journal.tsv` にある直近の `income:年金` 入金日をサイクル開始日にする
- `plan.tsv` にある次回の `income:年金` 入金日をサイクル終了日にする
- この規則は区間境界を解決するだけで、元Eventの日付を書き換えない
- 集計範囲は内部的には **半開区間** `開始日 <= date < 終了日` になる
- 表示上は `開始日 〜 (終了日 - 1)` になる

例：

```text
内部: 2026-04-15 <= date < 2026-06-15
表示: 2026-04-15〜2026-06-14
```

これは実質 `2026-04-15〜2026-06-14` の意味です。2026-06-15 に入る収入は次サイクルの開始日となり、前サイクルには含まれません。

### 給料が毎月25日になる場合

`accounts.tsv` に `income:給料` を追加し、`journal.tsv` / `plan.tsv` に給料予定を書いたうえで、`cycle.tsv` をこうします。

```tsv
mode	incomeAnchor
income_account	income:給料
```

この場合、例えば：

- `journal.tsv` に `2026-05-25` の給料実績
- `plan.tsv` に `2026-06-25` の給料予定

があれば、集計範囲は：

```text
2026-05-25〜2026-06-24
```

になります（内部的には `2026-05-25 <= date < 2026-06-25`）。

---

## 2. 固定期間で見る

期間を手動で完全指定したい場合。

```tsv
mode	fixed
start	2026-05-25
end_exclusive	2026-06-25
```

`end_exclusive` は「その日を含まない」という意味です。

つまり上の例は：

```text
2026-05-25〜2026-06-24
```

を集計します。

一時的に確認したい期間があるときに便利です。

---

## 3. 月末締めで見る

月初〜月末で見たい場合。

```tsv
mode	calendarMonth
```

`journal.tsv` の最終日が属する月を自動で集計します。

例：`journal.tsv` の最終日が `2026-05-30` なら：

```text
2026-05-01〜2026-05-31
```

になります（内部的には `2026-05-01 <= date < 2026-06-01`）。

---

## どれを使えばいい？

### 年金・給料など、収入日から次の収入日前までを見たい

```tsv
mode	incomeAnchor
income_account	income:年金
```

または：

```tsv
mode	incomeAnchor
income_account	income:給料
```

### 毎月1日〜月末で見たい

```tsv
mode	calendarMonth
```

### その月だけ手動で調整したい

```tsv
mode	fixed
start	YYYY-MM-DD
end_exclusive	YYYY-MM-DD
```

---

## 注意

- `incomeAnchor` を使う場合、次回収入日を `plan.tsv` に書いておく必要があります。
- `income_account` に指定する科目は `accounts.tsv` に存在している必要があります。
- `fixed` の `end_exclusive` は終了日の翌日を書くのが基本です。
  - 例：6/14まで集計したい → `end_exclusive	2026-06-15`
