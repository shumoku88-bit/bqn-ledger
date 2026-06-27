# Docs Hygiene Audit 2026-06-22

Status: **docs hygiene complete / all stale docs compressed to historical stubs / archive digests created**
Date: 2026-06-22 / updated 2026-06-26
Date: 2026-06-22

## 目的

ドキュメントが増えてきたため、現行仕様、進行中計画、完了済み計画、履歴メモを分けて読むための整理台帳を作る。

この監査では、どの文書が現役で、どの文書が archive 候補かを見える化する。
archive 移動は、小さなコミットに分けて段階的に行う。

合言葉:

```text
今読む地図と、昔の航海日誌を分ける。
```

## 監査範囲

今回確認した入口:

- `README.md`
- `AGENTS.md`
- `TODO.md`
- `docs/README.md`
- `docs/AI_CODEMAP.md`
- 主要設計書の先頭 status / current decision / 完了状況

制限:

- GitHub connector から repo 全体の再帰 tree 一覧は取得できなかった。
- したがって、完全な未参照ファイル検出ではなく、入口文書から見える範囲の一次監査である。
- archive や削除は、別コミットで小さく行う。

## 分類ルール

| 分類 | 意味 | 置き場所 |
|---|---|---|
| current spec | 現行仕様・現在の契約 | `docs/` に残す |
| active plan | 今後の作業対象 | `TODO.md` または `docs/` に残す |
| decision record | 実装済みだが判断記録として重要 | 現行docsから参照しつつ必要なら archive |
| completed plan | 完了済みチェックリスト | `docs/archive/completed-plans/` 候補 |
| superseded note | 後続文書に置き換わった古い設計メモ | status note / digest / archive |
| deleted feature note | 機能・exportが削除済みの要件書 | archive 候補 |

## 実施済み

### Phase 1: 入口の整備

状態: **完了**

- `docs/README.md` を docs 全体の目次として更新。
- `AGENTS.md` の最初に読むリストへ `docs/README.md` と docs hygiene audit を追加。
- `README.md` のドキュメント導線へ `docs/README.md` と docs hygiene audit を追加。

### Phase 2: archive 高候補の移動

状態: **完了**

| original | archived to | note |
|---|---|---|
| `docs/PLAN_ID_BACKFILL_PREVIEW.md` | `docs/archive/completed-plans/PLAN_ID_BACKFILL_PREVIEW.md` | 適用済み plan_id backfill 記録 |
| `docs/NEXT_CYCLE_AI_REPORT_REQUIREMENTS.md` | `docs/archive/completed-plans/NEXT_CYCLE_AI_REPORT_REQUIREMENTS.md` | 削除済み AI次サイクル相談 export 要件 |
| `docs/GO_SOURCE_TSV_EDITOR_APPEND_ONLY_DECISIONS.md` | `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_APPEND_ONLY_DECISIONS.md` | `GO_EDITOR_NEXT_PLAN.md` へ吸収済み |

### Phase 3: stale 文書への status note 追加

状態: **完了**

| file | status note | 現行で優先する文書 |
|---|---|---|
| `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` | `docs/GO_SOURCE_TSV_EDITOR_DESIGN.status.md` | `docs/GO_EDITOR_NEXT_PLAN.md` |
| `docs/GENERALIZATION_TODO.md` | `docs/GENERALIZATION_TODO.status.md` | `TODO.md`, `docs/GENERALIZATION_TODO.status.md` |
| `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` | `docs/BEHAVIOR_DRIFT_REPORT_PLAN.status.md` | `docs/ACTUAL_COMPARISON_REPORT_PLAN.md`, `docs/REPORT_DESIGN.md` |

### Phase 4: Canonical hardening TODO の圧縮

状態: **完了**

実施済み:

- `docs/CANONICAL_ENGINE_HARDENING_TODO.status.md` を作成・更新。
- `docs/archive/completed-plans/CANONICAL_ENGINE_HARDENING_COMPLETED_PHASES.md` を作成。
- `docs/CANONICAL_ENGINE_HARDENING_TODO.md` を active remainder へ圧縮。
- `docs/README.md` の導線を更新。

残した active remainder:

- Safety Profile invariant mapping.
- Section status policy: `OK / WARN / ERROR / SKIPPED / UNAVAILABLE`.
- Failure fixtures that prevent polished wrong reports.
- Debug / provenance sections.
- External reasoning role decision.
- Later items from Phase 11.

### Phase 5: stale / long docs の decision digest 作成

状態: **完了**

| source | digest | current status |
|---|---|---|
| `docs/GENERALIZATION_TODO.md` | `docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md` | active remainder pending |
| `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` | `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_DECISIONS.md` | historical decisions digest archived |
| `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` | `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md` | historical design decisions digest archived |

These original long documents are preserved for now. Their status notes and digest files define how to read them.

## 現役入口として残す文書

| file | 判定 | 理由 |
|---|---|---|
| `README.md` | current spec入口 | repo全体の入口。基本方針とドキュメント導線を持つ。 |
| `AGENTS.md` | current agent入口 | AI作業者の最初の導線と禁止事項。 |
| `TODO.md` | active plan | 現在進行中・次に着手する作業だけを置く場所。 |
| `docs/README.md` | current docs入口 | docs配下の目次。現行仕様・進行中計画・履歴を分ける中心。 |
| `docs/AI_CODEMAP.md` | current code map | pit向けコード地図。 |
| `docs/ARCHITECTURE.md` | current spec | データフロー・モジュール責務。 |
| `docs/CANONICAL_DAILY_CUBE.md` | current spec | `Day × Account × Layer` の中心契約。 |
| `docs/SAFETY_PROFILE.md` | active principle | fail closed / invariant / 正データ保護の安全規格。 |
| `docs/GO_EDITOR_NEXT_PLAN.md` | active plan | Go editor の現在の実装境界と次候補。 |
| `docs/ACTUAL_COMPARISON_REPORT_PLAN.md` | decision record / current report plan | `actual-comparison` の実装済み決定メモ。 |

## Historical / digest map

| long or completed source | current reading path |
|---|---|
| `docs/CANONICAL_ENGINE_HARDENING_TODO.md` | compressed active remainder + `docs/archive/completed-plans/CANONICAL_ENGINE_HARDENING_COMPLETED_PHASES.md` |
| `docs/GENERALIZATION_TODO.md` | `docs/GENERALIZATION_TODO.status.md` + `docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md` |
| `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` | `docs/BEHAVIOR_DRIFT_REPORT_PLAN.status.md` + `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_DECISIONS.md` |
| `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` | `docs/GO_SOURCE_TSV_EDITOR_DESIGN.status.md` + `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md` |

## 残っている整理候補

すべて対応済み:

- [x] `docs/GENERALIZATION_TODO.md` → historical stub 化済み（2026-06-22 Phase 5 以前に実施）
- [x] `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` → historical stub 化済み
- [x] `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` → historical stub 化済み

状態: **docs hygiene pass 完了**

## 今回は実施しないこと

- 正データ TSV の編集。
- 実装コードの変更。
- 仕様内容の変更。
- 古い判断記録の完全統合。
- Go editor の書き込み範囲拡大。
- 削除済み report/export の復活。

## 推奨作業順

状態: **docs hygiene pass 完了** ✅

全 stale 文書は historical stub に圧縮済み。archive digests 作成済み。
DOCS_HYGIENE_AUDIT の役割は完了。今後の docs 整理は通常 TODO の一部として扱う。
