# 外部監査: 改善提案と優先実施計画

**日付**: 2026-06-27
**監査者**: 外部AI
**ステータス**: 対応済み（2026-06-27）。公開衛生、自動化、docs整合、coverage、doctor を実装済み。追加確認で見つかった `LEDGER_DATA_DIR` 既定値の不統一と data/sandbox 文言も修正済み。

## 優先度付き改善提案

### 高優先度: 公開・共有に関わる非機能面の整備

設計を壊さずに実施でき、効果が大きい。

| # | 項目 | 目的 |
|---|------|------|
| 1 | LICENSE 追加 | 利用条件明確化 |
| 2 | data/ を fixture/sandbox 化し実データ外出し | 機微情報保護 |
| 3 | editor/editor を削除し成果物除外ルール統一 | サプライチェーン衛生 |
| 4 | GitHub Actions などで `tools/check.sh` を自動実行 | 品質ゲート自動化 |
| 5 | CONTRIBUTING.md とセットアップ節を追加 | contributor 体験改善 |

### 中優先度: 性能とドキュメント整合性

家計簿規模なら問題化しにくいが、fixture 拡大や将来の一般化では先に効く。

| # | 項目 | 目的 | 該当箇所 |
|---|------|------|----------|
| 6 | BQN 実装・推奨バージョンを明示 | 再現性向上 | README, docs |
| 7 | cube.Materialize の疎表現化または grouped accumulation | 性能改善 | `src_next/cube.bqn:167-187` |
| 8 | summary.bqn / README / TODO の文言整合化 | docs drift 解消 | `src_next/summary.bqn:12-14`, `README.md:67-88`, `TODO.md:59-93` |
| 9 | カバレッジ計測導入 | 品質可視化 | Go test, check scripts |

### 低優先度: 運用性向上

| # | 項目 | 目的 |
|---|------|------|
| 10 | 依存 SBOM / 実行 doctor コマンド追加 | 運用性向上 |

## 実装順序の提案

```
公開衛生 → 自動化 → 性能 → 利便性
```

1. LICENSE・data/ 分離・バイナリ削除
2. CI で `tools/check.sh` を固定
3. README と CONTRIBUTING.md に BQN/Go/fzf/gum の導入と動作確認手順を書く
4. cube.Materialize の実装改善や doctor tooling

ここまでで「他人が触っても危なくない」状態になる。

## 対応メモ

- `LICENSE`, `CONTRIBUTING.md`, GitHub Actions, coverage, doctor を追加済み。
- 公開 repo の `data/` は匿名 sandbox とし、実運用データは gitignore 済みの `moko/data` 等へ外出しする方針に更新済み。
- `tools/report`, `tools/report-next`, `tools/report-next-summary`, `tools/envelope-calc`, Go editor は `LEDGER_DATA_DIR` を既定 base directory として尊重する。
- `README.md`, `CONTRIBUTING.md`, `docs/AI_CODEMAP.md`, `docs/ARCHITECTURE.md`, `docs/QUALITY_BAR.md`, `AGENTS.md` の `data/` 正データ表現を base directory / sandbox 表現へ更新済み。
