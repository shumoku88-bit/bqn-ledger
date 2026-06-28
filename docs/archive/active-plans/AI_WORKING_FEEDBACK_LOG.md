# AI Working Feedback Log

Status: active intake log
Date: 2026-06-28

この文書は、pit（AI作業相棒）が実作業中に気づいた **作業品質・トークン効率・デバッグ効率・安全性** に関する意見を一時的に集める intake log です。

## 目的

- 作業のたびに出た小さな改善案を失わない。
- ある程度溜まったら、人間がレビューして次のどれかに振り分ける。
  - すぐ AGENTS.md / docs / check に反映する作業ルール
  - devtools / lint / helper script として実装する候補
  - 既存ツール（rtk / sqz / query / bqn-dump 等）の改善候補
  - 採用しない、または後回しにする案
- 過去の大きな提案集である [DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md](../completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md) を、今後の実作業から更新・発展させる材料にする。

## pit への記入ルール

作業後、改善余地に気づいた時だけ追記する。毎回必須ではない。

- 長文にしない。1件あたり数行でよい。
- 具体的な「困った場面」と「改善案」を分ける。
- 実データ TSV の内容は書かない。
- すぐ実装しない。ここはまず収集場所。
- 既にある devtools で解決できる場合は、そのツール名を書く。

## 記入テンプレート

```md
### YYYY-MM-DD: short title

- Context: 何の作業中に起きたか
- Friction: 何にトークン/時間/注意を使ったか
- Idea: どう改善できそうか
- Candidate type: rule / docs / check / devtool / existing-tool-improvement / no-action
- Related tool/doc: 任意
```

## Review policy

溜まってきたら、人間がまとめてレビューする。

レビュー時の判断軸:

1. 正データ保護や fail-closed に効くか
2. AI の探索トークンを減らすか
3. デバッグ往復を減らすか
4. 既存 devtools で代替できるか
5. ツール化するほど頻出か

採用した案は、必要に応じて `AGENTS.md`、`docs/AI_CODEMAP.md`、check、または devtools 実装へ移す。
完了・採用済みになったまとまりは、後で completed plan へ退避する。

## Entries

<!-- New feedback entries go below. -->

### 2026-06-28: docs archive move needs link validation

- Context: docs整理後のリンク修正作業
- Friction: archive 移動後、active docs だけでなく archive 内の相対リンク切れも手動確認が必要だった
- Idea: local Markdown link checker を check/devtool 化し、active docs は fail、archive は policy に応じて warn/fail に分ける
- Candidate type: check / devtool
- Related tool/doc: `tools/check.sh`, `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
