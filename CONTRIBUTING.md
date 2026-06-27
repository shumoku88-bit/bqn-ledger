# CONTRIBUTING

bqn-ledger は個人生活会計のための BQN エンジンです。一般向けプロダクトではありませんが、生活会計を預ける道具として production-grade の内部品質を目指しています。

## セットアップ

### 必要なもの

| 依存 | 用途 | インストール |
|------|------|-------------|
| [CBQN](https://github.com/dzaima/CBQN) | 会計エンジン | 推奨: commit `12a4fb9f` 以降（FFI, Singeli ビルド）<br>`git clone --depth 1 https://github.com/dzaima/CBQN.git && make -C CBQN -j$(nproc) && sudo cp CBQN/BQN /usr/local/bin/bqn` |
| [Go](https://go.dev/dl/) 1.22+ | TSV エディタ | `brew install go` / `apt install golang` |
| fzf, gum | 対話 UI（任意） | `brew install fzf gum` / `apt install fzf` |

### 動作確認

```bash
# 全チェック実行
bash tools/check.sh

# サンドボックスデータでレポート表示
tools/report fixtures/src-next-golden

# 実運用データを使う場合（moko/data は gitignore 済みの例）
export LEDGER_DATA_DIR=moko/data
bash tools/doctor
```

## 最初に読むドキュメント

1. [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md) — コード地図・データフロー
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — 全体構造と責務境界
3. [`docs/QUALITY_BAR.md`](docs/QUALITY_BAR.md) — 品質基準と判断軸
4. [`docs/CANONICAL_DAILY_CUBE.md`](docs/CANONICAL_DAILY_CUBE.md) — Day × Account × Layer の固定契約

## アーキテクチャ概要

```text
<base>/*.tsv (source of truth; public data/ is sandbox)
  │
  └─ src_next/loader.bqn (TSV読み込み)
       │
       └─ src_next/context.bqn (BuildContext)
            │
            ├─ src_next/cube.bqn (Canonical Daily Cube)
            ├─ src_next/tbds.bqn (Trial Balance Data Set)
            │
            └─ src_next/report.bqn (人間向けレポート)
                 └─ src_next/summary.bqn (機械向け出力)
```

詳しくは [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md) を参照。

## テストの走らせ方

```bash
# 全テスト・全チェック
bash tools/check.sh

# BQN ユニットテストのみ
for f in tests/test_*.bqn; do bqn "$f"; done

# Go テストのみ
cd editor && go test ./...

# 特定の golden fixture
bash checks/check-src-next-golden.sh fixtures/src-next-golden
```

## コード規約

- **TSV の先頭5列は固定**: `date memo from to amount`
- **6列目以降は `key=value` メタデータ**
- **source TSV 保護**: base directory 配下の `journal.tsv` 等が正データ。公開 repo の `data/` は sandbox、実運用は `LEDGER_DATA_DIR` で外出し。AI/ツールの勝手な編集禁止
- **境界削減**: Bash は UI のみ、Go は安全な TSV append のみ、BQN が会計意味の正本
- **1目的1差分**: 変更は小さく戻せる形で

詳細は [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) と [AGENTS.md](AGENTS.md) を参照。

## コントリビューションの流れ

1. [`TODO.md`](TODO.md) と [`docs/ENGINEERING_ROADMAP.md`](docs/ENGINEERING_ROADMAP.md) で優先順位を確認
2. 1目的に絞ったブランチを作成
3. 実装後 `tools/check.sh` が全 PASS することを確認
4. PR 作成（GitHub Actions で自動チェックが走ります）
