# DECISION_TERMINAL_COLOR_CONFIG

レポート出力の terminal color / styling をどの層で扱うか。

Status: 決定更新（2026-06-28: BQN layer は terminal styling を出力しない）

## 決定

BQN layer は terminal styling を出力しない。

BQN が出してよいもの:

- plain text report
- section key
- machine-readable summary
- semantic status word（例: `ok`, `warn`, `due`, `overdue`, `future`, `completed`）

BQN が出してはいけないもの:

- ANSI escape sequence
- terminal color code
- cursor control
- TTY 依存の表示制御
- fzf / gum など特定 UI ツール向けの装飾 markup

色、太字、枠、カード、preview 用の加工は presentation layer が担当する。

主な置き場:

- `tools/lib/color-filter`
- `tools/main-ui.sh`
- `tools/add-ui.sh` の表示補助
- Go TUI / future viewer layer

## 理由

BQN は source TSV の検査、意味解釈、計算、export の正本である。terminal 表示の都合を BQN に混ぜると、plain text report、machine-readable output、golden check、将来の TUI / Web viewer が同じ文字列に引きずられる。

特に `src_next/format.bqn` の `VWidth` / `PadV` は ANSI escape sequence を幅0として扱わない。そのため、BQN output に ANSI を混ぜると表の桁揃えが壊れやすい。

## 表示境界

```text
source TSV
  -> BQN validated model / view model / plain report text
  -> shell / Go / future UI presentation layer
  -> terminal color, cards, preview, interaction
```

BQN は意味を出す。UI は見せ方を決める。

## 実装上のルール

1. `src_next/**/*.bqn` と `tests/**/*.bqn` に ANSI escape sequence を追加しない。
2. `fmt.Ok`, `fmt.Warn`, `fmt.Bad` などの semantic helper を terminal color 実装として使わない。
3. BQN 内に `ESC`, `@+27`, `\033`, `\x1b`, `\e[` 相当の terminal styling を置かない。
4. 色付けしたい場合は、BQN が plain text または semantic status word を出し、presentation layer で後処理する。
5. `--no-color`, `--color=never`, `--color=always` のような CLI 互換フラグが残っていても、それを BQN に ANSI を戻す許可とは扱わない。

## 既存実装との関係

`src_next/format.bqn` には歴史的に semantic color helper 名が残っているが、terminal styling の実装場所ではない。これらは、将来の意味ラベルや presentation layer 連携に置き換える候補として扱う。

現在の色付き表示は、BQN の外側で plain text を受け取り、必要な場面だけ `tools/lib/color-filter` などで装飾する。

## check

`tools/check.sh` は、BQN source に terminal styling が混入していないかを engine-independent check として確認する。

## 議論メモ

- moko: BQN 側に色を埋め込まない方針を今のうちに厳格にルール化する。
- 色付きUI自体は否定しない。色の置き場を BQN ではなく presentation layer に固定する。
- Bubble Tea / Lip Gloss / Rich / Textual などの将来UIも、この境界に従えば後から安全に足せる。

## 導線

- `AGENTS.md` 作業ルール
- `docs/ARCHITECTURE.md` presentation boundary
- `tools/lib/color-filter`
- `tools/main-ui.sh`
- `tools/check.sh`
