# Envelope role design

状態: adopted direction / docs-only / implementation pending

この文書は、bqn-ledger の封筒予算を「金額の箱」ではなく、生活判断上の役割を持つ budget layer として整理するための設計メモです。

この PR では、封筒 role の初期3分類と短期方針だけを採用します。実装変更、source TSV schema 変更、実データ変更は行いません。

## 採用する短期方針

この文書で採用する短期方針は次の通りです。

```text
initial envelope roles
  dynamic
  execution
  unassigned

active envelope remaining
  dynamic + execution の remaining 合計。

unassigned
  active envelope には含めず、別枠で表示する。
  account が存在しない場合も自動生成しない。

unknown role
  active envelope には含めない。
  表示できる範囲で表示し、pace / execution advice はしない。

backing diagnostic
  readonly のまま維持する。
  不一致があっても budget_alloc.tsv を自動補正しない。
```

この方針は `docs/ENVELOPE_FUNDING_BASE_INVARIANT.md` の hybrid backing policy と組み合わせて扱います。

この文書でまだ決めないこと:

```text
adjustment row の具体的な format / memo / source_id / 向き（`docs/ENVELOPE_ADJUSTMENT_ROW_POLICY.md` で運用方針を定義）
cycle seed の基準
budget_pool=main metadata の導入要否
report grouping の実装方法
実データ accounts.tsv / budget_alloc.tsv の移行
```

## 背景

封筒予算では、すべての封筒が同じように見えやすいです。

```text
allocated
spent
remaining
status
```

しかし、同じ `remaining` でも、封筒の種類によって意味が違います。

```text
食費の remaining
  まだ生活に使える余力。
  余っていることが安全。

貯金・投資・支払い予定の remaining
  まだ実行されていない確保額。
  実行後に 0 になることが自然。

未割当の remaining
  まだ何にも割り当てていない資金。
  生活判断や実行予定とは別の保留枠。
```

これらを同じ health 判定で扱うと、使い切りたくない封筒と、実行して 0 にしたい封筒が混ざります。

## 目的

封筒を次の3つの基本 role に分けます。

```text
dynamic
execution
unassigned
```

この3分類は、封筒の数や名前を固定するためではありません。

目的は、封筒ごとの判定・表示・将来拡張を安全に分けることです。

## 基本 role

### dynamic envelope

```text
envelope_role=dynamic
```

意味:

```text
日々の支出ペースを観察する封筒。
使い切ることを目的にしない。
残っているほど安全。
```

例:

```text
食費
タバコ
一般生活
日用品
変動費
```

主な診断:

```text
allocated
spent
remaining
avg/day
days left
pace status
```

代表 status:

```text
SAFE
WARN
SHORT
OVER
```

### execution envelope

```text
envelope_role=execution
```

意味:

```text
支払い・貯金・投資など、予定された行為を実行するために確保する封筒。
使い切るというより、執行完了する封筒。
実行後に remaining が 0 になることが自然。
```

例:

```text
固定支払い予定
通院予定
ゆうちょ貯金
オルカン投資
クレカ引落し予定
```

主な診断:

```text
held amount
planned execution
actual execution
remaining to execute
due status
```

代表 status:

```text
HELD
DUE
DONE
MISSING
LATE
DRAWN
```

### unassigned envelope

```text
envelope_role=unassigned
```

意味:

```text
まだ何にも割り当てていない資金。
目的別封筒ではなく、保留中の配分残。
```

この role は optional です。

`unassigned` envelope が存在する場合、budget layer 上の未割当残高を明示できます。

`unassigned` envelope が存在しない場合でも、report は落ちず、cash-backed 未割当を readonly diagnostic として表示できます。

## optional unassigned policy

未割当封筒は必須にしません。

理由:

```text
必須にすると、入力が窮屈になる。
禁止すると、budget_alloc.tsv 上の配分残を追いにくい。
```

したがって、方針は次の通りです。

```text
unassigned envelope exists
  ledger unassigned として表示する。

unassigned envelope missing
  status を unavailable/no_unassigned_account などにする。
  cash-backed diagnostic は可能な範囲で表示する。
  自動生成や自動補正はしない。
```

## future role tolerance

将来、現在の3分類とは違う role の封筒を作れるようにします。

例:

```text
sinking
reserve
challenge
reimbursement
debt_payment
gift
```

未知の `envelope_role` は fail-closed で扱います。

```text
unknown role
  表示はする。
  金額は集計できる範囲で表示する。
  pace / execution advice はしない。
  status は unknown_role などにする。
  automatic correction はしない。
```

これにより、将来の封筒拡張が既存レポートを壊しにくくなります。

## metadata sketch

将来、`accounts.tsv` で role を表すなら、次のような metadata が考えられます。

```tsv
budget:食費	role=budget	envelope_role=dynamic	group=daily
budget:タバコ	role=budget	envelope_role=dynamic	group=daily
budget:一般生活	role=budget	envelope_role=dynamic	group=flex
budget:ゆうちょ貯金	role=budget	envelope_role=execution	group=reserve
budget:オルカン投資	role=budget	envelope_role=execution	group=reserve
budget:未割当	role=budget	envelope_role=unassigned
```

既存の `kind=envelope` / `kind=unassigned` との関係は未決定です。

互換性を優先するなら、最初は既存 metadata を維持し、追加 field として `envelope_role` を導入する方が安全です。

## layer boundary

封筒 role は budget layer の意味を整理するためのものです。

```text
actual layer
  実際に起きた資産・負債・収支。

plan layer
  これから起きる予定。

budget layer
  資金に対する意図・配分・保留。

backing diagnostic
  budget layer の封筒残高が actual asset で裏付けられているかを見る readonly check。
```

`envelope_role` は actual layer の勘定分類ではありません。

また、`envelope_role` は asset の liquidity 分類でもありません。

## backing diagnostic との関係

封筒 role は backing diagnostic と組み合わせて使います。

```text
封筒対象資金
= actual asset 側の暫定 funding base

active envelope remaining
= dynamic + execution の remaining 合計

ledger unassigned
= unassigned envelope の budget layer 残高

cash-backed unassigned
= 封筒対象資金 - active envelope remaining

delta
= cash-backed unassigned - ledger unassigned
```

この計算は readonly diagnostic です。

不一致があっても、自動補正しません。

## active envelope definition

初期方針では、active envelope は次の role を含みます。

```text
dynamic
execution
```

`unassigned` は active envelope には含めず、別枠で表示します。

未知の role は最初は active envelope に含めません。必要になったら docs と実装を更新して明示的に扱います。

## cycle-local execution policy

`execution` envelope は、サイクル中の執行待ちラベルとして扱います。

貯金、投資、固定支払い、通院予定、クレカ引落し予定などは、現在サイクル内では `execution` envelope として表現できます。

この場合の `remaining` は、生活に自由に使える余りではありません。

```text
execution remaining
  まだ実行されていない確保額。
  safe-to-spend surplus ではない。
```

執行が完了すると、その envelope の remaining は 0 に向かいます。

完了後の結果は、budget layer ではなく actual layer の資産・負債・投資・支出側で観察します。

```text
サイクル中
  budget:オルカン投資
    投資実行待ちの確保額。

実行後
  actual asset / investment 側
    実際に移動した資産、または支出・振替結果。
```

次のサイクル境界では、封筒配分を永続 account balance として引き継ぐとは限りません。

新しいサイクルの収入、支払い予定、生活状況、貯金・投資方針に応じて、封筒を re-seed / reallocate します。

サイクル途中の組み替えも許容します。

ただし、組み替えは過去の配分を黙って解釈し直すのではなく、明示的な `budget_alloc.tsv` adjustment row として残す方針を優先します。

adjustment row の具体的な運用方針は `docs/ENVELOPE_ADJUSTMENT_ROW_POLICY.md` で扱います。この文書では、cycle seed 基準はまだ決めません。

## human report sketch

人間向け表示は、role ごとに分けます。

```text
[Dynamic envelopes]
  group | envelope | allocated | spent | remaining | avg/day | health

[Execution envelopes]
  group | envelope | held | executed | remaining | due | status

[Unassigned]
  ledger unassigned: ...

[Backing check]
  封筒対象資金: ...
  active封筒残高合計: ...
  現金裏付け未割当: ...
  予算台帳未割当: ...
  delta: ...
  status: ...
```

## machine-readable sketch

将来 machine-readable rows を出すなら、次のような形を検討します。

```text
src_next_envelope_row:
  account
  label
  envelope_role
  group
  allocated
  spent_or_executed
  remaining
  status
```

ただし、この PR では machine-readable key を追加・変更しません。

## non-goals

この文書では、次のことはしません。

- 実装を変更しない
- `accounts.tsv` schema を変更しない
- `budget_alloc.tsv` format を変更しない
- `journal.tsv` format を変更しない
- `type=liquid` を変更しない
- `budget_pool=main` を導入しない
- `envelope_role` を必須にしない
- unknown role の具体的な計算を実装しない
- unassigned envelope を必須にしない
- automatic correction を導入しない

## implementation phases

### Phase 1: docs-only

この文書で、封筒 role の初期3分類と短期方針を固定します。

### Phase 2: metadata inventory

既存 `accounts.tsv` / fixtures の budget accounts を、次の3分類に手で棚卸しします。

```text
dynamic
execution
unassigned
```

この段階でも source TSV の形式は変えません。

### Phase 3: report grouping

human report を role ごとに分けます。

ただし、role の正本をどこに置くかを先に決めます。実データ `accounts.tsv` に `envelope_role=...` を導入する場合は、metadata schema / docs / fixture / check を同じ単位で更新します。

未知 role は表示のみ、診断なしにします。

### Phase 4: optional metadata

必要なら `envelope_role=...` を account metadata に導入します。

導入する場合も、未指定 account は fail-closed で扱います。

## conclusion

封筒は、少なくとも次の3つの role に分ける方針を採用します。

```text
dynamic
  使い切りたくない運用型封筒。

execution
  支払い・貯金・投資などを実行する執行型封筒。

unassigned
  まだ何にも割り当てていない未割当封筒。
```

この3分類は固定された完成形ではなく、将来 role を増やすための最小の足場です。

最初から拡張枠を無理に使う必要はありません。

未割当封筒も、必須ではなく optional として扱います。

重要なのは、封筒の残高を全部同じ意味で読まないことです。

封筒の role を分けることで、生活判断、予定執行、未決定資金、現金裏付け診断を混ぜずに扱えるようにします。
