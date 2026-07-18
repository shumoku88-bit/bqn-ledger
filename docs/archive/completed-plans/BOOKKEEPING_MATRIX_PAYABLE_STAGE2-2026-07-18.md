# Bookkeeping Matrix Study: Service Payable Recognition and Payment Stage 2

Status: completed research fixture
Owner: other
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; future accounting topics require separately selected slices
Date: 2026-07-18

## 目的

簿記行列研究の第2題として、保守サービス費用の発生、未払金の計上、その後の銀行支払いを、journal、event × account行列、running balances、BQN assertionsの四つで一致させた。

英語の `payable` は広義の支払債務を指す。このfixtureでは、通常の営業仕入ではない保守サービスの後払いを、日本語の勘定分類に合わせて「買掛金」ではなく「未払金」として扱い、`liabilities:other-payable` で表現する。

## 二件の取引

### サービス費用の発生と未払金計上（2026-09-15）

```text
借方  expenses:maintenance       2400
貸方  liabilities:other-payable  2400
```

符号付きposting:

```text
expenses:maintenance         2400
liabilities:other-payable   -2400
```

### 未払金の支払い（2026-09-25）

```text
借方  liabilities:other-payable  2400
貸方  assets:bank                 2400
```

符号付きposting:

```text
liabilities:other-payable    2400
assets:bank                 -2400
```

## 符号規約

Posting IRでは借方方向を正、貸方方向を負とする。

- 費用の増加: 正
- 負債の増加: 負
- 負債の減少: 正
- 銀行資産の減少: 負

## event × account行列

```text
event_key	layer	assets:bank	liabilities:other-payable	expenses:maintenance	row_total
expense-on-account	actual	0	-2400	2400	0
payable-payment	actual	-2400	2400	0	0
```

各event行の合計は0であり、取引ごとの貸借一致を保持する。

## running balances

```text
event_key	assets:bank	liabilities:other-payable	expenses:maintenance
expense-on-account	0	-2400	2400
payable-payment	-2400	0	2400
```

費用発生後は未払金が `-2400`、支払い後は0になる。保守費用は支払い後も `2400` のままであり、支払時に新しい費用を認識していない。

## 会計上の核心

費用は保守サービスの提供を受けた時点で認識する。支払いが後日であることは、費用認識を支払日まで延期する理由にならない。

支払時には未払金が消滅し、銀行預金が同額減少する。これは、売掛金研究における収益認識と回収の分離に対して、費用認識と支払いを分離する鏡関係である。

## 実装と検証

追加した主な証拠:

- `fixtures/bookkeeping-matrix-payable/profile.journal`
- `fixtures/bookkeeping-matrix-payable/expected-event-account-matrix.tsv`
- `fixtures/bookkeeping-matrix-payable/expected-running-balances.tsv`
- `fixtures/bookkeeping-matrix-payable/README.md`
- `tests/test_bookkeeping_matrix_payable.bqn`

テストではStage 1 parserの結果、posting順、event × account行列、BQN scan `` +` `` によるrunning balances、最終残高、負債増減の符号を検証する。

## 非変更境界

- `src_next/journal_profile_stage1.bqn` は変更しない
- production loader、editor、reports、Posting IR production adapter、Cube、TBDSへ接続しない
- source TSVやprivate dataを読み書きしない
- 商品仕入、買掛金、棚卸資産、売上原価を同時に扱わない
- Journal Posting IR adapter parity Stage 2へ進まない

次の簿記研究題材は自動選定しない。
