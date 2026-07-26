#!/usr/bin/env python3
"""Temporary branch-only helper for synchronizing AI_CODEMAP during topology audit."""

from pathlib import Path

path = Path("docs/AI_CODEMAP.md")
text = path.read_text(encoding="utf-8")
marker = "SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md"

if marker in text:
    raise SystemExit(0)

old_list = """1. `docs/AI_CODEMAP.md`（このファイル）
2. `TODO.md`（現在進行中・次に着手する作業だけ）
3. `docs/QUALITY_BAR.md`（品質基準）
4. `docs/SRC_NEXT_CURRENT.md`（`src_next` が現在の普段使い report engine であること、旧 migration docs の扱い）
5. `docs/DEVELOPER_INSPECTION_ENTRYPOINT.md`（低層診断入口と `main.bqn` 互換wrapper）
6. `docs/ARCHITECTURE.md`（データフロー・モジュール責務）
7. `docs/CANONICAL_DAILY_CUBE.md`（固定するDaily Cube契約）
8. `docs/TIME_AS_AXIS.md`（時間座標・観察時点・区間view）
9. projection変更なら `docs/archive/active-plans/PURPOSE_SPECIFIC_PROJECTION_COMPOSITION_DIRECTION-2026-07-25.md`、`docs/archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`、該当する `src_next/*` consumer
10. レポート変更なら `src_next/report.bqn` と該当する `src_next/*` モジュール、`docs/REPORT_CONTRACTS.md` / `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`、および現行の report 関連 check
11. エディタ作業なら `docs/PRODUCTION_EDITOR_DIRECTION.md` / `docs/BQN_EDITOR_USAGE.md` / `src_edit/README.md`
12. 複数ポスティング導入検討なら `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`
13. 変更内容に応じて `docs/CONVENTIONS.md` / `docs/JOURNAL_META.md` / `docs/MAINTENANCE.md`
14. 履歴・背景（非アクティブな計画書、旧エンジン移行期資料、完了済みの計画書など）が必要な場合のみ `docs/archive/` を読む
15. AIによる家計相談計算の設計なら `docs/archive/active-plans/AI_BUDGET_CALCULATOR_DESIGN.md`
"""
new_list = """1. `docs/AI_CODEMAP.md`（このファイル）
2. `TODO.md`（現在進行中・次に着手する作業だけ）
3. `docs/QUALITY_BAR.md`（品質基準）
4. `docs/SRC_NEXT_CURRENT.md`（`src_next` が現在の普段使い report engine であること、旧 migration docs の扱い）
5. `docs/DEVELOPER_INSPECTION_ENTRYPOINT.md`（低層診断入口と `main.bqn` 互換wrapper）
6. `docs/ARCHITECTURE.md`（データフロー・モジュール責務）
7. `docs/CANONICAL_DAILY_CUBE.md`（固定するDaily Cube契約）
8. `docs/TIME_AS_AXIS.md`（時間座標・観察時点・区間view）
9. `src_next`のfile moveなら `docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md` と `tools/src-next-import-graph`
10. projection変更なら `docs/archive/active-plans/PURPOSE_SPECIFIC_PROJECTION_COMPOSITION_DIRECTION-2026-07-25.md`、`docs/archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`、該当する `src_next/*` consumer
11. レポート変更なら `src_next/report.bqn` と該当する `src_next/*` モジュール、`docs/REPORT_CONTRACTS.md` / `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`、および現行の report 関連 check
12. エディタ作業なら `docs/PRODUCTION_EDITOR_DIRECTION.md` / `docs/BQN_EDITOR_USAGE.md` / `src_edit/README.md`
13. 複数ポスティング導入検討なら `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`
14. 変更内容に応じて `docs/CONVENTIONS.md` / `docs/JOURNAL_META.md` / `docs/MAINTENANCE.md`
15. 履歴・背景（非アクティブな計画書、旧エンジン移行期資料、完了済みの計画書など）が必要な場合のみ `docs/archive/` を読む
16. AIによる家計相談計算の設計なら `docs/archive/active-plans/AI_BUDGET_CALCULATOR_DESIGN.md`
"""

replacements = [
    (old_list, new_list),
    (
        "- `src_next/developer_inspection.bqn` が低層diagnostic implementationのownerである。`src_next/main.bqn`は一時的な互換wrapperに限定し、実装を戻さない。productionは `tools/report` → `src_next/report.bqn` の境界を保つ。\n",
        "- `src_next/developer_inspection.bqn` が低層diagnostic implementationのownerである。`src_next/main.bqn`は一時的な互換wrapperに限定し、実装を戻さない。productionは `tools/report` → `src_next/report.bqn` の境界を保つ。\n"
        "- `src_next`のdirectory移動は、`tools/src-next-import-graph --validate`とrepository-wide caller searchを先に行い、一つのcoherent neighborhoodだけを動かす。high fan-in hubやentrypointを最初の実験にせず、空のdirectory skeletonを先に作らない。\n",
    ),
    (
        "`actual_expense_ranking.bqn`は現時点でpublic report sectionへ配線されていない。checked selected-domain posting factsを使うpurpose-specific consumerとして、public synthetic fixtureとfocused testでcharacterizeされている。\n",
        "`actual_expense_ranking.bqn`は現時点でpublic report sectionへ配線されていない。checked selected-domain posting factsを使うpurpose-specific consumerとして、public synthetic fixtureとfocused testでcharacterizeされている。\n\n"
        "現在の`src_next`は71 BQN module中69 moduleがroot直下にあり、direct import graphは276 edge、欠損target 0、cycle 0です。point-in-time evidenceと移動順序は`docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md`を正とします。最初の候補は`actual_expense_ranking.bqn`と`exact_sparse_grouping.bqn`を一緒に`src_next/queries/`へ移すfinite sliceですが、このaudit PRではまだcurrent pathを変更しません。\n",
    ),
    (
        "- `check-src-next-golden.sh` — `developer_inspection.bqn`のpublic fixture goldenチェック。projection header、tabular rows、source-balance表示も固定する。\n",
        "- `check-src-next-golden.sh` — `developer_inspection.bqn`のpublic fixture goldenチェック。projection header、tabular rows、source-balance表示も固定する。\n"
        "- `check-src-next-import-graph.sh` — `src_next/**/*.bqn`のdirect `•Import` target、root/nested module観測、required entrypoint、cycle report生成を検証する。`check-repo-index.sh`経由でfull checkに入る。\n",
    ),
    (
        "- `tools/repo-index` — リポジトリの BQN ファイルやチェックスクリプトの索引を管理。ファイル追加・削除時は `--baseline` で更新する。\n",
        "- `tools/repo-index` — リポジトリの BQN ファイルやチェックスクリプトの索引を管理。ファイル追加・削除時は `--baseline` で更新する。\n"
        "- `tools/src-next-import-graph` — `src_next/**/*.bqn`のrelative direct importをread-onlyに列挙し、summary、module degree、cycle、Graphviz DOT、missing-target validationを出す。directory migration前後のtopology evidenceに使う。\n",
    ),
]

for old, new in replacements:
    if old not in text:
        raise SystemExit(f"expected codemap anchor not found: {old[:80]!r}")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
