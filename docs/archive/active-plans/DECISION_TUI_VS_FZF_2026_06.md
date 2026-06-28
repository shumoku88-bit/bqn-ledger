# Decision: TUI vs fzf+gum UI Experiment

Status: **frozen / suspended** (2026-06-28 凍結)
Date: 2026-06-27

> [!WARNING]
> 2026-06-28の指示により、本検証およびTUIのPoC実装は一旦凍結となりました。日常運用および操作UIは引き続き fzf+gum 路線を維持・強化します。

## 背景 (Context)

現在、日常の操作は `tools/main-ui.sh` と `tools/add-ui.sh`（fzf と gum を組み合わせた CLI ランチャー）で行っている。
しかし、「BQN側のレポート仕様が変わるたびに、UI側（fzfのプレビュー切り出し等）が壊れる」という問題を抱えていた。

この脆い境界を解決する手段として、「TUI（Terminal UI）を導入し、安定したAPI（TSV/JSON）だけを読ませる」というアプローチが浮上した。
そこで、Go言語と `tview` ライブラリを用いて、1ペイン全画面の最小TUIのPoC（概念実証）を実装した。

## 実装したPoC (Phase A)

- **パス**: `tui/main.go`, 起動ラッパー `tools/tui`
- **構成**: Go 1.20 + `github.com/rivo/tview`
- **機能**:
  - `tools/report` の出力を非同期にロードし、全画面の `TextView` に表示
  - `n` / `p` キーでセクションを切り替え（`report --list-sections` を利用）
  - `a` キーで `tview.Suspend` を使い、一時的にTUIを抜けて `add-ui.sh` の仕訳入力画面を呼び出し、完了後に自動リロード
  - 背景色をターミナルのデフォルトに透過設定（`tcell.ColorDefault`）
  - ANSIカラーパースを無効化（`SetDynamicColors(false)`）して描画負荷を軽減

## 結果と気付き (Results & Observations)

PoCを実データ（`moko/data`）で稼働させた結果、以下の気付きを得た。

**1. tview は fzf ほどの軽快さが出ない**
- `fzf` は C/Go ベースでテキストのストリーム処理と部分描画に極限まで最適化されている。
- 一方 `tview` の `TextView` は、巨大なテキストをメモリに抱え込み、ターミナル幅に応じた折り返し計算やスクロールを毎フレームGo側で処理するため、fzfに比べてスクロールや切り替えが「もっさり（重く）」感じられた。

**2. 目的の再確認**
- TUIを試した本来の目的は「リッチな画面が欲しい」からではなく、「**UIが壊れるのを防ぎたい**」からであった。
- UIの軽快さにおいて fzf+gum に勝る体験を作るのは（少なくとも tview では）難しく、無理にTUIに移行すると日々の操作体験を損なうリスクがある。

## 今後の選択肢 (Options)

現在、mokoによるリサーチと再検討待ち。以下の方向性が考えられる。

### Option 1: fzf路線の維持 ＋ BQN出力境界の堅牢化（推奨）
UIは軽快な `main-ui.sh` / `add-ui.sh` のまま維持し、**「壊れる原因」である BQN との接続部分だけを作り直す**。
現在のUIが壊れるのは「人間向けの装飾レポートを `awk` で文字列検索して切り出している」ため。
- 解決案A: BQN側に `tools/report --section <key>` オプションを足し、fzfのプレビューからそれを直接呼ぶ（UI側でのパースを辞める）。
- 解決案B: 人間向けレポートの中に、絶対に誤爆しない機械向け境界マーカー（例: `\x1c` 等の制御文字）を埋め込む。

### Option 2: Zig `libvaxis` など、より高速なTUIの検証
`docs/ENGINEERING_ROADMAP.md` で本命視されていた Zig の `libvaxis` を用いて、fzfに匹敵する速度が出せるか検証する。ただし、言語が一つ増える学習・保守コストがかかる。

### Option 3: tview のチューニング
セクション切り替えのたびに `SetText()` で巨大な文字列を渡し直すのではなく、セクションごとに別の `TextView` を作って `Pages` で切り替える等、tview側の描画負荷をギリギリまで下げる努力をする（根本的な軽快さで fzf に追いつくかは未知数）。

## アクション (Next Steps)

- 今回作成した `tui/` コードベースは、参照用・今後の土台としてリポジトリに残す。
- mokoのリサーチを経て、Option 1〜3 のどれに進むか（あるいは別の道か）を決定する。
- 決定までの間、本番の日常運用は引き続き既存の `tools/main-ui.sh` を使用する。
