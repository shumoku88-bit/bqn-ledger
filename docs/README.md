# docs README

このディレクトリは、`bqn-ledger` の仕様・設計・運用ルールを置く場所です。

重要: ここでは **現行仕様 / 進行中計画 / 履歴メモ** を分けて扱います。
古いTODOや完了済み計画を、現行仕様として読まないでください。

---

## moko が普段読む場所

普段は全部読まなくてよい。まずこの5つだけを見ます。

1. `TODO.md` - 今やること、次に着手すること
2. `docs/QUALITY_BAR.md` - 判断基準
3. `docs/ARCHITECTURE.md` - 全体構造と責務境界
4. `docs/AI_CODEMAP.md` - コード地図
5. `docs/SAFETY_PROFILE.md` - 壊れた時に止める規格

迷ったら `TODO.md` へ戻ります。過去の長い計画や判断記録は、必要になった時だけ辿ります。

---

## まず読む（pit向け最短ルート）

1. [AI_CODEMAP.md](AI_CODEMAP.md) - pit向けコード地図
2. [../TODO.md](../TODO.md) - 現在進行中・次に着手する作業だけ
3. [QUALITY_BAR.md](QUALITY_BAR.md) - production-grade personal tool として扱う品質基準
4. [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md) - プロ級へ詰める導線・次の一手
5. [SAFETY_PROFILE.md](SAFETY_PROFILE.md) - fail closed / 正データ保護 / invariant の小さな安全規格
6. [SAFETY_PROFILE_INVARIANT_MAP.md](SAFETY_PROFILE_INVARIANT_MAP.md) - Safety Profile invariant と既存 check / lint / fixture の対応表
7. [ARCHITECTURE.md](ARCHITECTURE.md) - 現行データフローとモジュール責務
8. [CANONICAL_DAILY_CUBE.md](CANONICAL_DAILY_CUBE.md) - `Day × Account × Layer` の固定契約
9. [POSTING_IR_CONTRACT.md](POSTING_IR_CONTRACT.md) / [TBDS_CONTRACT.md](TBDS_CONTRACT.md) - Posting IR と試算表データセットの境界契約
10. [PLAN_ID_LIFECYCLE.md](PLAN_ID_LIFECYCLE.md) - `plan_id` ライフサイクル契約 (Go/BQN 共通契約)
11. [TIME_AS_AXIS.md](TIME_AS_AXIS.md) - 時間座標・区間ビュー
12. [DATA_DIR_SETUP.md](DATA_DIR_SETUP.md) - データ配置の設定マニュアル
13. [UNAVAILABLE_SENTINEL_CONTRACT.md](UNAVAILABLE_SENTINEL_CONTRACT.md) - unavailable sentinelの定義
14. [CONVENTIONS.md](CONVENTIONS.md) / [JOURNAL_META.md](JOURNAL_META.md) - 科目命名・メタデータ規約
15. 変更内容に応じて、下の「Done / Current Baseline (完了済み・現行仕様として機能)」を参照

---

## Done / Current Baseline (完了済み・現行仕様として機能)

- [QUALITY_BAR.md](QUALITY_BAR.md)
  - production-grade personal tool として扱うための品質基準。
- [SAFETY_PROFILE.md](SAFETY_PROFILE.md) / [SAFETY_PROFILE_INVARIANT_MAP.md](SAFETY_PROFILE_INVARIANT_MAP.md)
  - 予測可能性、fail closed、正データ保護、不変条件の安全規格とその対応表。
- [GO_EDITOR_USAGE.md](GO_EDITOR_USAGE.md)
  - Go 製 source TSV editor (`tools/edit`) の使い方。
- [CONVENTIONS.md](CONVENTIONS.md)
  - 勘定科目の命名、TSVスキーマ、メタデータ定義などの規約。
- [JOURNAL_META.md](JOURNAL_META.md)
  - `journal.tsv` / `plan.tsv` で使用できるメタデータの一覧。
- [MAINTENANCE.md](MAINTENANCE.md)
  - データのバックアップやメンテナンス手順。
- [CYCLE.md](CYCLE.md)
  - サイクル集計期間の変更・設定マニュアル。
- [ADD_UI_USAGE.md](ADD_UI_USAGE.md)
  - 日常の取引入力UI (`tools/add-ui.sh`) のマニュアル。

---

## 履歴・アーカイブ

不要になった過去のドキュメントや移行期の資料、現在非アクティブな計画書は、すべて [archive/](archive/) ディレクトリに整理・退避されています。

*   **[archive/active-plans/](archive/active-plans/)**: 現在進行中、または待機中(Backlog)の計画書・設計メモ。
*   **[archive/completed-plans/](archive/completed-plans/)**: 実装完了済みの計画書・意思決定メモ。
*   **[archive/src-next-migration/](archive/src-next-migration/)**: 旧エンジンから `src_next` への移行フェーズに関わる検証・ログ類。
*   **[archive/audits/](archive/audits/)**: 過去に実施した一時的な drift 監査や section 監査のワークシート。
*   **[archive/handoffs/](archive/handoffs/)**: 過去の開発セッション間ハンドオフファイル。
