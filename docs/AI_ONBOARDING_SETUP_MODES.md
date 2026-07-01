# AI補助セットアップモード草案

状態: draft / discussion-only / docs-only

この文書は、bqn-ledger を初めて使う人が、自分の契約している AI サービスに助けてもらいながら初期セットアップを始めるための草案です。

想定する AI サービスは、Codex、Claude Code、Gemini CLI、またはその他のターミナル上で使う AI コーディングアシスタントです。

この文書の目的は、bqn-ledger を完全自動化することではありません。

目的は、初心者でも最初の使える ledger を作れるようにしつつ、正データは意識して扱う、という bqn-ledger の中核ルールを守ることです。

## 中核の考え

初心者は、ターミナルを開き、自分の AI アシスタントを起動して、次のように話しかけられる状態を目指します。

```text
bqn-ledger の初期セットアップをしたいです。
このリポジトリの docs/AI_ONBOARDING_SETUP_MODES.md を読んで、質問しながら進めてください。
```

AI アシスタントは、ユーザーに質問し、初期 TSV ファイルを作り、最後に内容を要約して確認を取ります。

セットアップ完了後、AI アシスタントはより制限の強い daily-use mode に切り替わります。

## 初心者向けターミナル導線の草案

Mac 初心者向けには、将来次のような案内を書くかもしれません。

```text
1. Mac を起動します。
2. Command + Space を押します。
3. terminal と入力します。
4. Enter を押します。
5. ターミナルに、自分が契約している AI サービスのコマンドを入力します。
   例:
   codex
   claude
   gemini
   agy
6. Enter を押します。
7. AI にこう話しかけます。
   bqn-ledger の初期セットアップをしたいです。
```

これはまだ草案です。完成したインストール手順として扱ってはいけません。

## モード

### 1. initial setup mode

initial setup mode は、最初の使える ledger がまだ存在しない状態で有効になります。

このモードでは、AI アシスタントは初期 canonical TSV ファイルを作成・編集してよいです。

理由は、初心者が最初から `accounts.tsv` や `journal.tsv` や `cycle.tsv` を手で作れるとは限らないからです。

作成候補のファイル:

```text
data/accounts.tsv
data/journal.tsv
data/cycle.tsv
data/plan.tsv
data/budget_alloc.tsv
```

AI アシスタントは、少なくとも次のことを質問します。

- セットアップ開始日
- 管理したい口座
- 各口座の開始残高
- 次の収入日、または生活サイクルの境界
- 現金を管理するか
- 支払い予定を最初から入れるか
- 封筒予算管理を今は使わずに後回しにするか

initial setup の最後に、AI アシスタントは生成した内容を要約し、次のように確認します。

```text
この内容で bqn-ledger を開始してよいですか？
```

ユーザーが確認するまでは、セットアップ完了とは扱いません。

### 2. daily-use mode

daily-use mode は、initial setup が完了したあとに有効になります。

このモードでは、AI アシスタントはファイルを読み、レポートを説明し、相談に乗り、編集案を提案できます。

ただし、ユーザーが明示的に編集を指示しない限り、canonical TSV ファイルを編集してはいけません。

編集許可にならない相談例:

```text
今日のお金の状況を見て。
次の収入日まで持ちそう？
食費を使いすぎてる？
今期の予算をどうしたらいい？
```

明示的な編集指示の例:

```text
journal.tsv に今日の支出を追記して。
plan.tsv のこの予定を完了扱いにして。
accounts.tsv に新しい支出カテゴリを追加して。
budget_alloc.tsv をこの内容で更新して。
```

### 3. plan setup mode

ユーザーは、初期セットアップの時点で予定管理を理解しているとは限りません。

plan setup mode は、あとから `plan.tsv` を作成・見直しするための補助モードです。

次のような発言で入ることを想定します。

```text
予定管理を始めたい。
固定費の予定を bqn-ledger に入れたい。
plan.tsv の使い方を一緒に整理したい。
```

`plan.tsv` は重要ですが、`journal.tsv` より危険度は低いです。

`plan.tsv` は履歴の証拠ではなく、予定や見込みを表すものだからです。

AI アシスタントは、このモードでは比較的積極的に手伝ってよいです。

ただし、ユーザーが不慣れな場合は、適用前に変更内容を要約して確認します。

### 4. budget / envelope setup mode

ユーザーは、最初の日から封筒予算管理を使いたいとは限りません。

budget / envelope setup mode は、`budget_alloc.tsv` や、予算グループに関係する account metadata をあとから作成・見直しするための補助モードです。

次のような発言で入ることを想定します。

```text
封筒予算管理を始めたい。
食費だけ予算管理したい。
今期の budget_alloc.tsv を一緒に作りたい。
```

予算データは実験してよい領域です。

間違っていればレポートは役に立たなくなるかもしれませんが、歴史的な実績である journal は残ります。

### 5. repair / review mode

repair / review mode は、レポート出力が矛盾して見えるときや、何かがおかしいと感じたときに使う確認モードです。

AI アシスタントは、まずレポートと TSV ファイルを読み、編集せずに調査します。

問題の場所が journal data、account metadata、plan data、budget data、report interpretation のどれに近いかを切り分けます。

編集ルールは、ファイル保護レベルとユーザーの明示指示に従います。

## ファイル保護レベル

すべての TSV ファイルが同じ重さではありません。

### 強く保護するファイル

```text
data/journal.tsv
```

`journal.tsv` は歴史的な実績の証拠です。

実際に何が起きたかを記録します。

ユーザーの明示指示なしに編集してはいけません。

`journal.tsv` の編集は、基本的には追記を優先します。

修正が必要な場合は、明確な修正エントリ、または説明された対象行編集を優先します。

### 保護するファイル

```text
data/accounts.tsv
data/cycle.tsv
```

これらのファイルは、レポートの解釈を形作ります。

ユーザーの明示指示があれば編集してよいですが、口座名の変更や削除など破壊的な変更を行う場合は、レポートへの影響を説明します。

### 柔軟・実験的に扱えるファイル

```text
data/plan.tsv
data/budget_alloc.tsv
```

これらのファイルは予定や予算を表します。

レポートにとって重要ですが、壊れても歴史的な journal は残ります。

AI アシスタントは、plan setup mode や budget / envelope setup mode の中では、比較的積極的にセットアップを手伝ってよいです。

## setup-complete marker の草案

将来の実装では、initial setup の完了後に小さな marker を作るかもしれません。

例:

```text
data/.setup-complete
```

または:

```text
data/SETUP_STATE.tsv
```

この marker によって、AI アシスタントや補助ツールが、initial setup mode は終わり、daily-use mode を適用すべきだと判断できます。

これは設計アイデアです。この草案では実装を指定しません。

## この草案でやらないこと

- まだ setup wizard は実装しません。
- 現在のレポート動作は変更しません。
- canonical TSV format はまだ変更しません。
- AI による編集を不可能にはしません。
- AI が canonical files を無断で編集できる状態にはしません。

## 未決定事項

- どの言葉を「明示的な編集許可」とみなすか。
- initial setup は直接 `data/` に書くべきか、まず `setup-draft/` に書くべきか。
- `journal.tsv` の修正は、方針として append-only を優先すべきか。
- plan / budget setup modes では、すべての書き込み前に確認が必要か。
- 初心者向けの最小セットアップはどこまでか。
- Mac 以外のユーザーをどう案内するか。

## merge readiness checklist

この PR は、onboarding policy がもう少し明確になるまでマージしません。

- [ ] initial setup mode が AI アシスタントに十分明確に定義されている。
- [ ] daily-use edit rules が曖昧ではない。
- [ ] `journal.tsv` protection level が合意されている。
- [ ] `plan.tsv` setup mode が説明されている。
- [ ] budget / envelope setup mode が説明されている。
- [ ] 初心者向けターミナル導線が慎重に書かれている。
- [ ] AI prompt examples を会話で試している。
- [ ] merge readiness を別途レビューしている。
