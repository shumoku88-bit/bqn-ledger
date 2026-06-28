# AI Agent Efficiency Plan

最終更新日: 2026-06-22
ステータス: **docs-only plan / 実装前の候補整理**

## 目的

AI が `bqn-ledger` を保守するときの無駄を減らすための計画です。

ここでいう無駄は、主に次のものです。

- 関係ファイルを探し回る。
- BQN の shape / box / 空列保持で同じ種類の失敗を繰り返す。
- check / fixture / docs の接続を見落とす。
- 変更後の影響範囲を巨大な出力や diff から読もうとする。
- 作業報告が長すぎる、または短すぎて安全情報が欠ける。

この文書は、すぐに全部を実装するためのものではありません。
次に Gemini / Codex / local agent へ渡す作業を小さく切るための棚札です。

## 現状の観察

### 1. 狭い task packet は効いている

`missing-budget-mapping` negative fixture の追加作業では、読む文書、触ってよいファイル、触ってはいけない境界、期待する check を先に絞ったことで、作業が小さく収まりました。

これは、巨大な自律作業よりも、次の形式が効きやすいことを示しています。

```text
read:
allowed files:
forbidden files:
expected checks:
report format:
```

### 2. 既存 check / fixture の地図がまだ弱い

AI は `checks/check.sh`、個別 check、fixture、lint、docs の関係を毎回探索しがちです。

`tools/sqz-report` は出力を絞る道具ですが、探索前に「どのファイルを読めばよいか」を教えるものではありません。
探索を減らすには、repo 内の浅い索引が必要です。

### 3. check script の boilerplate は繰り返しが多い

`check-missing-budget-mapping.sh` のような shell check を作るとき、毎回次の boilerplate が必要になります。

- `set -euo pipefail`
- `SCRIPT_DIR` 解決
- repo root への `cd`
- `mktemp`
- `trap` cleanup
- `assert_fail` 的な helper

これは AI が毎回読み直してコピーするには、少し石畳が長い部分です。

### 4. fragile test が発生した

`bqn-eval` の error message が変わったとき、`check-negative.sh` の期待文言が古くなり、テストが落ちました。

これは良い検出でもありますが、長い文言への依存が強いと、道具改善のたびに test 側が壊れやすくなります。

### 5. 短い出力は有効だが、省略してはいけない情報がある

LLM の出力を短くする方向は有用です。
ただし、bqn-ledger では `data/*.tsv`、`BuildCube`、Layer 契約、test 実行有無などを省略すると危険です。

短くする場合は、自由な短文ではなく、安全チェックリスト形式にします。

## 候補一覧

### A. AI output checklist

Caveman-style の短縮出力を、そのまま使うのではなく、作業後報告の checklist に変換します。

```text
変更:
- ...

実行:
- ...

未実行:
- ...

触っていない:
- data/*.tsv
- BuildCube shape / layer contract

リスク:
- ...
```

狙い:

- 出力トークンを減らす。
- ただし安全情報は削らない。
- 人間レビュー時に見る場所を固定する。

優先度: **高**
実装コスト: **低**
リスク: **低**

### B. Fragile test 防止

error message の完全一致や長文依存を減らします。

候補:

- `assert_fail` は exit status を主に見る。
- message grep は `Usage:` / `error:` などの抽象 keyword に寄せる。
- 必要なら tools 側に `E_MISSING_EXPR` のような error code を出す。
- human-facing 文言と machine-facing code を分ける。

優先度: **高**
実装コスト: **低〜中**
リスク: **低**

### C. CodeGraph-lite / repo-index

Semmle / CodeGraph / RepoGraph 的な「構造を先に索引化する」候補です。

ただし、初期版では BQN の完全 parser や AST 解析は目指しません。
まずは BQN を含む repo を、浅い規則で高速に案内できるようにします。

候補名:

```text
tools/repo-index
docs/AI_REPO_MAP.md
```

拾う情報:

- file path
- file kind: bqn / sh / go / docs / fixture / tsv
- BQN import: `•Import "..."`
- BQN definition: `name ←` / `name ⇐`
- check scripts
- `checks/check.sh` から呼ばれる scripts
- fixtures 一覧
- fixture README の短い説明
- exporter scripts
- report section names
- important docs

出力形式候補:

```text
path	kind	name	target	note
```

または JSON lines。

狙い:

- AI が関係ファイルを探し回る時間を減らす。
- `grep` / `find` の往復を減らす。
- task packet の `read:` 欄を作りやすくする。

優先度: **高**
実装コスト: **中**
リスク: **低**

### D. check script scaffolder

新しい shell check の雛形を作る道具です。

候補名:

```text
tools/scaffold-check.sh <name>
```

生成先:

```text
checks/check-<name>.sh
```

含めるもの:

- `set -euo pipefail`
- `SCRIPT_DIR` / `ROOT_DIR`
- repo root への `cd`
- `tmp=$(mktemp)`
- `trap` cleanup
- placeholder `assert_fail`
- TODO marker

狙い:

- boilerplate のコピペミスを減らす。
- AI が既存 check を読み回る量を減らす。
- negative fixture 追加を定型化する。

優先度: **中〜高**
実装コスト: **低**
リスク: **低**

### E. sqz-report impact summary mode

`tools/sqz-report` に、変更前後の report numbers を比較し、変化した key だけを出す mode を追加する候補です。

候補:

```text
tools/sqz-report <base> --as-of YYYY-MM-DD --impact-summary <before.tsv>
```

または、git worktree / baseline file を使う方式。

狙い:

- AI が巨大な report diff を読まずに済む。
- 予想外の封筒、予測、cycle、summary への影響を見つけやすくする。
- 数値変更系 task のレビューを軽くする。

注意:

- stable key contract が必要。
- baseline の取り方を先に決める必要がある。
- 最初から大きく作らない。

優先度: **中**
実装コスト: **中〜高**
リスク: **中**

### F. 本格 CodeGraph / Semmle / CodeQL 系

候補として残しますが、今すぐ実装しません。

理由:

- BQN の深い parser / extractor が必要になりやすい。
- 既製の CodeQL / Semmle 的解析は、BQN core にそのまま効く可能性が低い。
- Go editor / shell 周辺には将来効く可能性がある。
- 現時点では CodeGraph-lite / repo-index のほうが費用対効果が高い。

優先度: **低**
実装コスト: **高**
リスク: **中〜高**

## 推奨順序

### 1. AI output checklist を task packet に入れる

まずはコード不要で、Gemini / Codex への指示書末尾に追加します。

目的は、短い報告にしつつ、次を省略させないことです。

- changed files
- tests run
- tests not run
- `data/*.tsv` touched? yes/no
- `BuildCube` / Cube shape / layer contract touched? yes/no
- risk / uncertainty

### 2. Fragile test 防止を小さく進める

`check-negative.sh` と関連 tools の error assertion を見直します。

最初の範囲:

- 完全一致になっている箇所を調べる。
- exit status 主体にできるところを分ける。
- machine-readable error code が必要かどうかを判断する。

### 3. CodeGraph-lite / repo-index の設計メモを書く

いきなり実装しません。
まず、MVP が拾う field と出力形式を決めます。

設計メモ候補:

```text
docs/REPO_INDEX_DESIGN.md
```

### 4. repo-index MVP を作る

最初の MVP は shell / awk / Python / Go のどれでもよいです。
BQN parser は作りません。

最初の対象:

- `•Import`
- `name ←` / `name ⇐`
- `checks/check.sh` calls
- `fixtures/*/README.md`
- `src/reports/exporters/*.bqn`

### 5. check script scaffolder

repo-index のあと、または先に小さく実装してもよいです。
ただし、先に `check` boilerplate の標準形を docs で固定します。

### 6. sqz-report impact summary

report key contract が安定してから実装します。

### 7. 本格 CodeGraph / Semmle 系は保留研究

現時点では、外部大型ツールへ寄せるより、repo 固有の軽い索引を優先します。

## まずやらないこと

- BQN AST parser を作らない。
- CodeQL / Semmle extractor を作らない。
- `sqz-report` impact summary をいきなり大きく実装しない。
- AI 出力を短くするために、test 未実行や不確実性を省略させない。
- `data/*.tsv` を効率化実験のために触らない。
- `BuildCube` shape / layer contract を効率化目的で変更しない。

## Gemini / Codex 作業後報告テンプレ

```text
変更:
- ...

実行:
- ...

未実行:
- ...

触っていない:
- data/*.tsv: yes/no
- BuildCube shape / layer contract: yes/no

リスク / 不確実性:
- ...
```

## 次の一手候補

最初に切るなら、次のどちらかです。

### 候補1: Fragile test 防止の棚卸し

```text
check-negative.sh と tools/* の error assertion を棚卸しし、
長い文言依存・完全一致依存・exit status 主体にできる箇所を表にしてください。
実装変更はまだしないでください。
```

### 候補2: repo-index design doc

```text
docs/REPO_INDEX_DESIGN.md を作り、
BQN完全解析なしで拾う import / definition / check / fixture / exporter / docs の索引仕様を決めてください。
実装変更はまだしないでください。
```

現時点では、候補2の `repo-index design doc` が一番この計画の芯に近いです。
