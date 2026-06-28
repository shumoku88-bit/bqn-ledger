# Cube Evolution Policy

作成日: 2026-06-16

この文書は、`bqn-ledger` における Canonical Daily Cube の今後の扱いを整理するための方針メモである。

現状、`bqn-ledger` には `Day × Account × Layer` の3次元キューブが実装されている。

ただし、この Cube を唯一の真理や正データとして扱うのではなく、event log から生成される会計日次 projection として扱う。

---

## 1. 基本方針

```text
正データ:
  event log TSV

根の考え方:
  event-first

計算用projection:
  Day × Account × Layer cube

研究用中間層:
  Tx × Account × Layer vector

説明用:
  rows / journal view

派生観察:
  graph / signal / burn rate
```

この方針では、Cube を完成形として神棚に置きすぎない。

Cube は強い計算用の結晶である。

しかし、生活イベント、メモ、説明可能性、監査可能性、あとから読み返したときの意味は、行ベースの event log や journal view に残る。

---

## 2. Cube の位置づけ

Canonical Daily Cube は、正データではない。

正データは、引き続き人間が直接読める・書ける TSV とする。

Cube は、次のための materialized view である。

- 日付別の残高計算
- `as_of` snapshot
- layer 別の比較
- 封筒残高の集計
- trend / burn rate / safety speed などの派生レポート
- BQN による配列処理

つまり、Cube は次の位置にある。

```text
event log TSV
  -> Event IR
  -> Projection IR
  -> Day × Account × Layer cube
  -> reports
```

Cube は強いが、唯一の時間モデルではない。

`as_of`、cycle、月、週、cashflow due、plan 消化、生活イベントの意味などは、Cube とは別の観察境界や projection として扱う余地を残す。

---

## 3. Event-first を根にする

今後の基本姿勢は、Cube-first ではなく Event-first とする。

```text
Event:
  起きたこと、予定したこと、配賦したこと

Projection:
  それをどの構造へ写すか

Cube:
  日付 × 科目 × レイヤーに射影した計算用ビュー

Report:
  生活に戻すための表示・観察
```

この分離により、次の両方を守る。

- TSV の生活記録としての読みやすさ
- BQN の配列処理としての強さ

Cube にすべてを押し込まず、必要に応じて row view、graph view、signal view などを派生させる。

---

## 4. Tx × Account × Layer vector の研究余地

現在の実装では、Projection IR から `Day × Account × Layer` へ materialize している。

今後の研究として、その前段に `Tx × Account × Layer` を明示する選択肢がある。

```text
Event IR
  -> Projection IR
  -> Tx × Account × Layer vector
  -> Day × Account × Layer cube
```

この中間層を持つと、次の検査がしやすくなる。

- 1取引が合計0ベクトルになっているか
- 複数postingを自然に扱えるか
- ledger形式を疎ベクトル表現として再解釈できるか
- 取引単位の不変量を検査できるか
- Day へ畳み込む前の構造を観察できるか

ただし、これは現時点では研究用の中間層であり、ただちに本番の正データ形式にする必要はない。

---

## 5. Row view を残す理由

すべてのレポートを Cube だけから生成する方向は、配列処理としては美しい。

しかし、家計簿には数値だけではなく、生活イベントとしての意味がある。

そのため、次の用途では row view / journal view を残す。

- memo を含む説明
- from / to の文脈
- 実際の入力確認
- cycle や YTD の説明的な集計
- ledger export
- AI や人間による監査
- あとから読み返したときの生活記録

Cube は計算に強い。

Rows は説明に強い。

この2つを対立させず、役割分担する。

---

## 6. Layer 3 の意味整理

現状の Cube は `Day × 256 × 4` の形を持つ。

想定レイヤーは次の通りである。

```text
0: actual
1: plan
2: budget
3: forecast
```

ただし、実装上の Layer 3 の用途が docs 上の `forecast` と完全に一致しているかは、今後確認・整理が必要である。

選択肢は次の通り。

```text
A. Layer 3 を本当に forecast に戻す
B. Layer 3 を diagnostic / budget_alloc_sum 的な層として再定義する
C. Layer 3 は forecast 用に予約し、diagnostic は別の派生viewへ出す
```

現時点では、C が最も安全な候補である。

Layer の意味を濁らせず、forecast は将来の予測層として残す。

検査用・診断用の値は、Cube 本体の Layer としてではなく、必要に応じて別 view として生成する。

---

## 7. 旧2層互換 API の扱い

旧構造である `tx_updates : T × 256 × 2` や `day_balances : Day × 256 × 2` は、互換性のために残っている。

今後の選択肢は次の通り。

```text
A. しばらく残す
B. deprecated と明記する
C. export / check / report が Cube 対応へ移ったら削除する
```

推奨方針は、B から C へ進むことである。

いきなり削除せず、まず互換用であることを明示する。

その後、既存の export tool や check tool が Cube 対応へ移った段階で削除を検討する。

---

## 8. 今後の進め方

現実的な順序は次の通り。

```text
1. Layer 3 の意味を整理する
2. 旧2層互換 Build / BuildDays を deprecated 扱いにする
3. Event IR / Projection IR / Cube の責務を docs に明記する
4. Tx × Account × Layer を研究用に小さく試す
5. レポートを少しずつ Cube 由来へ寄せる
```

ただし、Cube だけに純化することを目的にしない。

必要な場合は、row view や event log から直接作るレポートも残してよい。

重要なのは、どの表現がどの問いに答えるためのものかを明確にすることである。

---

## 9. この方針のまとめ

```text
正データは人間寄り
内部 projection は event-first
計算用 view は Cube 寄り
研究用中間層は vector 寄り
説明用 view は row 寄り
観察用 view は graph / signal 寄り
```

この設計では、Cube は中心的な計算道具である。

しかし、Cube は唯一の真理ではない。

`bqn-ledger` の大きな構造は、次のように捉える。

```text
event log
  + projection
  + invariant
  + cube
  + report
```

この方針により、BQN の配列処理の美しさと、TSV の生活記録としての読みやすさを両方残す。
