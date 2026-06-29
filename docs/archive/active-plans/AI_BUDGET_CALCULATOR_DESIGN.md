# AI Budget Calculator Design

Status: **P1-P4 実装済み / P5-P7 未着手**
実装: `src_next/calc/envelope_calc.bqn`, CLI: `tools/envelope-calc`

Note (2026-06-29): examples that mention `bqn main.bqn` are historical traces from the original consultation. Current daily operation starts from `tools/bl`; non-interactive report output is `tools/report`; envelope consultation calculations should prefer `tools/envelope-calc`.

## 1. 目的

AI（pit）が家計相談に答えるときに使う計算を、その場の ad-hoc Python や暗算ではなく、
BQN canonical engine の延長として整備するための設計材料を集める文書です。

### 背景

2026-06-24 の食費ペース相談で、pit は次のような計算を ad-hoc Python で行いました：

- 理想消化額（経過日数ベース）
- 超過額
- ペースラインまでの復帰日数（1日上限額を変えたとき）
- 目標復帰日数に対する1日上限額

これらは一時的な計算ではなく、「封筒残高・経過日数・残日数」という
Canonical Daily Cube 由来のデータに対する汎用計算です。
BQN エンジン側で整備すれば、AI の回答精度と一貫性が上がります。

## 2. ユースケース（実例から）

### 2.1 封筒ペース超過の復帰計算

相談例（2026-06-24）:

- 食費 allocated=40,000, spent=7,751, days_elapsed=9, days_total=60
- 「あと何日、1日いくら以内ならペースラインに戻るか？」

必要な計算プリミティブ:

1. `ideal_spent = allocated × elapsed / total`（理想消化額）
2. `overshoot = spent - ideal_spent`（超過額）
3. `days_to_recover(daily_limit)` → 復帰日数
4. `daily_limit_for_recovery(target_days)` → 目標復帰日数に対する1日上限

### 2.2 封筒の枯渇予測

「このペースだと封筒がいつ空になるか？」

必要な計算プリミティブ:

1. `daily_burn_rate = spent / elapsed`（現在の消化速度）
2. `days_until_empty = remaining / daily_burn_rate`（枯渇までの日数）
3. `empty_date = today + days_until_empty`（枯渇予定日）
4. 残日数と比較して `shortfall_days = days_total - elapsed - days_until_empty`

### 2.3 封筒間の再配分シミュレーション

「タバコを 500→300/日 に減らして、食費に +200/日 回すとどうなるか？」

必要な計算プリミティブ:

1. `new_daily = old_daily - transfer + received_transfer`
2. 各封筒の新しい残高・残日数・ペース判定
3. 再配分後の全体健康診断（SAFE/WARN/SHORT/DRAWN の変化）

### 2.4 次の収入日までの生存判定

「残日数51日、流動資産93,548、予定支払い12,692。大丈夫か？」

必要な計算プリミティブ:

1. `free_liquid = liquid - planned_payments - fixed_obligation_reserve`
2. `survival_daily = free_liquid / days_left`
3. 封筒日割りとの比較（survival_daily >= sum(envelope_dailies)?）

### 2.5 前サイクル同区間との比較コメント

「食費が前年同期間比 57% で減ってる。これは良い傾向か継続的なものか？」

必要な計算プリミティブ:

1. `ratio = current / baseline`
2. `delta_count = current_count - baseline_count`
3. 件数変化も含めた解釈（金額減＝単価減なのか回数減なのか）

## 3. 計算プリミティブ一覧

上記ユースケースから抽出した汎用プリミティブ:

| # | プリミティブ | 入力 | 出力 | 用途 |
|---|---|---|---|---|
| P1 | `envelope_pace` | allocated, spent, elapsed, total | ideal_spent, overshoot, daily_actual, daily_target, pace_ratio, health | 封筒の現在ペース診断 |
| P2 | `envelope_recovery` | allocated, spent, elapsed, total, daily_limit | days_to_recover | 指定した1日上限でペースラインに復帰する日数 |
| P3 | `envelope_recovery_target` | allocated, spent, elapsed, total, target_days | required_daily_limit | 指定した日数で復帰するための1日上限 |
| P4 | `envelope_depletion` | remaining, spent, elapsed, total | burn_rate, days_until_empty, shortfall_days | 枯渇予測 |
| P5 | `envelope_transfer` | envelopes[], from_envelope, to_envelope, transfer_amount, elapsed, total | new_envelopes[] | 封筒間再配分シミュレーション |
| P6 | `survival_check` | liquid, planned_payments, fixed_reserve, days_left, envelope_dailies[] | survival_daily, surplus_or_shortfall, verdict | 収入日までの生存判定 |
| P7 | `cycle_comparison_comment` | current_value, baseline_value, current_count, baseline_count | ratio, count_delta, interpretation_hint | 前年同期間比の解釈補助 |

## 4. 責務の配置（Seam Reduction 準拠）

BQN canonical engine の責務（計算・意味解釈）と、Bash/Go の責務（表示・選択・安全追記）を混ぜません。

| 層 | 責務 | この計算機の置き場所 |
|---|---|---|
| **BQN** | 計算・意味解釈・export | 本体。全プリミティブを pure function として実装 |
| **Bash** | UI・選択・呼び出し | pit からの質問を関数呼び出しに変換する thin wrapper（将来） |
| **Go** | 安全な TSV append | 関与しない（この計算機は read-only） |
| **AI (pit)** | 質問理解・回答整形 | プリミティブの結果を受け取り自然言語に変換 |

### 設計ルール

1. 計算プリミティブは BQN の pure function として実装する。
2. 封筒名（`食費`, `タバコ` 等）や policy label（`daily`, `flex` 等）を engine concept として hard-code しない。
3. プリミティブは引数でデータを受け取り、結果を返す。TSV や `data/` にアクセスしない。
4. プリミティブは既存の `report_engine.bqn` / Canonical Daily Cube の出力を入力として使える形にする。
5. この計算機自体は read-only。正データを変更しない。

### 想定モジュール配置（仮）

```text
src/calc/
  envelope_pace.bqn         # P1: 封筒ペース診断
  envelope_recovery.bqn     # P2-P3: 復帰計算
  envelope_depletion.bqn    # P4: 枯渇予測
  envelope_transfer.bqn     # P5: 再配分シミュレーション
  survival_check.bqn        # P6: 生存判定
  cycle_comparison.bqn      # P7: 前年同期間比
```

## 5. 既存エンジンとの関係

| 既存モジュール | 関係 |
|---|---|
| `report_engine.bqn` | プリミティブの入力元。`r.envelope_*` や `r.cycle_*` を引数にできる |
| `envelope_view.bqn` | 封筒健康診断のロジック。`envelope_pace` と重複しうる。機能重複を避け、既存コードを pure function 化して再利用する |
| `main.bqn` | 変更しない。プリミティブは main.bqn とは独立 |
| `src_next` | 将来的に src_next からも同じプリミティブを呼べるようにする。ただし今は current engine の出力を入力にする |

## 6. 実装しないもの

- 自然言語生成エンジン（AI/pit の責務）
- 封筒名・policy label の hard-code
- `data/` への書き込み
- `main.bqn` への統合（当面は独立）
- TUI/GUI/Web UI（表示は pit の回答テキストで十分）
- 機械学習や予測モデル（単純な算術と線形外挿で十分）

## 7. 実装状況

| プリミティブ | 状態 | 実装場所 |
|---|---|---|
| P1 envelope_pace | ✅ 実装済み | `src_next/calc/envelope_calc.bqn` |
| P2 DaysToRecover | ✅ 実装済み | `src_next/calc/envelope_calc.bqn` |
| P3 RequiredDailyLimit | ✅ 実装済み | `src_next/calc/envelope_calc.bqn` |
| P4 EnvelopeDepletion | ✅ 実装済み | `src_next/calc/envelope_calc.bqn` |
| P5 envelope_transfer | 未着手 | — |
| P6 survival_check | 未着手 | — |
| P7 cycle_comparison | 未着手 | — |

CLI ツール: `tools/envelope-calc`（pace/recover/recover-target/deplete/list）
テスト: `tests/test_src_next_calc_envelope_calc.bqn`
AGENTS.md に登録済み。

### 丸め基準の差異について

P1（EnvelopePace）と P2（DaysToRecover）では超過額（overshoot）の定義が異なる：

| プリミティブ | overshoot 定義 | 例 (a=40000,s=8815,e=12,t=60) |
|---|---|---|
| P1 EnvelopePace | `spent - floor(allocated × elapsed / total)` | 8815 - 8000 = **815** |
| P2 DaysToRecover | `spent - floor(allocated / total) × elapsed` | 8815 - 7992 = **823** |

P1 は「比例按分した理想消化額との差」を表し、P2 は閉形式の復帰計算に必要な `daily_target × elapsed` との差を使う。
この差異は整数除算の順序によるもので、予算の1%未満。P2 は保守的（安全側）に倒れるため、実害はない。
相談時には「pace で出る超過額」と「recover の内部計算で使う超過額」が微妙に異なることを認識すれば十分。

## 8. 次のステップ

1. ~~**設計合意**: この文書の方向性を moko と確認~~ ✅
2. ~~**P1-P4 実装**~~ ✅ (2026-06-27)
3. **P5（封筒間再配分シミュレーション）**: タバコ→食費の振替など、複数封筒をまたぐ操作
4. **P6（生存判定）**: 残日数と流動資産から「次の収入日まで大丈夫か」
5. **P7（前期比較コメント）**: actual_comparison の結果に対する自然言語コメント生成

## 8. 関連文書

- `docs/ARCHITECTURE.md` — データフロー・モジュール責務・二大目的
- `docs/AI_CODEMAP.md` — pit 向けコード地図
- `docs/CANONICAL_DAILY_CUBE.md` — Day × Account × Layer 固定契約
- `docs/REPORT_FIELD_MAP.md` — `report_engine.Build` の出力 field 一覧（プリミティブの入力候補）
- `docs/MAIN_SECTIONS.md` — 12セクションの IO マップ
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — configurable household report policy contract（封筒計算の policy boundary）
- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — セクション parity matrix
- `docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md` — AI 開発効率化の提案集（ツール・デバッグ支援）

## Appendix A: 相談ログ（Consultation Log）

実際に AI（pit）が家計相談に答えた記録。
新しい相談が来るたびに追記し、プリミティブ設計の材料にする。

### 凡例

| 項目 | 意味 |
|---|---|
| 日付 | 相談日 |
| 質問 | ユーザーの原文 |
| トリガー | 相談のきっかけ（レポートのどの数字を見ての質問か） |
| 必要なデータ | pit が回答に使った数値（どのレポートセクションから抽出したか） |
| データ取得 | pit が実行したコマンド |
| 計算 | pit がその場でした計算の方法・スクリプト |
| 回答形式 | pit が出力した回答の構造 |
| プリミティブ候補 | この相談から抽出された汎用プリミティブ |
| トリガーした設計 | この相談がきっかけで生まれた設計文書や実装判断 |

---

### 相談 #1: 食費ペース復帰計算

| 項目 | 内容 |
|---|---|
| 日付 | 2026-06-24 |
| 質問 | 「食費は何日くらい節約するといいペースに戻る？」 |
| トリガー | `bqn main.bqn` の Sec5（封筒・予算残高）で食費が **WARN** になっているのを見て |
| 必要なデータ | `allocated=40000, spent=7751, days_elapsed=9, days_total=60`（Sec5 封筒テーブル + Sec4 cycle 情報から抽出） |
| データ取得 | `bqn main.bqn` を実行し、Sec5 の食費行と Sec4 の cycle 期間から数値を読み取り |
| 計算 | pit がその場で python3 スクリプトを書き、`overshoot = spent - ideal_spent` を求め、`daily_limit` と `target_days` の2方向から復帰条件を計算 |
| 回答形式 | 2つの表: (a) 1日上限額→復帰日数（400円/日で7日, 500円/日で11日...）, (b) 目標日数→1日上限（1週間で417円以内, 10日で492円以内...）＋「1週間400円台を意識すれば7月初に復帰」という自然言語まとめ |
| プリミティブ候補 | P1（envelope_pace）, P2（envelope_recovery）, P3（envelope_recovery_target） |
| トリガーした設計 | `docs/AI_BUDGET_CALCULATOR_DESIGN.md` の作成依頼 |

#### pit の動作トレース

```text
# 1. レポート全体を取得
bqn main.bqn
  → Sec4: cycle 2026-06-15〜2026-08-13, 60日
  → Sec5: 食費 allocated=40000, spent=7751, balance=32249, health=WARN

# 2. 数値の意味を解釈
  elapsed = 9日 (2026-06-15 → 2026-06-24)
  total = 60日
  ideal_spent = 40000 × 9/60 = 6000
  overshoot = 7751 - 6000 = 1751
  daily_target = 40000/60 = 667
  daily_actual = 7751/9 = 861

# 3. 復帰計算（python3 で即席スクリプト）
  for daily_limit in [0, 200, 300, 400, 500, 600]:
    days = overshoot / (daily_target - daily_limit)
  for target_days in [3, 5, 7, 10, 14]:
    max_daily = (budget*(elapsed+target_days)/total - spent) / target_days

# 4. 回答整形
  表 + 自然言語アドバイス（「自炊＋コンビニ飯減＋缶コーヒーは別勘定」）
```

#### 入力データの出所（report_engine field との対応）

| 計算に使った値 | レポート上の表示位置 | report_engine field（推定） |
|---|---|---|
| allocated (40,000) | Sec5 封筒テーブル allocated 列 | `r.env_allocated` の食費行 |
| spent (7,751) | Sec5 封筒テーブル spent 列 | `r.env_spent` の食費行 |
| days_elapsed (9) | Sec9 基準日と cycle start の差 | `r.days_elapsed` |
| days_total (60) | Sec4 cycle 期間 | `r.days_in_cycle` |
| health (WARN) | Sec5 health 列 | `r.env_health` |

---

### 相談 #2: 食費・一般生活の枯渇予測と節約復帰

| 項目 | 内容 |
|---|---|
| 日付 | 2026-06-27 |
| 質問 | 「食費と一般生活費の封筒がいい感じの数値に戻るのは今のペースだといつくらいになる？」「食費は一週間くらい節約できたらどう変化する？」 |
| トリガー | レポート Sec5 封筒テーブルで食費 WARN / 一般生活 SHORT |
| 必要なデータ | 食費(allocated=40000, spent=8815), 一般生活(allocated=27857, spent=14250), elapsed=12, total=60 |
| データ取得 | `tools/envelope-calc deplete 食費` / `tools/envelope-calc deplete 一般生活` / `tools/envelope-calc recover-target 食費 7` |
| 計算 | P4（枯渇予測）と P3（復帰計算）によりツールが自動計算 |
| 回答形式 | 枯渇日数＋不足日数＋節約時の1日上限額の表 |
| プリミティブ候補 | P3, P4（両方使用） |
| トリガーした設計 | P1-P4 の実装 + `tools/envelope-calc` CLI |

#### pit の動作トレース
```bash
tools/envelope-calc deplete 食費       # → 枯渇まで43日、不足5日
tools/envelope-calc deplete 一般生活   # → 枯渇まで12日、不足36日
tools/envelope-calc recover-target 食費 7  # → 1日上限550円
tools/envelope-calc recover 食費 550      # → 復帰まで8日
```

---

### 相談テンプレート（新規相談用）

```markdown
### 相談 #N: （タイトル）

| 項目 | 内容 |
|---|---|
| 日付 | YYYY-MM-DD |
| 質問 | （原文） |
| トリガー | |
| 必要なデータ | |
| データ取得 | |
| 計算 | |
| 回答形式 | |
| プリミティブ候補 | |
| トリガーした設計 | |

#### pit の動作トレース
（実行コマンドとデータフロー）

#### 入力データの出所
| 計算に使った値 | レポート上の表示位置 | report_engine field（推定） |
|---|---|---|
| | | |
```
