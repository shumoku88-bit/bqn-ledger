# journal.tsv / plan.tsv の拡張列（6列目以降メタ情報）

位置づけ:
- 長期の方針: `docs/ENGINEERING_ROADMAP.md` (Phase 2)
- 表記ルール（キーの命名など）: `docs/CONVENTIONS.md`

このプロジェクトでは、取引の基本フォーマット（先頭5列）は固定しつつ、**6列目以降に任意のメタ情報を追加**できるようにしています。

## 基本フォーマット（必須: 5列）

TSV（TAB区切り）で以下の5列は必須です。

1. 日付 (`YYYY-MM-DD`)
2. 摘要（メモ）
3. From（出金元の勘定科目）
4. To（入金先の勘定科目）
5. 金額（数値）

## 拡張列（任意: 6列目以降）

- 6列目以降は任意個の追加列を置けます
- 推奨は `key=value` 形式（列ごとに1トークン）
- **会計計算・残高計算は先頭5列のみ使用**し、拡張列は無視します（将来の拡張用）
- 監査（StrictCheck）は「5列以上」を許容します

例:

```tsv
2026-05-24	コンビニ	assets:smbc	expenses:食費	500	tax=private	biz=0
2026-05-25	書籍	assets:smbc	expenses:学習	1800	tax=business	biz=1	invoice=none
```

## 最低限の運用ルール（今はこれだけ守ればOK）

確定申告の設計を今すべて決めなくても運用できるように、当面は **次の最小ルール**だけ守る方針にします。

- `journal.tsv` は実績のみを書く。`system_today` より未来日の行は記入ミスとしてlint/strict checkで止める
- 未来の宣言・予定は `plan.tsv` に書く
- 追加情報は **6列目以降**に置く（先頭5列は固定）
- 形式は **`key=value` を1列に1トークン**（TSVの追加列）
  - 例: `...\ttax=private\tbiz=0`
- **key は英小文字**（`tax`, `biz`, `invoice` など）
  - 表記ゆれ防止のため（`Tax` や `TAX` は使わない）
- 迷ったら **既存キーの意味を変えず、新しいキーを追加**する（後方互換を守る）

この運用なら、将来確定申告が現実になった時点でキー/値体系を固めても、TSVを壊さず移行できます。

## キー設計ガイド（暫定）

- key は **英小文字 + 数字 + `_` / `-`**（例: `tax`, `biz`, `invoice_no`）
- value は TAB を含めない（TSVが壊れるため）
- 値の体系はできるだけ固定（例: `tax=private|business|mixed` など）

### よく使いそうなキー例

- `tax=private|business` : 私用/事業用（暫定）
- `biz=0|1` : 事業按分の対象フラグ（暫定）
- `invoice=none|ok` : インボイス関連（仮）
- `note=...` : 補足（短文推奨）
- `due_on=YYYY-MM-DD` : 引落予定日の例外上書き（Phase 6実験中。通常は口座メタから導出）
- `plan_id=<id>` : `plan.tsv` の予定と、対応する `journal.tsv` 実績候補を結ぶ任意ID
- `cashflow=fixed_obligation` : 費用ではないが、生活資金から固定的に確保すべき支払い予定。例: 借金元本返済 (`assets:* -> liabilities:*`)。

※どのキーを正式採用するかは、確定申告フローが固まった時点で更新します。`plan_id` は実データの `plan.tsv` では原則として必須（バックフィル済み・新規追加時に自動付与）としますが、BQNエンジン側は互換性・手入力の非常口としてIDなし行も許容します。

## `plan_id` 命名規則

基本形:

```text
plan-YYYY-MM-DD-<series>
```

例:

```text
plan-2026-07-15-gpt-plus
plan-2026-07-16-wifi
plan-2026-08-15-rent
```

- `YYYY-MM-DD` は実績日ではなく、`plan.tsv` に置いた予定日です。
- `<series>` は原則 `series=<id>` と同じ値を使います。
- 同じ `plan_id` が既にある場合だけ、末尾に `-02`, `-03` のような連番を付けます。
- 一回予定など `series=` がない場合は、BQN editor または人間が短い識別名を補い、必要なら `-01` を付けます。

衝突時の例:

```text
plan-2026-07-15-gpt-plus
plan-2026-07-15-gpt-plus-02
```

予定日と実績日がずれても、`plan_id` は予定日のまま `journal.tsv` へ引き継ぎます。

```text
plan.tsv   : 2026-07-15 ... plan_id=plan-2026-07-15-gpt-plus
journal.tsv: 2026-07-16 ... plan_id=plan-2026-07-15-gpt-plus
```

## `plan.tsv` の繰り返し予定メタ

`plan.tsv` では、先頭5列に「次に実際に起きる予定日」を書き、6列目以降に繰り返しの性質をメモできます。

最小ルール:

- `recur=monthly` : 毎月の予定
- `recur=cycle` : 収入サイクルなど、特定イベントに連動する予定
- `recur=once` : 一回だけの予定（省略してもOK）
- `months=all` : 全月（省略時の扱い）
- `months=even` : 偶数月だけ（2,4,6,8,10,12月）
- `months=odd` : 奇数月だけ（1,3,5,7,9,11月）
- `anchor=<account>` : `recur=cycle` の基準になる勘定。例: `anchor=income:年金`
- `offset=<days>` : 基準日から何日後か。例: 当日なら `offset=0`、翌日なら `offset=1`
- `series=<id>` : 同じ定期予定を束ねる名前。例: `series=rent`, `series=pension`
- `plan_id=<id>` : 個別の予定行と、後日の実績行を結ぶ任意ID。手入力必須ではなく、将来のBQN editorが生成・引き継ぐ想定。
- `cashflow=fixed_obligation` : 固定的に確保すべきキャッシュアウト。会計上の費用に混ぜず、可用資金・資金繰りの控除候補として扱う。

例:

```tsv
2026-06-15	年金	income:年金	assets:smbc	221016	recur=cycle	series=pension	plan_id=plan-2026-06-15-pension
2026-06-15	家賃	assets:smbc	expenses:家賃	64000	recur=cycle	anchor=income:年金	offset=0	series=rent	plan_id=plan-2026-06-15-rent
2026-06-15	借金返済	assets:smbc	liabilities:友人	10000	recur=cycle	anchor=income:年金	offset=0	series=debt	cashflow=fixed_obligation	plan_id=plan-2026-06-15-debt
2026-06-16	wifi	assets:smbc	expenses:通信	4812	recur=monthly	series=wifi	plan_id=plan-2026-06-16-wifi
2026-06-24	google-one	assets:smbc	expenses:AIサブスク	1450	recur=monthly	series=google-one	plan_id=plan-2026-06-24-google-one
2026-07-01	一回だけの支払い	assets:smbc	expenses:予備	3000	recur=once	plan_id=plan-2026-07-01-once-01
```

注意:

- `#` で始まる行はコメントとして無視されるため、`plan.tsv` の見た目の区切りに使えます。
- 現時点の会計計算・予定表示は、先頭5列の日付と金額をそのまま使います。
- `recur` / `months` はまず「人間が見分けるためのメモ」です。
- `plan_id` は履行確認や Plan / Actual / Residual の対応付けに使います。
- `plan_id` は人間が毎回手で入力する前提ではありません。将来の BQN editor が予定作成時に生成し、実績化時に `journal.tsv` へ引き継ぐ想定です。実データでは原則必須とします。
- 将来、必要になったらこのメタから翌月分の予定行を生成するツールを追加できます。

## レシートを分割したいとき（複数行 + `receipt` / `txn_id`）

普段は **1レシート=1行** のままでOKです。

ただし、1枚のレシートに複数カテゴリ（趣味 + PC など）が混ざった場合は、**無理に1行へ押し込めず**、分類ごとに **複数行へ分割**します。

このとき、各行に同じ `receipt=...` を付けることで「同一レシートの束」を作れます。
さらに必要なら `txn_id=...` も併用できます（検索・集計・export向けの束ID）。

例:

```tsv
2026-06-01	ヨドバシ	assets:smbc	expenses:趣味	3000	receipt=2026-06-01_yodobashi-0001	party=ヨドバシ
2026-06-01	ヨドバシ	assets:smbc	expenses:PC	12000	receipt=2026-06-01_yodobashi-0001	party=ヨドバシ
```

- 分割した各行の金額合計が、レシート総額になるようにします
- `receipt=` は **証憑（レシート/領収書/請求書/明細）への参照**です
- `txn_id=` は **同一取引の束を識別するID**（レシート束ねに使ってもOK）
  - 形式は当面 `YYYY-0001` のような手動採番で十分です（自動採番は後回し）
- `party=`（相手先）や `note=` なども同じ束で揃えておくと後で拾いやすいです

現時点では、`txn_id` ごとの一覧・束表示は専用ツールの現行入口としては固定していません。必要になったら、source TSV を直接壊さない read-only helper として追加します。

## 現行の追記ツールでのメタ指定

- 日常入力は `tools/add-ui.sh` または `tools/edit` を使います。
- CLI で明示する場合は `tools/edit journal add ... --meta tax=private --meta biz=0` のように、`--meta key=value` を追加します。
- `tools/add-ui.sh` のメタ候補プリセットは `config/ui_meta_presets.tsv` に置きます。Shell は候補を表示するだけで、メタキーの意味解釈や検証は BQN editor / `config/meta_schema.tsv` 側に寄せます。
- 書き込みは BQN editor の preview / confirm / backup / stale check 経路を通します。
