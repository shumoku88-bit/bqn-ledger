# Envelope adjustment row policy

状態: draft / adopted operating policy / docs-only

この文書は、封筒予算の `budget_alloc.tsv` adjustment row をいつ・どの向きで追加するかを固定するための運用メモです。

この文書では実装変更、source TSV schema 変更、自動補正は行いません。

## 背景

`budget_alloc.tsv` は budget layer の配分台帳です。

封筒残高や未割当残高が実残高側の backing diagnostic とずれた場合でも、システムは `budget_alloc.tsv` を自動補正しません。

差分を調整する場合は、人間が理由を確認し、明示的な adjustment row として追記します。

## 原則

```text
adjustment row は、封筒配分を変更すると人間が決めた日に入れる。
過去の配分を黙って再解釈しない。
MISMATCH は自動補正しない。
```

adjustment row は actual layer の資産移動ではありません。

```text
actual layer
  銀行・現金・収入・支出など、実際に起きた会計事実。

budget layer
  実資金に対する封筒・未割当・執行待ちなどの札付け。
```

adjustment row は budget layer 上の札付けを変えるだけです。

## 入れるタイミング

### 1. backing diagnostic の差分を人間が調整すると決めた時

`src_next_envelope_backing_status` が `MISMATCH` の場合でも、自動では補正しません。

人間が差分を見て、予算台帳側を現金裏付け未割当に合わせると決めた時だけ、adjustment row を入れます。

例:

```text
現金裏付け未割当: 12741
予算台帳未割当:    4389
delta:             8352
```

この場合、予算台帳未割当が 8352 少ないため、次の向きで追加します。

```text
budget:opening -> budget:未割当  8352
```

意味:

```text
実残高に対して budget layer の未割当が不足していたため、
未割当に 8352 円を明示的に追加した。
```

### 2. 固定費・支払い予定のために未割当から execution envelope へ移す時

予定支払いを封筒として確保する場合は、未割当から execution envelope へ移します。

例:

```text
未了予定支払い合計: 12692
```

固定費予定封筒へ確保する場合:

```text
budget:未割当 -> budget:固定費予定  12692
```

意味:

```text
未割当だった資金を、サイクル中に実行予定の固定費支払いへ札付けした。
```

この `remaining` は自由に使える余りではありません。支払い・執行待ちの確保額です。

### 3. サイクル途中で封筒を組み替える時

生活状況により、封筒間で金額を移してよいです。

例:

```text
budget:一般生活 -> budget:食費  3000
```

意味:

```text
一般生活に札付けしていた 3000 円を、食費に振り替えた。
```

逆に封筒から未割当に戻す場合:

```text
budget:食費 -> budget:未割当  2000
```

意味:

```text
食費として確保していた 2000 円を、未割当へ戻した。
```

## 向きのルール

`budget_alloc.tsv` の `from` / `to` は、budget layer 上の札付けの移動として読む。

```text
budget:未割当 -> budget:<封筒>
  未割当から封筒へ配分する。

budget:<封筒> -> budget:未割当
  封筒から未割当へ戻す。

budget:<封筒A> -> budget:<封筒B>
  封筒Aから封筒Bへ組み替える。

budget:opening -> budget:未割当
  現金裏付け未割当へ合わせるため、予算台帳上の未割当を増やす。
```

`budget:opening` は、backing diagnostic の差分を明示的に budget ledger へ入れるための調整元として使う。

ただし、これは自動補正ではありません。人間が差分の意味を確認してから入れます。

## memo の推奨

memo は、後でなぜその調整を入れたか分かる名前にします。

推奨例:

```text
backing差分調整: 現金裏付け未割当へ合わせる
固定費予定へ配分
食費へ追加配分
食費から未割当へ戻す
予算調整(理由)
```

避ける例:

```text
調整
修正
misc
```

理由が分からない adjustment row は、後から backing diagnostic を追う時に危険です。

## source_id / metadata

現行 `budget_alloc.tsv` では必須 metadata は増やしません。

将来、調整行をより追いやすくする場合は、6列目以降に次のような metadata を検討できます。

```text
adjustment=backing_delta
adjustment=planned_execution
source_id=budget-adjust:2026-07-02-fixed-payments
```

ただし、この文書では metadata schema を変更しません。

metadata key を増やす場合は、先に `config/meta_schema.tsv` と `docs/JOURNAL_META.md` を更新します。

## fail-closed policy

- MISMATCH を見ても自動で行を追加しない。
- 差分があることと、調整してよいことを混同しない。
- `budget:未割当` が存在しない場合、勝手に account を作らない。
- 新しい envelope account を作る場合は、人間が確認し、backup を取ってから行う。
- adjustment row 追加後は report / check を実行して、backing status と残高を確認する。

## 実装・運用メモ

日常操作では approved editor path を使います。

例:

```bash
tools/edit --base <base> budget add \
  --date YYYY-MM-DD \
  --memo '固定費予定へ配分' \
  --from budget:未割当 \
  --to budget:固定費予定 \
  --amount 12692 \
  --yes
```

pit は、実データ TSV を直接編集しません。moko から明示指示がある場合だけ、approved editor path または backup 付きの小さな変更で進めます。

## 次に決めること

この文書では、次はまだ決めません。

```text
cycle seed の基準
budget_pool=main metadata の導入要否
固定費予定 envelope と plan.tsv の自動対応
execution envelope の due / done 判定
```

次の docs-only slice では、cycle seed policy を決めます。
