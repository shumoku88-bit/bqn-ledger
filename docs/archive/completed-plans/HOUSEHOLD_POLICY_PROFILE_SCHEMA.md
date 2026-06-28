# Household Policy Profile Schema

Status: **Phase 2 / minimal schema design**
Date: 2026-06-26
Source: `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md` Phase 2
Previous: `docs/HOUSEHOLD_POLICY_ASSUMPTION_AUDIT.md` (Phase 1)

## 1. 設計方針

### 1.1 最小限主義

Policy profile schema は、**今すぐに全部の生活スタイルを実装するためではなく、差し替え可能であることを証明するために必要最小限のもの**だけを定義する。

```text
「moko の封筒スタイル」と「月給カレンダー月スタイル」の2つを fixture で動かせること
→ そのために必要なキーだけを定義する
```

### 1.2 配置場所

| 層 | ファイル | 役割 |
|---|---|---|
| system defaults | `config/system_defaults.tsv` | ファイルパス等のインフラ設定 |
| profile defaults | `config/default_config.tsv` | デフォルトの policy 値 |
| production override | `data/config.tsv` | moko の実際の設定 |

Phase 2 では **新しいファイルは作らない**。既存の `config/default_config.tsv` と `data/config.tsv` にキーを追加する。

### 1.3 既存キーは壊さない

`HOUSEHOLD_GROUP_*` キーはすでに運用中。これらのセマンティクスを文書化し、上に新しいキーを積む。既存キーの削除や改名はしない。

## 2. 既存ポリシーキーの体系化

### 2.1 封筒グループ（HOUSEHOLD_GROUP_*）

```
キー: HOUSEHOLD_GROUP_LIFE
型:   comma-separated string (例: "daily,flex")
意味: 生活費グループに属する budget_group のラベル一覧。
      先頭から順に IsDailyGroup (life[0]), IsFlexGroup (life[1]) として参照される。
必須: yes (Required)

キー: HOUSEHOLD_GROUP_RESERVE
型:   comma-separated string (例: "reserve")
意味: 予備費グループに属する budget_group のラベル一覧。
      表示順で life groups の後に来る。
必須: yes (Required)

キー: HOUSEHOLD_GROUP_ORDER
型:   comma-separated string (例: "daily,flex,reserve")
意味: 表示時のグループ優先順。この順でソートされる。
必須: yes (Required)
```

**既知の制約（Phase 1 audit より）:**
- `IsDailyGroup` は `life_groups[0]` のラベルと照合（index-based）
- `IsFlexGroup` は `life_groups[1]` のラベルと照合（index-based）
- `GetPri`（表示優先順）は `⟨"daily","flex","reserve"⟩` を hardcode（`envelope_computation.bqn:358`）
- → Phase 3 で `HOUSEHOLD_GROUP_ORDER` と `HOUSEHOLD_GROUP_LIFE` を使って解決するように修正予定

### 2.2 予算内部口座（BUDGET_*）

```
キー: BUDGET_PREFIX
型:   string (例: "budget:")
意味: 予算口座の名前空間プレフィックス。
必須: yes

キー: BUDGET_ID_OPENING
型:   string (例: "budget:opening")
意味: 期首予算振替先の口座名。
必須: yes

キー: BUDGET_ID_UNASSIGNED
型:   string (例: "none")
意味: 未割当前の予算が滞留する口座名。"none" で無効化。
必須: yes

キー: BUDGET_ID_SPENT
型:   string (例: "budget:spent")
意味: 予算消費の集計口座名。
必須: yes
```

### 2.3 サイクル解決（cycle.tsv）

```
キー: mode
型:   enum ("fixed" | "incomeAnchor" | "calendarMonth")
意味: サイクル期間の解決方法。コード内では未使用の文字列は unavailable 扱い。
場所: cycle.tsv

キー: start, end_exclusive
型:   date string ("YYYY-MM-DD")
意味: mode=fixed のときの固定期間。
場所: cycle.tsv

キー: income_account
型:   account name string (例: "income:年金")
意味: mode=incomeAnchor のときの収入基準口座。
場所: cycle.tsv

キー: offset
型:   integer
意味: incomeAnchor で何期前を見るか（0=直近, 1=1期前）。
場所: cycle.tsv
```

### 2.4 勘定メタデータ（accounts.tsv の key=value 列）

```
キー: role
型:   enum ("asset" | "liability" | "income" | "expense" | "equity")
意味: 会計上の役割。prefix fallback あり（"expenses:"→expense, "income:"→income）。
場所: accounts.tsv

キー: type
型:   enum ("liquid" | "savings" | "invest")
意味: 資産の流動性分類。負債・収入・費用には不要。
場所: accounts.tsv

キー: budget
型:   string (budget account name)
意味: この費用口座がどの封筒予算口座に紐づくか。
場所: accounts.tsv

キー: budget_group
型:   string (group label, 例: "daily", "flex", "reserve")
意味: 封筒のグループ分類。集計・表示順に使用。
場所: accounts.tsv

キー: spend_class
型:   enum ("fixed" | "variable")
意味: 支出の固定/変動分類。明示なければ prefix fallback + fixed=1 で推論。
場所: accounts.tsv

キー: kind
型:   enum ("envelope" | "opening" | "spent" | "unassigned")
意味: 予算口座の種類。envelope 以外は内部口座。
場所: accounts.tsv

キー: fixed
型:   bool ("1" | absent)
意味: spend_class 未指定時に fixed として扱うかの補助フラグ。
場所: accounts.tsv

キー: cashflow
型:   string (例: "fixed_obligation")
意味: plan.tsv の行が会計支出ではなく現金 outflow 予約であることを示す。
場所: plan.tsv meta
```

## 3. 新規追加キー（Phase 2 で定義）

### 3.1 POLICY_BUDGET_STYLE

```
キー: POLICY_BUDGET_STYLE
型:   enum ("envelope" | "none")
既定: "envelope"
意味: 封筒予算を使うかどうか。none の場合、envelope_view は実行されず、
      budget_group や HOUSEHOLD_GROUP_* も無視される。
      Sec 5 (Envelopes) は "unavailable/policy" を返す。
```

### 3.2 POLICY_RISK_STYLE

```
キー: POLICY_RISK_STYLE
型:   enum ("conservative" | "simple")
既定: "conservative"
意味: 日割り計算の保守性。
      conservative: 固定費 + fixed_obligation を先に reserve してから日割り。
      simple:       流動資産を単純に残日数で割る（fixed reserve なし）。
```

### 3.3 POLICY_INCOME_CADENCE

```
キー: POLICY_INCOME_CADENCE
型:   enum ("bimonthly" | "monthly" | "weekly" | "irregular")
既定: none（必須ではない）
意味: 収入の周期性。現在は計算に直接使われていないが、
      将来の予測・警告・表示切替に使用する予定。
      年金隔月支給は "bimonthly" に相当する。
```

## 4. バリデーションルール

### 4.1 既知値チェック

以下のキーは、定義された enum 値以外を reject する：

| キー | 許容値 |
|---|---|
| `POLICY_BUDGET_STYLE` | `envelope`, `none` |
| `POLICY_RISK_STYLE` | `conservative`, `simple` |
| `POLICY_INCOME_CADENCE` | `bimonthly`, `monthly`, `weekly`, `irregular` |

未知値が来た場合：**ERROR** で fail closed。デフォルト値に fallback しない。

### 4.2 必須キーチェック

```
POLICY_BUDGET_STYLE: 必須。欠損時は "envelope" を既定値とする。
POLICY_RISK_STYLE:   必須。欠損時は "conservative" を既定値とする。
POLICY_INCOME_CADENCE: 任意。欠損時は空文字。
```

### 4.3 整合性チェック

```
POLICY_BUDGET_STYLE=none かつ HOUSEHOLD_GROUP_* に値がある場合:
  → WARN: budget groups defined but budget style is none.
  計算には影響しないが、設定ミスの可能性を示す。

POLICY_BUDGET_STYLE=envelope かつ HOUSEHOLD_GROUP_LIFE が空の場合:
  → WARN: envelope style selected but no life groups defined.
  封筒計算は空で走るが、表示が不完全になる。
```

### 4.4 実装方針

バリデーションは `config.bqn` に追加する。`LoadConfig` が返す namespace に
validation 済みの値を載せる。

```text
config.bqn:
  LoadConfig → policy validation → validated config namespace
```

コード側は config の生の値ではなく、validated config の値を見る。

## 5. 対比 fixture 設計（Phase 3 向け）

### 5.1 moko-style fixture（現状維持）

```text
fixtures/household-moko/
  config.tsv:
    HOUSEHOLD_GROUP_LIFE=daily,flex
    HOUSEHOLD_GROUP_RESERVE=reserve
    HOUSEHOLD_GROUP_ORDER=daily,flex,reserve
    POLICY_BUDGET_STYLE=envelope
    POLICY_RISK_STYLE=conservative
    POLICY_INCOME_CADENCE=bimonthly
  cycle.tsv:
    mode=incomeAnchor
    income_account=income:年金
  accounts.tsv:
    (封筒口座に budget=*, budget_group=daily/flex/reserve, kind=envelope あり)
```

### 5.2 monthly-salary fixture（新規）

```text
fixtures/household-monthly-salary/
  config.tsv:
    POLICY_BUDGET_STYLE=none
    POLICY_RISK_STYLE=simple
    POLICY_INCOME_CADENCE=monthly
    # HOUSEHOLD_GROUP_* は未定義（budget style=none なので不要）
  cycle.tsv:
    mode=calendarMonth
  accounts.tsv:
    (封筒口座なし。budget_group メタデータなし)
  journal.tsv:
    (月給収入、カレンダー月の支出)
```

### 5.3 検証項目

| 項目 | 期待される結果 |
|---|---|
| accounting core (TBDS) | 両fixtureで同じ構造・同じ計算ロジックを使う |
| Trial Balance | 両fixtureで opening/movement/closing が正しい |
| household view | moko では envelope + conservative daily、monthly では simple daily |
| Sec 5 (Envelopes) | moko では表示、monthly では "unavailable/policy" |

## 6. Phase 2 完了条件

- [x] `POLICY_BUDGET_STYLE` キーを `config.bqn` で読み取り・検証
- [x] `POLICY_RISK_STYLE` キーを `config.bqn` で読み取り・検証
- [x] `POLICY_INCOME_CADENCE` キーを `config.bqn` で読み取り（必須ではない）
- [x] 整合性チェック（BUDGET_STYLE=none + HOUSEHOLD_GROUP_* 定義済み → WARN）
- [x] `config/default_config.tsv` に既定値を追加
- [x] `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md` の Phase 2 を更新
