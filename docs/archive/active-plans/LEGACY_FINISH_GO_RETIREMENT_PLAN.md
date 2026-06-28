# Legacy finish.go Retirement Plan


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
最終更新日: 2026-06-22
ステータス: **B: migration completed (2026-06-22)**

## 目的

`src/input/finish.go` は、現在 `src/` 配下に残っている legacy standalone Go helper です。

現時点で危険な未管理コードではありません。
`checks/check-disabled-features.sh` により preview-only helper として検査され、source TSV を変更しないことが確認されています。

ただし、現在の責務分離から見ると、Go の standalone helper が `src/input/` に残っている状態は読み手に混乱を与えます。

この文書は、まず docs-only で退役方針を明確にし、その後に必要なら `src/input/finish.go` を legacy / tools 側へ移すための計画です。

## 現在地

### 現在の本線

Go による source TSV 編集の本線は `editor/` です。

- `editor/go.mod`
- `editor/main.go`
- `editor/plan.go`
- `editor/journal.go`
- `tools/edit`

`editor/` は、BQN canonical engine とは責務を分けた Go source TSV editor です。

### legacy helper

`src/input/finish.go` は、legacy standalone plan finish preview helper です。

- package main の単体 Go program。
- write-capable 本線ではない。
- preview-only として扱う。
- `check-disabled-features.sh` が build / vet / no-mutation を検査する。

## 問題意識

### 1. `src/` の意味が濁る

現在の見通しでは、`src/` は主に BQN core / input parser / views / reports / checks の置き場です。

そこに Go の standalone helper が残っていると、AI や人間が次のように誤解しやすくなります。

- `src/input/finish.go` が現在の本線なのか。
- Go editor が `editor/` と `src/input/` に分裂しているのか。
- source TSV を書き換える権限が `src/input/` にもあるのか。

### 2. repo-index / AI_CODEMAP 上でもノイズになる

`repo-index` や `AI_CODEMAP` で repo を読むとき、legacy Go file が `src/input/` にあると、AI が input 層の現在責務を誤読する可能性があります。

### 3. 安全上は即削除より段階的整理がよい

`check-disabled-features.sh` は、この helper が preview-only であり、source TSV を変更しないことを検査しています。

したがって、いきなり削除や移動をせず、まず現状の safety fence を壊さない形で整理します。

## 方針

この計画は A から B へ進みます。

### A. docs-only retirement plan

この文書を作り、以下を明確にします。

- `src/input/finish.go` は legacy helper である。
- Go source TSV editor の本線は `editor/` である。
- `finish.go` は preview-only のまま維持されている。
- 移動 / 削除 / 維持の判断基準を先に決める。

### B. legacy location migration plan

A のあと、必要なら `src/input/finish.go` を `src/` から外します。

候補:

```text
legacy/finish-preview.go
```

または:

```text
tools/legacy/finish-preview.go
```

推奨は `tools/legacy/finish-preview.go` です。

理由:

- Go standalone helper は BQN input parser ではなく tool に近い。
- legacy であることが path から分かる。
- `tools/edit` と同じく、人間が起動する補助道具として見える。
- `src/` を BQN core / parser / view / report に寄せられる。

## 判断基準

### 維持してよい条件

`src/input/finish.go` を現状維持してよいのは、次のすべてが満たされる場合です。

- `check-disabled-features.sh` が preview-only を検査している。
- `AI_CODEMAP.md` が legacy helper と明記している。
- `editor/` が write-capable 本線として明確である。
- 誰もこの helper を日常運用の本線として使っていない。

### 移動すべき条件

次のどれかが当てはまるなら、移動を検討します。

- AI が `src/input/finish.go` を現行本線として誤読する。
- `src/` を BQN中心に整理したくなる。
- `repo-index` の出力で Go helper が input 層に混じることがノイズになる。
- Go editor 周辺を `editor/` / `tools/` に寄せて読みやすくしたい。

### 削除してよい条件

次のすべてが満たされるまで削除しません。

- `editor plan finish` が preview / apply の必要機能を十分に持っている。
- `check-disabled-features.sh` の legacy helper 検査が不要になる。
- docs に残す歴史的情報で十分になる。
- ユーザーが明示的に削除を承認する。

## B: migration design

### 移動先候補

第一候補:

```text
tools/legacy/finish-preview.go
```

第二候補:

```text
legacy/finish-preview.go
```

採用しない候補:

```text
editor/finish-preview.go
```

理由:

- `editor/` は現在の write-capable 本線なので、legacy preview helper を混ぜるとまた意味が濁る。
- `src/input/` から出しても `editor/` に入れると、退役ではなく復帰に見えやすい。

### migration で触る可能性があるファイル

- `src/input/finish.go` -> `tools/legacy/finish-preview.go`
- `checks/check-disabled-features.sh`
- `docs/AI_CODEMAP.md`
- `docs/LEGACY_FINISH_GO_RETIREMENT_PLAN.md`
- 必要なら `docs/GO_EDITOR_USAGE.md`

### migration で触ってはいけないファイル

- `data/*.tsv`
- `editor/*` の機能実装
- `src/core/build_cube.bqn`
- `src/reports/report_engine.bqn`
- `src/views/*.bqn`
- `src/input/*.bqn`
- `BuildCube` shape / Layer contract

### migration 後の check-disabled-features 方針

`check-disabled-features.sh` は削除しません。

移動後は、検査対象 path を変更します。

変更前:

```sh
go vet src/input/finish.go
go build -o "$tmp_bin" src/input/finish.go
```

変更後候補:

```sh
go vet tools/legacy/finish-preview.go
go build -o "$tmp_bin" tools/legacy/finish-preview.go
```

検査内容は維持します。

- preview-only message が出る。
- plan action が出る。
- `UNCHANGED` が出る。
- `journal.tsv` / `plan.tsv` が変更されない。
- plan-only metadata が journal candidate に残らない。
- invalid date を拒否する。

## 実装しないこと

この計画では、次は行いません。

- `finish.go` を write-capable に戻さない。
- `editor/` に legacy helper を混ぜない。
- `check-disabled-features.sh` を削除しない。
- source TSV を変更しない。
- BQN report / cube / parser を変更しない。
- plan finish の新機能追加をしない。

## migration 受け入れ条件

B に進む場合、受け入れ条件は次の通りです。

- `src/input/finish.go` が `tools/legacy/finish-preview.go` へ移動されている。
- `src/input/` に Go standalone helper が残っていない。
- `check-disabled-features.sh` が新しい path を build / vet する。
- preview-only / no-mutation 検査が従来通り通る。
- `docs/AI_CODEMAP.md` が新しい path と legacy status を説明している。
- `docs/LEGACY_FINISH_GO_RETIREMENT_PLAN.md` に実施メモが追記されている。
- `./checks/check.sh` が通る。
- `data/*.tsv` は変更されていない。
- `BuildCube` shape / Layer contract は変更されていない。

## Gemini / Codex handoff 案

```text
目的:
`docs/LEGACY_FINISH_GO_RETIREMENT_PLAN.md` の B: migration design に従って、
legacy standalone helper `src/input/finish.go` を `tools/legacy/finish-preview.go` へ移動してください。

読むもの:
- `docs/LEGACY_FINISH_GO_RETIREMENT_PLAN.md`
- `docs/AI_CODEMAP.md`
- `checks/check-disabled-features.sh`
- `src/input/finish.go`
- `docs/GO_EDITOR_USAGE.md` if needed

触ってよいもの:
- `src/input/finish.go` の削除 / 移動
- `tools/legacy/finish-preview.go` の追加
- `checks/check-disabled-features.sh`
- `docs/AI_CODEMAP.md`
- `docs/LEGACY_FINISH_GO_RETIREMENT_PLAN.md`

触ってはいけないもの:
- `data/*.tsv`
- `editor/*` の機能実装
- `src/core/build_cube.bqn`
- `src/reports/report_engine.bqn`
- `src/views/*.bqn`
- `BuildCube` shape / Layer contract

非目標:
- `finish.go` の機能変更はしない。
- write-capable helper に戻さない。
- `editor/` に移さない。
- `check-disabled-features.sh` を削除しない。

実行:
- `bash checks/check-disabled-features.sh data`
- `./checks/check.sh`

作業後報告:
- 変更ファイル
- 実行した確認
- 未実行の確認
- `data/*.tsv` touched? no
- BuildCube shape / layer contract touched? no
- リスク / 不確実性
```

## 判断

`src/input/finish.go` は今すぐ危険なものではありません。

しかし、`src/` の意味を BQN core / parser / report 側に寄せるなら、legacy Go standalone helper は `tools/legacy/` へ出すのが自然です。

この移動は機能追加ではなく、責務境界を見やすくする床掃除です。

## 実施メモ (2026-06-22)

計画Bの移行を完了しました。

- `src/input/finish.go` を `tools/legacy/finish-preview.go` へ移動しました。
- `checks/check-disabled-features.sh` のテスト対象パスを変更し、正常にテストが通ることを確認しました。
- `docs/AI_CODEMAP.md` の説明を新しいパスに追記・更新しました。
