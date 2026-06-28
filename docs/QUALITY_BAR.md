# Quality Bar

Status: current policy
Date: 2026-06-25

## 目的

`bqn-ledger` は一般向けプロダクトとして作らない。

ただし、自分の生活会計を預ける道具として、内部品質は **professional accounting software quality** を目指す。配布・販売・一般ユーザー対応はしないが、会計エンジンの構造、残高計算、期間損益、検査、復旧性は production-grade personal tool より一段厳しく扱う。

```text
配布・販売・一般ユーザー対応はしない。
でも、会計エンジンとしての筋、正データ保護・検査・復旧・変更耐性は本気で作る。
```

この文書は、次の作業を選ぶときの判断基準を固定する。

## 非目標

次は優先しない。

- 一般向けオンボーディング
- SaaS 化、同期サービス、マルチユーザー対応
- 見栄えのための GUI / TUI 作り込み
- 誰にでも説明できる設定画面
- ブランド、配布、インストーラ整備
- AI 相談やおすすめ配分を canonical engine に混ぜること

UI や launcher は作ってよいが、目的は販売可能なプロダクト化ではなく、日々の操作を安全にすること。

## 品質基準

### 1. Source TSV protection

base directory 配下の `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv` は正データである。公開 repo の `data/` は匿名 sandbox、実運用データは `LEDGER_DATA_DIR`（例: `/path/to/ledger-data/data`）で外出しする。正データの場所は移動可能なので、日常入口と pit 作業では `tools/doctor` で実効 base directory を確認する。

- AI は明示指示なしに実データ TSV を編集しない。
- 書き込みは approved editor path を通す。
- 大きな修正や削除は、人間が source TSV を確認する。
- 派生ファイルや cache を正データにしない。

### 2. Fail closed, not pretty wrong

壊れた入力や仕様外状態から、きれいな嘘のレポートを出さない。

- unknown account は止める。
- 列ずれを黙って補正しない。
- `0` と `UNAVAILABLE` を混ぜない。
- 未実装・履歴不足・設定不足は `ERROR / WARN / SKIPPED / UNAVAILABLE` として明示する。

### 3. Reproducible numbers

同じ source TSV、同じ config、同じ `as_of` からは同じ数字を出す。

- `as_of` は入口で決める。
- core の途中で勝手に外部時計を読まない。
- レポート値を変える変更は、理由・差分・fixture / golden を添える。

### 4. Accounting boundary clarity

会計上の意味を知る場所を増やさない。

```text
source TSV -> Posting IR -> validation -> ledger-wide postings -> TBDS(period, as_of) -> view/report/export
```

- BQN は正本数値エンジン。
- Posting IR は入力正規化境界。
- Ledger-wide postings は period / cycle で切り落とさない。
- Cube は `Day × Account × Layer` の materialized view。ただし cycle-bounded cube を残高計算の正本にしない。
- TBDS は period/account/layer の会計状態境界であり、`opening / movement / closing` を明示する。
- 残高系 report は `closing`、期間 flow 系 report は `movement` を使う。
- 年金・月給・不定期収入・封筒派などの生活スタイルは household policy layer で扱い、accounting core に埋め込まない。
- UI / shell / Go editor は計算責務を持たない。

### 5. Recovery and diagnostics

便利な機能より、壊れた時に戻れることを優先する。

- preview before apply
- backup before write
- stale check
- post-write lint / check
- source file / line / rule が分かる診断
- 失敗時に「書いたか、書いていないか」が分かる説明

### 6. Small reversible changes

変更は小さく、戻せる形で行う。

- 1目的1差分を基本にする。
- source TSV migration は急がない。
- default switch は gate を満たすまでしない。
- docs / contract / fixture / check を実装と同じ単位で更新する。

### 7. Test Visibility and Strictness

CIやチェックスクリプトが失敗した際に、原因が即座に分かる状態を維持する。

- **エラー出力の隠蔽厳禁**: テストコマンド (`go test`, `bqn` など) の出力を `>/dev/null` で捨ててはならない。失敗した時に「なぜ落ちたか」が隠されてしまい、CIデバッグが困難になる罠を防ぐ。
- **Goテストキャッシュの罠に注意**: Goのテストは `.go` ファイル自体が変更されないと結果がキャッシュされる（`ok (cached)`）。BQNファイルを追加・変更してGo側のLinter（依存関係チェック等）に違反した場合、ローカルではエラーに気づかないことがある。BQNの依存を変えた時は `go test -count=1 ./...` でキャッシュを無効化するか、CIの実行結果を必ず確認する。
- **環境差異への防御**: CI (Ubuntu/UTC) と ローカル (macOS/JST) の差異で落ちないように、CI側でタイムゾーンを明示的に指定する（`TZ: Asia/Tokyo`）、またはテスト側を堅牢に書く。

## 作業選択ルール

次に何をするか迷ったら、次の順に優先する。

1. 正データを壊す可能性を減らす作業
2. きれいな間違いを防ぐ fail-closed fixture / lint / invariant
3. 数字の再現性・比較可能性を上げる export / golden / parity check
4. 復旧・診断・doctor・backup などの運用安全
5. `src_next` の Posting IR / TBDS / section parity
6. 日々の入力や確認を安全にする薄い launcher / UI
7. 見た目や利便性だけの改善

## 関連文書との関係

- `docs/SAFETY_PROFILE.md`
  - safety / fail closed / invariant の詳細。
- `docs/POSTING_IR_CONTRACT.md`
  - 入力正規化境界。
- `docs/TBDS_CONTRACT.md`
  - 試算表データセット境界。
- `docs/archive/active-plans/APPLICATION_FOUNDATION.md`
  - TUI / GUI / Web UI を被せる場合の外装境界。
- `TODO.md`
  - 実際の次作業。迷ったらこの Quality Bar で優先順位を決める。

## 合言葉

```text
一般向けプロダクトではない。
でも、自分の生活を預けても怖くない道具にする。

TSV は地面。
BQN は秤。
UI は薄い外装。
壊れたら止まり、理由を言う。
```
