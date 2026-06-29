# Report Policy Externalization Plan

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
Status: planning / design track

この文書は、レポートコード内に残っている可能性のある生活上の前提を棚卸しし、必要なものだけをTSV設定・account metadata・docs契約へ外出しするための計画である。

目的は、汎用レポートDSLを作ることではない。

目的は、mokoの生活上の名前・封筒構成・表示順・分類が変わったとき、BQNの計算芯を不用意に削らず、できるだけ宣言データの変更として扱えるようにすることである。

---

## 背景

`bqn-ledger` はすでに、正データTSVとBQN計算エンジンを分けている。

- `journal.tsv`: Actualの正データ
- `plan.tsv`: Planの正データ
- `budget_alloc.tsv`: Budget配賦の正データ
- `accounts.tsv`: account名とmetadataの正データ
- `cycle.tsv`: サイクル設定
- `config.tsv`: 特殊budget accountなどの設定
- `main.bqn` / `report_sections.bqn`: 人間向け表示入口
- `report_engine.bqn` / `src/reports/engine/*`: 派生値を計算する場所

一方で、レポート表示・健康診断・section切替の周辺には、次のような前提がコード内に残る可能性がある。

- 特定のaccount名やbudget名を特別扱いする
- `daily` / `flex` / `reserve` などの封筒groupを表示ロジックが直接知っている
- section key / alias / label / order がコード内配列として固定されている
- 表示順や表示名が、データではなくBQNコード側に寄っている
- reportが生活上の判断語を持ちすぎる

これらを一度に設定化すると、かえって理解不能な抽象化になる。したがって、まずは棚卸しし、「外に出すもの」と「コアに残すもの」を分ける。

---

## 境界

### コードに残すもの

次は、外部設定にしない。これは家計簿エンジンの芯であり、生活名ではなく計算契約である。

- TSVを読み、空列を保持すること
- journal-like TSVの先頭5列契約
- Event IR / Projection IR
- Canonical Daily Cube: `Day × Account × Layer`
- Layer契約: `actual / plan / budget / forecast`
- `BuildCube` の意味
- 金額を整数円として扱うこと
- zero-sum / layer単位の整合性検査
- reportが正データTSVを書き換えないこと
- `as_of` を観察時点として扱うこと

### 外に出す候補

次は、生活上の値・表示上の値なので、外に出す候補である。

- accountのrole / type / spend_class / budget mapping
- budget envelopeのgroup: daily / flex / reserve 等
- 特殊budget account名: opening / unassigned / spent
- sectionのenabled / order / label / alias
- accountの表示名
- accountの表示順
- reportで警告・健康診断対象にするaccount group
- 「生活封筒」「仮確保封筒」などのreport上の役割名

ただし、外に出す前に、その値が本当に変わる可能性があるか、fixtureで証明する。

---

## 方針

計算の仕組みはBQNコードに残す。

生活上の意味づけはTSVまたはmetadataへ出す。

表示の都合は、必要になったものだけ小さく設定化する。

```text
Core math / invariant        -> BQN code
Lifestyle policy             -> accounts.tsv / config.tsv / small TSV
Report presentation metadata -> optional small TSV
Human interpretation         -> docs / outside AI conversation
```

この計画は `docs/GENERALIZATION_TODO.md` の延長にある。ただし、account role一般化そのものではなく、report codeに残る生活前提を対象にする。

---

## Phase 0: 棚卸しだけを行う

目的: 実装前に、コード内の前提を一覧化する。

検索対象例:

```text
daily
flex
reserve
budget_group
spend_class
fixed
variable
saving
actual
plan
budget
forecast
snapshot
envelopes
outlook
cashflow
residual
```

見る場所:

- `src/reports/main.bqn`
- `src/reports/report_sections.bqn`
- `src/reports/report_engine.bqn`
- `src/reports/engine/*.bqn`
- `src/core/*.bqn`
- `checks/*.bqn`
- `config.bqn` / `config.tsv`
- `accounts.tsv`
- `fixtures/*/accounts.tsv`
- docs

分類:

| 分類 | 意味 | 対応 |
|---|---|---|
| core invariant | Cube / Layer / zero-sumなど | コードに残す |
| data contract | role / type / spend_class / budgetなど | docsとTSV契約へ |
| lifestyle policy | daily / flex / reserve 等の生活意味 | metadataまたはconfigへ |
| presentation | label / order / alias / section表示 | 必要なら小TSVへ |
| fixture example | fixture固有の名前 | そのままでよい |
| docs explanation | 説明文中の例 | そのまま、または現行契約へ追従 |

成果物候補:

- `docs/REPORT_ASSUMPTION_AUDIT.md`
- hard-coded assumption table
- 外に出す候補 / 残す候補 / 後回し候補

このPhaseではコードを変更しない。

---

## Phase 1: budget group契約を明文化する

目的: `daily` / `flex` / `reserve` のような封筒上の意味を、account名ではなくmetadataとして扱えるか確認する。

既存の考え方:

```tsv
expenses:食費	role=expense	spend_class=variable	budget=budget:daily
budget:daily	role=budget	budget_group=daily
budget:flex	role=budget	budget_group=flex
budget:reserve	role=budget	budget_group=reserve
```

現在の production report では、これらの group label の生活上の意味を小さな config boundary に置く。

```tsv
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
HOUSEHOLD_GROUP_ORDER=daily,flex,reserve
```

`daily` / `flex` / `reserve` は現行configの値であり、恒久的なBQNコード概念ではない。

確認すること:

- `budget_group` が現行docsで契約済みか
- production codeがbudget account名そのものを見ていないか
- `budget_group` の値を `HOUSEHOLD_GROUP_*` config経由で見れば足りる箇所はどこか
- group名を変えたfixtureでも同じ計算芯が通るか

完了条件:

- 「封筒名」と「封筒の生活上の役割」の区別を説明できる
- reportの健康診断がaccount名ではなくgroup/policyから組み立てられる候補が見える
- 実データ `accounts.tsv` は勝手に変更しない

---

## Phase 2: report presentation設定の必要性を判断する

目的: section key / alias / label / order を外部TSVにする必要があるか判断する。

候補ファイル:

```tsv
# report_sections.tsv
key	enabled	order	label	aliases
snapshot	1	10	全体サマリ	overview,summary
balances	1	30	勘定科目別残高	accounts,account,balance
envelopes	1	50	封筒/予算残高	budget,budgets
```

ただし、section dispatcherはBQN関数と強く結びつく。外部TSV化すると、存在しないsection名、重複order、alias衝突などの検査が必要になる。

判断基準:

- sectionの増減・並び替えを頻繁に行うか
- `main.bqn --list-sections` とfzf/gum UIの表示を外部から変えたいか
- labelだけの変更でBQNを触る負担が大きいか
- 逆に、設定化によって理解が難しくならないか

当面の推奨:

- まずは `docs/MAIN_SECTIONS.md` とコード内配列の同期を保つ
- section実行関数そのものはコードに残す
- `label/order/alias` の外出しは、必要性が出てから小さく行う

---

## Phase 3: account display設定を検討する

目的: account名、表示名、表示順を分ける必要があるか判断する。

候補:

```tsv
# account_display.tsv
account	label	order	show_in_report
assets:smbc	SMBC	10	1
expenses:食費	食費	100	1
budget:daily	Daily	200	1
```

または、`accounts.tsv` metadataに寄せる。

```tsv
assets:smbc	role=asset	type=liquid	label=SMBC	order=10
```

判断基準:

- account名を安定IDとして残し、表示だけ変えたいか
- reportごとに表示順が違う必要があるか
- `accounts.tsv` がmetadata過多にならないか
- 別ファイルにした場合、account未定義・重複・削除忘れのlintが必要になるか

当面の推奨:

- まずは `accounts.tsv` metadataで足りるかを見る
- 別ファイルは、reportごとに表示設定が分岐してから考える

---

## Phase 4: lint / fixtureを先に置く

外部宣言を増やす場合は、必ず検査を同時に置く。

検査候補:

- metadataに未知のrole / budget_group / spend_classがある
- `budget=...` が存在しないbudget accountを指す
- `budget_group` が必要なbudget accountにない
- required groupがない場合のreport挙動が未定義
- section aliasが重複している
- display設定が未定義accountを参照している
- display orderが重複している

fixture候補:

- budget group名を変えても計算芯が壊れないfixture
- daily/flex/reserve以外のgroupを持つfixture
- 封筒を使わないfixture
- section表示を最小にしたfixture
- account label/orderだけ変えたfixture

---

## Phase 5: 小さい置き換えだけ行う

実装する場合は、1回に1種類の前提だけを外へ出す。

よい変更例:

- `budget:daily` 直接比較を `budget_group` 参照へ置き換え、生活上のgroup label判定は `HOUSEHOLD_GROUP_*` configへ通す
- section labelだけを外出しする
- account表示順だけをmetadataから読む

悪い変更例:

- report全体を設定駆動DSLにする
- `actual / plan / budget / forecast` layer名を自由設定にする
- `BuildCube` のshapeや意味を同時に変更する
- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` を実装の都合で書き換える
- 設定ファイルにBQN式や任意コードを書けるようにする

---

## AI作業ルール

この計画をAIに進めさせる場合、次を守る。

- まず棚卸しdocsを作る。いきなり実装しない。
- 正データTSVを勝手に変更しない。
- `BuildCube` の意味を変えない。
- 出力値が変わる変更を混ぜない。
- 1 PR / 1 branch / 1契約変更にする。
- 既存fixtureで `./tools/check.sh` を通す。
- 新しい設定値を読むなら、未知値・欠損・重複のlintも同時に設計する。
- docsとfixtureなしに「汎用化しました」と言わない。
- 生活上の判断文はBQN coreへ混ぜない。
- 迷ったら、まず `docs/GENERALIZATION_TODO.md` の境界に戻る。

---

## 最初の着手候補

最初にやるのは実装ではなく、次の1ファイルを作ること。

```text
docs/REPORT_ASSUMPTION_AUDIT.md
```

内容:

```text
literal / location / kind / keep-in-code? / externalize-to / reason / next action
```

最初の検索対象は、report周辺だけに限定する。

```text
src/reports/main.bqn
src/reports/report_sections.bqn
src/reports/report_engine.bqn
src/reports/engine/*.bqn
docs/MAIN_SECTIONS.md
docs/REPORT_DESIGN.md
```

この棚卸しが終わるまで、`report_sections.tsv` や `account_display.tsv` は作らない。

---

## Current checkpoint (2026-06-29)

The current remainder has been narrowed without adding new runtime policy TSVs:

- `docs/archive/audits/REPORT_ASSUMPTION_AUDIT.md` records the current keep/externalize/defer decisions.
- `checks/check-report-labels.sh` verifies `L "..."` references against `config/report_labels.tsv`.
- `docs/archive/active-plans/ENVELOPE_TARGET_POLICY_SKETCH.md` sketches future target policy before any `envelope_targets.tsv` exists.
- `report_sections.tsv` and `account_display.tsv` remain intentionally uncreated until need + lint/fixture design are clear.

## 完了条件

この計画全体の完了条件は、次の状態である。

- report code内の生活前提が棚卸しされている
- 外に出すもの / 残すもの / 後回しにするものがdocsで説明されている
- 外部宣言が増えた場合はlintとfixtureがある (Completed: `check-src-next-lint.sh` and `fixtures/src-next-lint-failures` added on 2026-06-27)
- BQN coreは配列変換の芯として残っている
- mokoが「生活名を変えるときにどこを触るか」を説明できる
- AIが次の変更でどのdocsを読むべきか迷わない

この計画は、家計簿を巨大設定アプリにするためではない。

石に刻まれていた生活名を、必要なものだけ札に書き直すための計画である。
