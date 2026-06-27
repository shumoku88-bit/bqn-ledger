# Go Source TSV Editor: Append-only Plan / Cycle Decision Note

Archive status: **superseded / historical decision note**
Archived on: 2026-06-22
Current source for active Go editor boundary: `docs/GO_EDITOR_NEXT_PLAN.md`

This note is preserved as history. Do not use it as current implementation approval.
Important current decisions were carried forward into `docs/GO_EDITOR_NEXT_PLAN.md`, including:

- keep source-of-truth as the current multiple TSV set, not a single `events.tsv`
- keep `cycle.tsv` as resolver configuration, not append-only history
- treat `.ops/` as recovery / audit records, not source-of-truth
- do not adopt `cycle_instances.tsv` or `plan_status.tsv` without a future explicit decision

---

# Original note

# Go Source TSV Editor: Append-only Plan / Cycle Decision Note

Status: **design note only / implementation not approved yet**  
Date: 2026-06-18  
Parent: `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md`

この文書は、Go source TSV editor 設計に対する追加メモである。

主に次の未決点を扱う。

- `plan.tsv` を追記式に寄せるか
- `cycle.tsv` を追記式にするか
- Go editor が plan finish / cycle edit でどこまで source TSV を変更してよいか
- 将来の event-log 化と、現行の複数TSV source-of-truth をどう接続するか

このメモは実装指示ではない。`moko` が運用上の意味を説明できるまで、apply mode や source-of-truth 変更は行わない。

---

## 1. 置き場所の判断

今回の議論は `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` に属する。

理由:

- Go editor の責務境界に関わる
- `plan.tsv` 実績化は二ファイル更新であり、Go側の安全設計と直結する
- `cycle.tsv` の編集は Go editor の対象ファイル一覧に含まれている
- `plan lifecycle` は既に同文書の未決事項である

ただし、既存の親文書は Go editor 全体の設計メモであり、今回の議論は長くなるため、まずはこの補助文書に分離する。

親文書へ統合する場合は、主に次の場所へ反映する。

- `## 10. 複数ファイル更新`
- `## 11. plan.tsv 実績化との関係`
- `## 15. 未決事項`

---

## 2. 現時点の大方針

現時点では、source-of-truth を一気に少数ファイルの event log へ統合しない。

```text
source-of-truth:
  journal.tsv
  plan.tsv
  budget_alloc.tsv
  accounts.tsv
  cycle.tsv
  config.tsv

Go:
  source TSV editor
  preview / diff / confirm
  safe append / safe edit
  atomic write / backup / stale check

BQN:
  read / validate / project / report / export
```

Goの操作感は event-log 的でよい。

しかし、source-of-truth を今すぐ単一 `events.tsv` に畳み込まない。複雑さが消えるのではなく、ファイル境界から `type=` や projection rule へ移るだけだからである。

---

## 3. plan.tsv は追記式に寄せる価値が高い

`plan.tsv` は「未来ToDoリスト」だけではなく、「何を意識していたか」の記録でもある。

そのため、予定を履行したあとに plan 行を削除すると、次の情報が失われる。

- 予定していた日付
- 予定していた金額
- 意識していた支出/収入の内容
- Plan / Actual / Residual の比較材料
- 後から「何を履行したのか」を確認する手がかり

したがって、`plan.tsv` は将来的に append-only または append-only に近い運用へ寄せる価値がある。

ただし、すぐ正式採用しない。

理由:

- 完了済み plan が future outlook に残ると邪魔になる
- Plan layer に入れるべき行と、履歴として残すだけの行を分ける必要がある
- BQN report 側に `plan_open` と `plan_all` の区別が必要になる
- Go editor の apply mode が二ファイル更新になり、operation log / recovery / idempotency が必要になる

---

## 4. plan.tsv の第一歩は plan_id

最初の安全な一歩として、`plan_id=` を任意メタとして採用する方針にする。

`plan_id` は人間が毎回手で入力する前提ではない。将来の Go editor が、予定作成時に生成し、履行時に `journal.tsv` の候補行へ引き継ぐための札である。

命名規則は次を基本形にする。

```text
plan-YYYY-MM-DD-<series>
```

例:

```tsv
2026-07-15	gpt-plus	assets:smbc	expenses:AIサブスク	3000	recur=monthly	series=gpt-plus	plan_id=plan-2026-07-15-gpt-plus
```

実績化する場合、`journal.tsv` の候補行にも同じ `plan_id=` を引き継ぐ。予定日と実績日がずれても、`plan_id` は予定日のままにする。

```tsv
2026-07-16	gpt-plus	assets:smbc	expenses:AIサブスク	3000	series=gpt-plus	plan_id=plan-2026-07-15-gpt-plus
```

同じ `plan_id` が既にある場合だけ、末尾に `-02`, `-03` のような連番を付ける。

```text
plan-2026-07-15-gpt-plus
plan-2026-07-15-gpt-plus-02
```

この段階では、Go editor は `plan.tsv` を削除・更新しない。

```text
plan.tsv に plan_id がある
journal.tsv に同じ plan_id がある
=> 履行済み候補として観察できる

plan.tsv に plan_id がある
journal.tsv に同じ plan_id がない
=> 未履行 / 未発生 / 取消未記録の候補として観察できる
```

`plan_id` は最初から全行必須にしない。

固定費、大きな一回払い、日付をまたいでも追跡したい予定から任意導入する。

ただし、現在の実データは記録期間が短いため、既存 `plan.tsv` 行は `plan_id` backfill 対象にする。`plan_id` がない行の互換規則を長く育てるより、既存予定にIDを付けて揃える方針とする。

---

## 5. Go editor 上の plan_id の扱い

将来の Go editor では、入力の面倒さをユーザーへ押し付けない。

想定する操作感:

```text
kedit plan finish
  ↓
未履行っぽい予定を一覧する
  ↓
「この予定は払った/発生した」を選ぶ
  ↓
Go が plan_id を持つ journal 候補を作る
  ↓
preview / diff / confirm
  ↓
apply mode が承認済みなら journal.tsv へ安全に書く
```

この場合、ユーザーは通常 `plan_id` を直接入力しない。

Go editor がやる候補:

- `plan add` 時に `plan-YYYY-MM-DD-<series>` 形式の `plan_id` を自動生成する
- 既存 plan に `plan_id` がない場合、finish preview 時に正規のbackfill候補IDを表示する
- journal 候補へ同じ `plan_id` を引き継ぐ
- 同じ `plan_id` の journal 行が既に存在する場合、二重記帳を警告または拒否する

ただし、これは apply mode の実装許可ではない。まず preview-only で設計を確認する。

---

## 6. open plan と historical plan を分ける

`plan_open` / `plan_all` は採用方針とする。

履行済み予定は、未来予定の見通しからは外す。一方で、履歴・Residual観察には残す。

```text
plan_open:
  まだ履行・取消・失効していない予定。
  outlook / fixed reserve / future cashflow に使う。

plan_all または plan_declared:
  過去に意識・宣言された予定を含む記録。
  Residual / Plan vs Actual / 履行確認に使う。
```

第一規則として、`journal.tsv` に同じ `plan_id` が存在する `plan.tsv` 行は `plan_open` から除外する。

```text
plan.tsv:
  ... plan_id=plan-2026-07-15-gpt-plus

journal.tsv:
  ... plan_id=plan-2026-07-15-gpt-plus

=> この plan は plan_open ではない
=> plan_all / Residual / 履行確認には残る
```

`plan_id` がない既存 plan 行は、原則として backfill してからこの規則に乗せる。記録期間が短い間は、例外処理よりID付与で正規化する。

この区別なしに `plan.tsv` を追記式にすると、完了済みPlanがいつまでも「これから起きる予定」として残る。

したがって、Go editor の `plan finish apply` より先に、BQN report contract で次を固定する必要がある。

- `journal.tsv` に同じ `plan_id` がある場合の履行済み判定
- `plan_id` backfill の手順
- `plan_all` をどの report / export が読むか
- status metadata や `plan_status.tsv` を将来導入した場合の優先順位

---

## 7. plan lifecycle の候補

現時点での候補は次の通り。

### A. plan行を削除する

ToDoリストとしては自然。

しかし、Residualや履行確認の材料が失われる。

### B. plan行を残す

履歴としては自然。

しかし、open / done / cancelled / expired を区別しないと outlook が濁る。

### C. plan行に status metadata を付ける

例:

```tsv
2026-07-15	gpt-plus	assets:smbc	expenses:AIサブスク	3000	series=gpt-plus	plan_id=plan-2026-07-15-gpt-plus	status=done	actual_date=2026-07-15
```

ただし、これは `plan.tsv` を上書き編集する。Go editor の safe edit / stale check / backup / post lint が必要になる。

### D. plan_status.tsv を追加する

例:

```tsv
date	plan_id	action	note
2026-07-15	plan-2026-07-15-gpt-plus	done	journal_id=...
2026-07-16	plan-2026-07-16-wifi	moved	to=2026-07-17
```

`plan.tsv` は宣言ログとして残し、状態変化を別ログへ追記する。

分析上は美しいが、source-of-truth が増える。BQN loader / lint / report contract が必要になる。

当面は次の方針にする。

- `plan finish` は preview-only のまま
- `plan_id=` は任意メタとして採用方針
- `plan_id` 命名規則は `plan-YYYY-MM-DD-<series>`、衝突時のみ `-02`, `-03`
- 既存 `plan.tsv` 行は `plan_id` backfill 対象
- `plan_open` / `plan_all` は採用方針
- 第一規則として、`journal.tsv` に同じ `plan_id` がある plan は `plan_open` から除外する
- Go editor は plan行を勝手に削除しない
- Go editor は plan行を勝手に `status=done` にしない
- `plan_open` の除外条件と `plan_all` の利用範囲を report contract で固定するまで apply mode を実装しない

---

## 8. cycle.tsv は追記式にしない

`cycle.tsv` は `plan.tsv` と性質が違う。

`plan.tsv` は「意識したEvent」を置く場所である。

一方、`cycle.tsv` はEventではなく、時間座標上から `[start, end_exclusive)` を選ぶための **period view / resolver config** である。

したがって、`cycle.tsv` を append-only 履歴台帳に変えるのは避ける。

```text
cycle.tsv:
  現在どのルールでcycleを解決するか
  mode=incomeAnchor / fixed / calendarMonth など

not:
  過去サイクル境界の全履歴ログ
```

Go editor が最初に扱う `cycle` 操作は、現在の key/value 設定の表示・変更に限定する。

```sh
kedit cycle show
kedit cycle set mode incomeAnchor
kedit cycle set income_account income:年金
```

---

## 9. historical cycle は resolver を先に固める

過去サイクルを見たい場合、まずはBQN側で read-only resolver を安定させる。

優先順:

1. `incomeAnchor` の historical-cycle resolver を pure/read-only で作る
2. start と end_exclusive の両方が揃わない場合は `unavailable` にする
3. sentinel date による all-history fallback を禁止する
4. fixtureで境界を固定する
5. その後、必要なら materialized cycle instances を検討する

手動で確定サイクルを保存したくなった場合は、`cycle.tsv` を追記式にするのではなく、別ファイル案として扱う。

```tsv
# cycle_instances.tsv candidate
cycle_id	start	end_exclusive	basis	note
2026-04-pension	2026-04-15	2026-06-15	income:年金	
2026-06-pension	2026-06-15	2026-08-14	income:年金	
```

ただし、これは現時点では未採用。

`cycle_instances.tsv` を採用するなら、それは resolver の cache / override / explicit period table のどれなのかを先に決める。

---

## 10. operation log と event log は別物

Go editor の `.ops/<timestamp>-<id>.json` は、source-of-truth ではなく recovery / retry / audit のための operation record である。

将来、操作ログから source TSV を再生成する実験はあり得る。

しかし現時点では、次を混ぜない。

```text
operation log:
  Go editor の安全な復旧・再試行のためのログ

source TSV:
  BQN が読む正データ

event log source-of-truth:
  将来の別設計候補。現時点では採用しない。
```

---

## 11. Go editor 実装への影響

### 先に実装してよい候補

- `journal add` の dry-run
- `journal add` の safe append
- `budget add` の dry-run
- `budget add` の safe append
- `plan list`
- `plan finish` の preview統合
- `cycle show`
- `cycle set` の preview / confirm

### まだ実装しない候補

- `plan finish apply`
- plan行の削除
- plan行の `status=done` 自動付与
- `plan_done.tsv` への移動
- `plan_status.tsv` の正式採用
- `cycle.tsv` の append-only 化
- `cycle_instances.tsv` の正式採用
- operation log からの source TSV 再生成

---

## 12. 決定メモ

現時点の判断:

```text
plan.tsv:
  追記式へ寄せる価値が高い。
  plan_id は任意メタとして採用方針。
  plan_id 命名規則は plan-YYYY-MM-DD-<series>。
  衝突時のみ -02, -03 を付ける。
  既存 plan.tsv 行は plan_id backfill 対象。
  plan_open / plan_all は採用方針。
  journal.tsv に同じ plan_id がある plan は plan_open から除外する。
  履行済み予定は未来見通しから外し、履歴・Residual観察には残す。
  Go apply はまだ禁止。

cycle.tsv:
  追記式にしない。
  現在のresolver設定として維持する。
  historical cycle はBQN resolverとfixtureで先に固める。

Go editor:
  操作感はevent-likeでよい。
  plan_id はGoが生成・引き継ぐ想定。
  しかしsource-of-truthを単一event logへ今すぐ畳み込まない。
```

合言葉:

```text
Planは記憶に近い。
Cycleは窓に近い。
Goは手袋。
BQNは秤。
```

Planは、何を意識していたかを後から見るために残す価値がある。  
Cycleは、出来事そのものではなく、時間座標を見るための窓である。  
この二つを同じ append-only 方針で扱わない。
