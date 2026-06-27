# Repo Index Design

最終更新日: 2026-06-26
ステータス: **implemented / examples need src_next refresh**

> Note (2026-06-26): `tools/repo-index` exists and is checked by `checks/check-repo-index.sh`. This design doc has been refreshed for `src_next`. Old-engine paths (`src/reports/*`, `checks/lint_cli.bqn`, `checks/check-missing-budget-mapping.sh`) no longer exist and have been replaced with current examples.

## 目的

`tools/repo-index` は、AI が `bqn-ledger` の関係ファイルを探し回る無駄を減らすための、軽量な repo 索引ツールです。

この設計は、Semmle / CodeGraph / RepoGraph 的な「構造を先に索引化する」発想を、BQN を含む小さな個人 repo 向けに薄く翻訳したものです。

重要なのは、BQN を完全に理解することではありません。
AI が作業前に「どのファイルを読めばよいか」を短時間で見つけられるようにすることです。

## 既存文書との関係

### `docs/AI_CODEMAP.md`

`AI_CODEMAP.md` は、pit / AI 作業相棒が読む静的なコード地図です。
これは人間が編集し、意味や責務境界を説明します。

`repo-index` は `AI_CODEMAP.md` を置き換えません。
`repo-index` は、AI が必要な入口ファイルを探すための機械生成の補助索引です。

役割分担:

| 文書 / ツール | 役割 |
|---|---|
| `docs/AI_CODEMAP.md` | 意味、責務、読む順番を説明する人間編集の地図。 |
| `tools/repo-index` | import / definition / check / fixture / exporter などを浅く拾う機械生成索引。 |
| `docs/AI_REPO_MAP.md` | 必要なら `repo-index` の出力を人間が読みやすく整えた生成物。 |
| `docs/AI_AGENT_EFFICIENCY_PLAN.md` | AI 作業効率化候補全体の計画。 |

### `docs/AI_AGENT_EFFICIENCY_PLAN.md`

この設計は、`AI_AGENT_EFFICIENCY_PLAN.md` の CodeGraph-lite / repo-index 候補を具体化するものです。

ただし、ここではまだ実装しません。
MVP の入力、出力、拾う field、やらないことを固定します。

## 非目標

- BQN AST parser を作らない。
- BQN formatter / linter を作らない。
- CodeQL / Semmle extractor を作らない。
- 型推論、shape 推論、box / unbox の意味解析をしない。
- `BuildCube` の仕様や Layer 契約を変更しない。
- `data/*.tsv` を変更しない。
- `AI_CODEMAP.md` を自動生成で全面置換しない。
- 大型外部ツール導入を前提にしない。

## MVP 方針

初期版は、BQN を「完全に解析する言語」ではなく、「一定の記号パターンを持つテキスト」として扱います。

対象は repo 内の次の構造です。

- BQN imports
- BQN top-level definitions
- check scripts
- `checks/check.sh` から呼ばれる checks
- fixtures
- fixture README summaries
- report exporters
- docs entries
- task / handoff docs

## 入力

MVP は repo root で実行します。

```sh
./tools/repo-index
```

オプション候補:

```sh
./tools/repo-index --format tsv
./tools/repo-index --format jsonl
./tools/repo-index --kind check
./tools/repo-index --grep missing-budget
./tools/repo-index --write-doc docs/AI_REPO_MAP.md
```

初期実装では、`--format tsv` だけでもよいです。

## 出力形式

### TSV MVP

最初の出力形式は TSV を推奨します。

```tsv
path	kind	name	target	note
```

field の意味:

| field | 意味 |
|---|---|
| `path` | repo root からの相対 path。 |
| `kind` | `bqn-import`, `bqn-def`, `check`, `check-call`, `fixture`, `exporter`, `doc`, `task-doc` など。 |
| `name` | definition 名、script 名、fixture 名、doc 名など。 |
| `target` | import target、呼び出し先、関連 fixture など。なければ空。 |
| `note` | 短い補足。なければ空。 |

例:

```tsv
tests/test_src_next_cube.bqn	bqn-import	cube	../src_next/cube.bqn	from •Import
checks/check.sh	check-call	check-src-next-golden.sh	checks/check-src-next-golden.sh	bash
fixtures/basic	fixture	basic		fixtures/basic [has: journal.tsv,plan.tsv,budget_alloc.tsv,accounts.tsv]
```

Note: `src/reports/exporters/` は削除済みのため、現在 `exporter` kind の出力はない。

### JSONL 候補

将来、machine consumption を強めるなら JSONL も候補です。

```json
{"path":"tests/test_src_next_cube.bqn","kind":"bqn-import","name":"cube","target":"../src_next/cube.bqn","note":"from •Import"}
```

ただし、初期版は TSV で十分です。

## 収集対象

### 1. BQN imports

対象:

```bqn
name ← •Import "..."
name ⇐ •Import "..."
```

拾う情報:

- file path
- import binding name
- import target literal
- resolved path は可能なら入れる。難しければ literal のままでよい。

出力例:

```tsv
tests/test_src_next_cube.bqn	bqn-import	cube	../src_next/cube.bqn	from •Import
```

注意:

- BQN parser は作らない。
- コメント内の `•Import` を拾う可能性は MVP では許容する。
- 誤検出が問題になったら、行頭 comment を除外する程度に留める。

### 2. BQN top-level definitions

対象:

```bqn
Name ← ...
Name ⇐ ...
```

拾う情報:

- file path
- definition name
- public-ish marker: `⇐` なら `exported` note を付ける。

出力例:

```tsv
src_next/report.bqn	bqn-def	Report		exported
src_next/cube.bqn	bqn-def	Materialize		exported
```

注意:

- 関数内 local binding も拾う可能性があります。
- MVP では「候補」として扱い、完全な symbol index とは呼ばない。
- 後で必要なら、行頭 indent やセクションコメントで粗く絞る。

### 3. check scripts

対象:

```text
checks/check-src-next-*.sh
checks/check-*.sh
checks/check-*.bqn
```

拾う情報:

- check file path
- check name
- script kind: shell / bqn

出力例:

```tsv
checks/check-src-next-golden.sh	check	check-src-next-golden	shell	src_next golden output check
```

### 4. `check.sh` calls

対象:

```sh
bash checks/check-foo.sh
bqn checks/check-bar.bqn
bash checks/golden_check.sh fixtures/basic 2026-06-16
```

拾う情報:

- caller path: `checks/check.sh`
- command kind: `bash` / `bqn`
- target script
- fixture argument があれば note に入れる。

出力例:

```tsv
checks/check.sh	check-call	check-src-next-golden.sh	checks/check-src-next-golden.sh	bash
checks/check.sh	check-call	check-src-next-report.sh	checks/check-src-next-report.sh	bash
```

### 5. fixtures

対象:

```text
fixtures/*/
```

拾う情報:

- fixture path
- fixture name
- `README.md` の1行目または最初の説明文
- invalid / negative / golden らしき語があれば note に入れる。

出力例:

```tsv
fixtures/missing-budget-mapping	fixture	missing-budget-mapping		negative fixture: missing budget mapping
```

注意:

- fixture の中身を深く解釈しない。
- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` の存在有無を note に入れるのは有用。

### 6. exporters

対象:

```text
src/reports/exporters/*.bqn
```

> Note (2026-06-26): `src/reports/exporters/` は old-engine 削除に伴い存在しない。現在 `exporter` kind の出力はゼロ。将来 exporter が追加された場合はこのセクションが再有効化される。

拾う情報:

- path
- exporter name
- machine output / human output の区別は MVP では不要。

### 7. docs

対象:

```text
docs/*.md
TODO.md
AGENTS.md
```

拾う情報:

- path
- title line
- active / archive / handoff / task / design / policy などの kind

分類の粗いルール:

| pattern | kind |
|---|---|
| `*_HANDOFF.md` | `handoff-doc` |
| `*_TASK.md` | `task-doc` |
| `*_PLAN.md` | `plan-doc` |
| `*_DESIGN.md` | `design-doc` |
| `*_POLICY.md` | `policy-doc` |
| `archive/` | `archive-doc` |
| その他 | `doc` |

出力例:

```tsv
docs/AI_AGENT_EFFICIENCY_PLAN.md	plan-doc	AI Agent Efficiency Plan		active AI efficiency plan
```

## 使い方の想定

### task packet 作成前

AI または人間が次を実行します。

```sh
./tools/repo-index --grep budget
```

期待する使い方:

```text
budget mapping に関係する候補:
- src_next/envelope_computation.bqn
- fixtures/envelope-plan/
- docs/SAFETY_PROFILE.md
```

これにより、task packet の `read:` 欄を短く正確にできます。

### 変更前の影響調査

```sh
./tools/repo-index --kind check
./tools/repo-index --kind fixture
```

AI が check と fixture の全体像を掴み、既存 pattern を再利用しやすくします。

### docs drift の補助

将来、`docs/AI_REPO_MAP.md` を生成する場合は、`check-docs-drift.sh` 的な検査で、repo-index 出力と生成 docs の差分を検出できます。

ただし、MVP では docs drift check は不要です。

## 実装候補

### shell / awk

利点:

- 既存 repo の shell check と相性がよい。
- 依存が軽い。
- 最初の MVP に向く。

欠点:

- JSONL 出力や path 解決が複雑になると読みにくい。

### Go

利点:

- 既存 Go editor と同じ ecosystem。
- path walk、JSONL、tests が書きやすい。
- 将来 `tools/edit` 周辺とも一貫する。

欠点:

- 小さな MVP には少し重い。

### Python

利点:

- path walk と text processing が速い。
- prototype が簡単。

欠点:

- repo の主系統ではない依存に見える可能性がある。

### 推奨

最初は shell / awk か Go。

- 単発の TSV 出力 MVP なら shell / awk。
- test 付きで育てるなら Go。

## 受け入れ条件 MVP

最小実装の受け入れ条件:

- `./tools/repo-index` が TSV を標準出力する。
- repo root 以外から実行しても root を解決できる、または repo root 実行前提を明記する。
- BQN import が最低限拾える。
- BQN definition 候補が最低限拾える。
- `checks/check.sh` の呼び出しが拾える。
- `fixtures/*` が拾える。
- `src/reports/exporters/*.bqn` が拾える。
- `docs/*.md` の title が拾える。
- `data/*.tsv` の中身は index しない。
- `./checks/check.sh` にいきなり組み込まない。

## 初回 task packet 案

```text
目的:
`docs/REPO_INDEX_DESIGN.md` に従って、repo-index MVP の実装案を作ってください。
最初は実装せず、実装対象ファイル、出力例、テスト方針だけを `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md` にまとめてください。

読むもの:
- `docs/AI_AGENT_EFFICIENCY_PLAN.md`
- `docs/REPO_INDEX_DESIGN.md`
- `docs/AI_CODEMAP.md`
- `checks/check.sh`
- `fixtures/basic/README.md`

触ってよいもの:
- `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md`

触ってはいけないもの:
- `data/*.tsv`
- `src_next/cube.bqn`
- `src_next/report.bqn`
- `tools/*`
- `checks/*`

非目標:
- BQN parser を作らない。
- repo-index を実装しない。
- check.sh に接続しない。

報告:
- 変更ファイル
- 実行した確認
- 未実行の確認
- `data/*.tsv` touched? no
- BuildCube shape / layer contract touched? no
```

## 将来候補

MVP のあとに考えること:

- `--grep` filter
- `--kind` filter
- JSONL output
- `docs/AI_REPO_MAP.md` 生成
- generated docs drift check
- historical: 削除済み `tools/sqz-report` 相当の output squeezer を復活させる場合の連携
- task packet の `read:` 自動生成

## 判断

現時点で最も重要なのは、AI に repo 全体を深く理解させることではありません。

重要なのは、次の作業で読むべき入口を素早く見つけ、関係ないファイルを読ませないことです。

そのため、`repo-index` は巨大な知能ではなく、小さな索引で十分です。
