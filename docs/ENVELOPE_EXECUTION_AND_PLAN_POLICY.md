# Envelope execution and plan policy

Status: current policy / readonly diagnostic and confirmation-gated plan linkage implemented
Owner: envelope / editor
Canonical: yes
Exit: revise if execution-envelope source ownership or linkage identity changes

この文書は、固定費・支払い予定・貯金・投資などを execution envelope として扱う場合に、`plan.tsv` の予定支出と二重計上しないための運用方針を固定します。

現行実装では、`EXECUTION_PLANNED_PAYMENTS_ENVELOPE` 設定時に、指定 envelope remaining と未了 planned payments 合計を照合する readonly diagnostic を `envelopes` section に表示します。さらに、`plan_id` で一意に対応する完了済み固定費予定に限り、`tools/edit plan budget-sync` が確認付きの消化行を提案・追記します。任意の差分を自動補正することはありません。

## 結論

reserve / savings / investment / fixed payment などの執行待ち資金は、サイクル中の execution envelope として active envelope remaining に含めます。

```text
active envelope remaining
  = dynamic envelope remaining
  + execution envelope remaining
```

`unassigned` は active envelope に含めず、別枠で表示します。

execution envelope の remaining は、自由に使える余りではありません。

```text
execution remaining
  まだ実行されていない確保額。
  safe-to-spend surplus ではない。
```

## 対象

execution envelope として扱えるもの:

```text
固定費予定
クレカ引落し予定
通院予定
貯金予定
投資予定
その他、サイクル中に実行するために確保した資金
```

例:

```text
budget:未割当 -> budget:固定費予定
budget:未割当 -> budget:ゆうちょ貯金
budget:未割当 -> budget:オルカン投資
```

これらは、実行前は budget layer の札付けとして見ます。

実行後の結果は actual layer 側で見ます。

```text
実行前
  budget:固定費予定 に remaining がある。

実行後
  actual layer の支出・資産移動・投資移動に反映される。
  execution envelope は必要に応じて 0 に向かう。
```

## plan.tsv との役割分担

`plan.tsv` は、将来起きる予定の actual layer 取引を表します。

execution envelope は、その予定を実行するために budget layer 上で資金を確保した状態を表します。

```text
plan.tsv
  いつ、何を、いくら支払う/移動する予定か。

execution envelope
  その予定のために、今サイクルの資金からいくら札付け済みか。
```

この2つは同じ金額を指すことがありますが、意味は違います。

## 二重計上リスク

危険なのは、同じ予定支出を次の両方で控除してしまうことです。

```text
1. plan.tsv の予定支出を outlook / usable funds で控除する。
2. 同じ予定支出を execution envelope として active remaining に含める。
```

これを safe-to-spend 計算で両方差し引くと、固定費を二重に控除してしまいます。

例:

```text
可用資金: 50000
未了予定支払い: 12000
固定費予定 envelope: 12000
```

この時、自由に使える金額を次のように計算してはいけません。

```text
50000 - 12000(plan) - 12000(envelope)
```

同じ支払い予定を二重に差し引いています。

## 採用する運用

短期運用では、固定費・支払い予定は execution envelope として確保します。

```text
budget:未割当 -> budget:固定費予定
```

plan.tsv は、支払い予定の due / completed / overdue を見るために使います。

```text
plan.tsv
  支払い予定リスト、期限、完了判定の正本。

budget:固定費予定
  その支払い予定を実行するための確保額。
```

したがって、封筒レポート上の active envelope remaining には固定費予定を含めます。

ただし、safe-to-spend / 可用資金の計算で plan と execution envelope を同時に控除しないようにします。

## 表示方針

人間向けには、次のように分けるのが望ましいです。

```text
[Dynamic envelopes]
  食費、タバコ、一般生活など。
  ペース管理する。

[Execution envelopes]
  固定費予定、通院、貯金、投資など。
  期限・実行状況を見る。

[Planned payments]
  plan.tsv 由来の予定支払い一覧。
  due / future / overdue / completed を見る。

[Backing check]
  active envelope remaining と actual funding base の照合。
```

この時、`Execution envelopes` と `Planned payments` は同じ予定を別視点で表示してよいです。

ただし、合計値を作る時は「同じ予定支出を二重に控除していないか」を明示します。

## 実行後の扱い

支払いや投資を実行したら、actual layer に取引が入ります。

その支払いが expense account の `budget=...` metadata により該当 envelope へ投影される場合、execution envelope の remaining は減ります。

`plan finish` 由来で `plan_id` が一意、対象費用が `spend_class=fixed`、設定・通貨・budget account が整合する場合は、BQN editor が同じ adjustment row を確認付きで提案します。既に同じ `plan_id` の budget row があれば冪等な適用済みとして扱います。曖昧・重複・設定不足の場合は fail closed し、人間が明示的な budget adjustment row を検討します。

例:

```text
budget:固定費予定 -> budget:spent  330
```

または、既存の投影規則で支出が `budget:固定費予定` を消費するように account metadata を整えることを検討します。

この連動は journal append と budget append を不可分と偽装しません。journal 実績化後に budget append が取消・失敗した場合は `BUDGET_SYNC_PENDING` とし、`tools/edit plan budget-sync --id ...` で再試行します。

## fail-closed policy

- plan.tsv から execution envelope を自動生成しない。
- execution envelope から plan.tsv を自動生成しない。
- 金額が一致しない場合、plan の予定額ではなく一意な journal actual の観測額を候補に使い、preview と確認を必須にする。
- due / done 判定と envelope remaining を混同しない。
- safe-to-spend 計算では plan 控除と execution envelope 控除の二重計上を避ける。

## Readonly diagnostic

設定例:

```text
EXECUTION_PLANNED_PAYMENTS_ENVELOPE=固定費予定
```

この設定がある場合、`envelopes` section は次を表示します。

```text
[Execution planned coverage]
  envelope:                 固定費予定
  envelope remaining:       ...
  unfinished planned total: ...
  envelope - planned:       ...
  status: OK / MISMATCH
```

Machine-readable summary keys:

```text
src_next_envelope_execution_planned_envelope
src_next_envelope_execution_planned_remaining
src_next_envelope_execution_planned_open_total
src_next_envelope_execution_planned_delta
src_next_envelope_execution_planned_status
src_next_envelope_execution_planned_row
```

`MISMATCH` でも自動補正しません。人間または pit が差分理由を確認し、必要なら `docs/ENVELOPE_ADJUSTMENT_ROW_POLICY.md` に従って adjustment row を追加します。

## 次に決めること

この文書では、次はまだ決めません。

```text
budget_pool=main metadata の導入要否
通常収入を未割当へ連動するための durable `txn_id` 契約
plan以外の execution event linkage
```
