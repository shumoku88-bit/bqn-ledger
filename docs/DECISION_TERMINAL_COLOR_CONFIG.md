# DECISION_TERMINAL_COLOR_CONFIG

レポート出力の ANSI カラー制御をどのように設定可能にするか。

Status: Phase 1 実装済み（2026-06-27: semantic color helpers + `--no-color` / wrapper auto制御）

## 現状

`src_next/format.bqn` が ANSI カラー helper を提供する。色は semantic helper 経由へ寄せ始めている。

- セクションヘッダー：太字（`Bold`）
- マイナス金額：赤（`FmtAmt` で自動）
- semantic helpers: `Ok` / `Warn` / `Bad` / `Info` / `Muted` / `Accent` / `Future`
- 試算表 OK/FAIL：`Ok` / `Bad`
- 封筒 health：SAFE系=`Ok`、WARN=`Warn`、SHORT/DRAWN=`Bad`
- 予定支払い：future=`Future`、completed=`Ok`、due=`Warn`、overdue=`Bad`
- snapshot/cycle summary の主要金額に意味色を一部追加

`bqn src_next/report.bqn <base> --no-color` または `--color=never` で ANSI を抑制できる。`--color=always` は強制表示。
`tools/report` / `tools/main-ui.sh` は `NO_COLOR` または stdout 非TTY時に `--no-color` を渡す。

## プロの CLI/TUI ツールの標準アプローチ

1. **`NO_COLOR` 環境変数** — https://no-color.org で標準化。設定されていれば色を抑制。
2. **パイプ検出** — `isatty(stdout)` が false なら色抑制。`--color=always|never|auto` で上書き可能。
3. **テーマファイル** — TUI で細かく設定する場合（lazygit, k9s 等）。このプロジェクトではオーバースペック。

## 選択肢

### A: 最小構成 — Bash 層で `NO_COLOR` + パイプ検出（採用済み）

`tools/report` / `tools/main-ui.sh` で環境変数またはパイプ検出を行い、BQN へ `--no-color` を渡す。
BQN 側は `report.bqn` が `fmt.SetColorEnabled 0` を呼び、各 module の `format.bqn` helper が無色文字列を返す。

```bash
bqn src_next/report.bqn data --no-color
bqn src_next/report.bqn data --color=always
```

CBQN に `•GetEnv` がないため、BQN が環境変数を直接読む設計にはしない。

### B: 何もしない

個人ツールであり、`tools/main-ui.sh` は常に対話実行なのでカラーが問題になる場面は限られる。

### C: `format.bqn` に on/off スイッチ（軽量版を採用済み）

`SetColorEnabled` と semantic color helper を追加済み。テーマ辞書や `config/theme.tsv` はまだ作らない。
将来 theme 化する場合も、report 各所は `Ok` / `Warn` / `Bad` などの意味名を使い、色の割当は `format.bqn` に閉じ込める。

## 表示実装の注意

表の幅計算 (`VWidth` / `PadV`) は ANSI escape sequence を幅0として扱わない。
そのため、表セルを色付けする時は原則として次の順序を守る。

```text
先に PadV / PadL / AlignR で幅を揃える → 最後に semantic color helper で巻く
```

既に色が付いた文字列を `PadV` に渡すと、桁ズレの原因になる。

## 議論メモ

- moko: 「これどうするか考えるから議題としてドキュメントにして」（2026-06-26）
- 実装済みの色付け自体は気に入っている
- 2026-06-27: config-theme はまだ早い。まず semantic helper と no-color 制御だけ入れる方針。
- パイプ時に ANSI が混ざらない仕組みは `tools/report` / `tools/main-ui.sh` で導入済み。

## 導線

- `AGENTS.md` 作業ルール
- `src_next/format.bqn`（色の実装箇所）
- `tools/main-ui.sh`（呼び出し元）
