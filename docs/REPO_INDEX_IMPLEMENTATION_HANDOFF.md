# Repo Index Implementation Handoff

最終更新日: 2026-06-26
ステータス: **implemented / historical handoff with stale old-engine examples**

> Note (2026-06-26): `tools/repo-index` is implemented and checked by `checks/check-repo-index.sh`. This handoff has been refreshed for `src_next`. Old-engine paths (`src/reports/*`, `checks/lint_cli.bqn`, old exporters) no longer exist and examples have been updated.

## 目的

`docs/REPO_INDEX_DESIGN.md` に従って、`tools/repo-index` の MVP 実装を次の agent に渡すための作業指示書です。

この handoff では、実装する範囲、触ってよいファイル、触ってはいけないファイル、受け入れ条件、検査方法を固定します。

## 背景

`repo-index` は、AI が `bqn-ledger` の関係ファイルを探し回る無駄を減らすための軽量な repo 索引ツールです。

BQN を完全に解析するのではなく、次のような浅い構造を拾います。

- BQN imports: `•Import "..."`
- BQN definition candidates: `name ←` / `name ⇐`
- check scripts
- `checks/check.sh` から呼ばれる checks
- fixtures
- fixture README summaries
- report exporters
- docs entries

## 必ず読む文書

- `docs/AI_AGENT_EFFICIENCY_PLAN.md`
- `docs/REPO_INDEX_DESIGN.md`
- `docs/AI_CODEMAP.md`
- `docs/BQN_CONVENTIONS_FOR_AI.md`
- `docs/SAFETY_PROFILE.md`

## 参考として読むファイル

- `checks/check.sh`
- `checks/check-src-next-golden.sh`
- `fixtures/basic/README.md`
- `src_next/cube.bqn`
- `src_next/report.bqn`

## 触ってよいファイル

MVP 実装で触ってよいファイル:

- `tools/repo-index`
- `docs/REPO_INDEX_IMPLEMENTATION_HANDOFF.md` への進捗メモ追記
- 必要なら `docs/REPO_INDEX_DESIGN.md` の小さな clarifying note

テストを追加する場合に限り、次を触ってよい:

- `checks/check-repo-index.sh`
- `checks/check.sh`

ただし、初回実装では `check.sh` への接続は任意です。
まず `tools/repo-index` 単体で動くことを優先します。

## 触ってはいけないファイル

- `data/*.tsv`
- `src_next/cube.bqn`
- `src_next/report.bqn`
- `src_next/*.bqn` （参照のみ可、変更不可）
- `editor/*`
- `tools/edit`
- 既存 fixture の中身
- `BuildCube` / Cube shape / layer contract に関わる実装

## 非目標

- BQN AST parser を作らない。
- CodeQL / Semmle extractor を作らない。
- Tree-sitter grammar を導入しない。
- BQN formatter / linter を作らない。
- `docs/AI_CODEMAP.md` を自動生成で全面置換しない。
- `docs/AI_REPO_MAP.md` 生成はまだ実装しない。
- historical: 当時存在した `sqz-report` には触らない。現在の tree では削除済み。
- `data/*.tsv` を index しない。

## 実装方針

### 推奨実装

最初の MVP は shell / awk でよいです。

理由:

- repo 内の既存 check script と相性がよい。
- 依存が軽い。
- BQN 完全解析をしない MVP には十分。

Go 実装にしてもよい条件:

- path walk と tests を明確にしたい。
- JSONL 出力まで見据える。
- shell が複雑になりすぎると判断した。

Python は prototype としては可ですが、repo の主系統ではない依存に見える可能性があるため、初回は避けるのが無難です。

## MVP の仕様

### コマンド

```sh
./tools/repo-index
```

repo root から実行する前提でよいです。
repo root 以外からの実行対応は、初回では任意です。

### 出力

標準出力に TSV を出します。

```tsv
path	kind	name	target	note
```

header は出してよいです。
ただし、テストでは header の有無に強く依存しないようにしてください。

### kind 候補

最低限、次の kind を出してください。

- `bqn-import`
- `bqn-def`
- `check`
- `check-call`
- `fixture`
- `exporter`
- `doc`

余裕があれば次も可:

- `task-doc`
- `handoff-doc`
- `design-doc`
- `plan-doc`
- `policy-doc`

## 収集要件

### 1. BQN imports

対象:

```bqn
name ← •Import "..."
name ⇐ •Import "..."
```

最低限:

- path
- kind=`bqn-import`
- name: import binding name
- target: import literal
- note: `from •Import`

コメント行の誤検出は MVP では許容します。
ただし、簡単に除外できるなら、`#` で始まる行は無視してください。

### 2. BQN definition candidates

対象:

```bqn
Name ← ...
Name ⇐ ...
```

最低限:

- path
- kind=`bqn-def`
- name: definition candidate
- note: `exported` if `⇐`, empty otherwise

関数内 local binding を拾う可能性は許容します。
MVP では symbol index ではなく definition candidate index として扱います。

### 3. check scripts

対象:

- `checks/check-*.sh`
- `checks/check-*.bqn`
- `checks/*check*.bqn`

最低限:

- path
- kind=`check`
- name: basename without extension if possible
- target: `shell` or `bqn`

### 4. `checks/check.sh` calls

対象:

- `bash checks/...`
- `bqn checks/...`
- `bash checks/golden_check.sh fixtures/... YYYY-MM-DD`

最低限:

- path=`checks/check.sh`
- kind=`check-call`
- name: called script basename
- target: called script path
- note: command kind, fixture/as_of if obvious

### 5. fixtures

対象:

- `fixtures/*/`

最低限:

- path: fixture directory
- kind=`fixture`
- name: fixture directory name
- note: README first heading or short summary if present

`journal.tsv` / `plan.tsv` / `budget_alloc.tsv` の存在有無を note に入れられるなら有用です。
ただし、fixture TSV の中身は深く読まないでください。

### 6. exporters

対象:

- `src/reports/exporters/*.bqn`

最低限:

- path
- kind=`exporter`
- name: basename without `.bqn`
- note: `machine output`

### 7. docs

対象:

- `docs/*.md`
- `TODO.md`
- `AGENTS.md`

最低限:

- path
- kind=`doc` または分類 kind
- name: first markdown heading without `#`

分類できるなら:

- `*_HANDOFF.md` -> `handoff-doc`
- `*_TASK.md` -> `task-doc`
- `*_PLAN.md` -> `plan-doc`
- `*_DESIGN.md` -> `design-doc`
- `*_POLICY.md` -> `policy-doc`

## 出力例

以下のような行が含まれることを目指してください。

```tsv
tests/test_src_next_cube.bqn	bqn-import	cube	../src_next/cube.bqn	from •Import
src_next/report.bqn	bqn-def	Report		exported
checks/check-src-next-golden.sh	check	check-src-next-golden	shell
checks/check.sh	check-call	check-src-next-golden.sh	checks/check-src-next-golden.sh	bash
fixtures/basic	fixture	basic		fixtures/basic [has: journal.tsv,plan.tsv,budget_alloc.tsv,accounts.tsv]
docs/REPO_INDEX_DESIGN.md	design-doc	Repo Index Design
```

Note: `exporter` kind は現在該当なし（`src/reports/exporters/` は削除済み）。

完全一致ではなく、意味的に同等ならよいです。

## 検査方針

### 最小 smoke test

まず手動で次を確認してください。

```sh
./tools/repo-index | head
./tools/repo-index | grep -F "bqn-import"
./tools/repo-index | grep -F "Report"
./tools/repo-index | grep -F "check-src-next-golden"
./tools/repo-index | grep -F "fixtures/basic"
./tools/repo-index | grep -F "REPO_INDEX_DESIGN"
```

### check script を追加する場合

`checks/check-repo-index.sh` を追加するなら、次を検査してください。

- `./tools/repo-index` が非ゼロ終了しない。
- `bqn-import` が少なくとも1件ある。
- `bqn-def` が少なくとも1件ある。
- `check-call` に `check-src-next-golden.sh` が含まれる。
- `fixture` に `fixtures/basic` が含まれる。
- `doc` または `design-doc` に `REPO_INDEX_DESIGN` が含まれる。

注意:

- 長い出力や完全な件数には依存しない。
- 既存 repo の成長で壊れない grep にする。
- 最初から `check.sh` へ接続するかは任意。接続した場合は `./checks/check.sh` を実行してください。

## 受け入れ条件

- `tools/repo-index` が追加されている。
- `./tools/repo-index` が TSV を標準出力する。
- BQN import が最低限拾える。
- BQN definition candidate が最低限拾える。
- `checks/check.sh` の呼び出しが最低限拾える。
- `fixtures/*` が最低限拾える。
- `src/reports/exporters/*.bqn` が最低限拾える（現在該当なし、将来的に再有効化）。
- docs の title が最低限拾える。
- `data/*.tsv` の中身を index していない。
- `BuildCube` / Cube shape / layer contract を変更していない。
- `docs/AI_CODEMAP.md` を自動生成で置換していない。

## 実行してほしい確認

可能なら:

```sh
./tools/repo-index >/tmp/repo-index.tsv
head /tmp/repo-index.tsv
grep -F "bqn-import" /tmp/repo-index.tsv
grep -F "Report" /tmp/repo-index.tsv
grep -F "check-src-next-golden" /tmp/repo-index.tsv
grep -F "fixtures/basic" /tmp/repo-index.tsv
grep -F "REPO_INDEX_DESIGN" /tmp/repo-index.tsv
```

check script を追加した場合:

```sh
bash checks/check-repo-index.sh
./checks/check.sh
```

`./checks/check.sh` が重い場合や環境不足で実行できない場合は、未実行理由を報告してください。

## 作業後報告テンプレ

```text
変更:
- ...

実行:
- ...

未実行:
- ...

触っていない:
- data/*.tsv: no
- BuildCube shape / layer contract: no

リスク / 不確実性:
- ...
```

## 注意

この作業は、AI に repo 全体を深く理解させるためのものではありません。

目的は、次の作業で読むべき入口を素早く見つけ、関係ないファイルを読ませないことです。

`repo-index` は巨大な知能ではなく、小さな索引で十分です。

## MVP 実装結果と進捗メモ (2026-06-22 追記)

- 2026-06-22 に `tools/repo-index` の MVP 実装を完了しました。
- 推奨方針に従い、シェルスクリプト (bash) で軽量・高速に動作するよう実装しました。
- 次の項目を抽出するロジックをカバーしています：
  - BQN imports (`•Import`)
  - BQN definition candidates (大文字開始の定義名。エクスポートされている場合は `exported` と判定)
  - check scripts (`checks/check-*.sh` など)
  - `checks/check.sh` calls (呼び出し先のスクリプト名とパス、および引数から fixture 設定を判定)
  - fixtures (fixture ディレクトリおよび `README.md` の見出しと TSV の有無)
  - exporters (`src/reports/exporters/*.bqn`)
  - docs (docs 以下の markdown タイトルおよび `handoff-doc` / `design-doc` などの種別判定)
- テストとして `checks/check-repo-index.sh` を新規追加し、`checks/check.sh` に接続しました。すべてのチェックが正常に通過することを確認しています。
- また、テスト実行環境にて `check-negative.sh` の `bqn-eval` が標準入力待ちでハングする既存のバグに遭遇したため、`check.sh` 側の呼び出し部分に `</dev/null` を追加してハングを防止するよう修正しました。
