# BQN Refactoring Review Guide

Status: boundedなBQN refactorのためのproposed review gate

## 目的

このガイドは、BQN refactorを毎回同じ方法で確認するためのものです。code golfの規則ではなく、repository全体を一つの書き方へ統一するものでもありません。

目標は次です。

> 会計上の意味、ownership、diagnostics、provenance、fail-closed behaviorを保ちながら、データ変換をコード上でより直接見えるようにする。

`src/`、`src_edit/`、retained shared ownerと、そのfocused testにある小さなrefactorで使います。correctness変更とownership migrationは別sliceのまま保ちます。

## Exploration laneとの関係

このガイドはproduction採用のgateです。BQNの発想、primitive、modifier、alternate representation、tacit form、新しいcapabilityを発見する範囲を狭めるためのものではありません。

候補の発見と比較には`BQN_EXPLORATION_PLAYBOOK.md`を使い、蓄積済みの問いと再訪条件は`BQN_EXPLORATION_CATALOG.md`から読みます。production gateをまだ通れない案は捨てず、次のどれかへ戻します。

- `experiments/bqn/`のanalysis-only probe;
- 個人用BQN書籍の実験;
- catalogに理由と再訪条件を残すparked record;
- catalogに別correctness decisionとして残すnew capability。

探索では複数の大胆な表現を比較して構いません。productionへの採用だけを、一つのcoherent finite sliceに絞ります。

## 日常の5問

通常のbounded refactorでは、まずこの5問だけを確認します。

1. **何を配列変換として見せたいか。**

   ```text
   input cells / columns
   → coordinate, mask, classification, group, or selected function
   → output cells / columns
   ```

2. **何を絶対に変えないか。**

   該当するordering、diagnostics、provenance、exact arithmetic、output bytes、rejection behavior、evaluation behaviorを明記します。

3. **境界でも同じ意味か。**

   該当するempty、not-found、nested cell、duplicate、boundary index、invalid shape、conditional evaluationをfocused testで固定します。

4. **必要な名前とownership boundaryを消していないか。**

   domain上のstageやownerは残し、その内側にあるincidentalなscan、mutation、branch ladderだけを短くします。

5. **前より問題の構造が見えるか。**

   行数ではなく、入力、変換、出力、失敗条件が前より直接読めるかで `accept / revise / reject` を決めます。

5問で判断できないときだけ、後半のReview lensesを使います。

## Hard gates

該当するgateが一つでも通らないrefactorはproductionへ採用しません。価値ある表現はexploration laneへ戻して観察を続けられます。

1. **Finite question**: 編集前に、一つのboundedな変換またはownership questionを宣言する。
2. **Meaning preservation**: 別のcorrectness sliceで明示的に許可しない限り、値、順序、diagnostics、provenance、exact arithmetic、rejection behaviorを変えない。
3. **Owner preservation**: 短縮のためにutility bag、forwarding wrapper、universal context、新しいhidden policy ownerを作らない。
4. **Evaluation preservation**: 選ばれていないbranch、formatter、parser、高価な計算をeagerに実行する形へ変えない。
5. **Edge evidence**: 該当するempty、nested、not-found、duplicate、boundary、malformed inputをcharacterizeする。
6. **Focused scope**: 実装とfocused testが一つのcoherent finite sliceに収まる。
7. **Full verification**: focused test、`tools/check.sh`、coverage、final patch reviewをcurrent `main`との統合状態で通す。

行数はevidenceでありgateではありません。contractを隠す短いコードは改善ではありません。

## Review lenses

以下は日常の必須記入欄ではなく、5問だけでは判断が難しいときの参照です。必要なlensだけを使い、具体的な変更内容とevidenceを書きます。

### 配列変換: array transformationを露出させる

確認すること:

- repeated scan、mutable accumulation、branch ladderを、一つのprimitiveまたはcoordinate transformationとして表せるか。
- input shape、中間coordinate、output shapeが見えるか。
- first-class functionを実行前に選択しているか。
- 選んだBQN primitiveが、その操作の直接ownerになっているか。

よいevidenceには、exact lookupの`index-of`、major-cell uniquenessの`Deduplicate`、classify/group key、mask、selection、aligned function arrayなどがあります。

diagnostic stepが反復して見えるという理由だけでstrict admissionを圧縮しません。

### 境界意味論: semantic edgeを証明する

確認すること:

- empty inputでは何が起きるか。
- not-found valueは何か。selection前に安全か。
- nested major cellが意図したequalityで比較されるか。
- rank、scalar対one-element list、ordering、duplicate semanticsを保っているか。
- accounting contractがexactnessを要求する場所で、演算と比較がexactか。

primitive置換は、edge semanticsがtestされるまで未完了です。

### 読める境界: declarationを読める形に保つ

確認すること:

- 各named functionが一つの目的を表しているか。
- admission、coordinate resolution、grouping、publicationなどの意味あるstageが残っているか。
- 消えたものはincidental temporaryか。それとも必要なdomain boundaryか。
- mutationの手順ではなく、resultの宣言として読めるか。

accountingまたはapplication上の意味を持つ名前は残し、そのnamed boundary内のkernelを短くします。

### 導出経路: derivation pathを残す

確認すること:

- 将来のreaderが、procedural formからfinal idiomへ至る道筋を追えるか。
- 短いcommentがsyntaxの実況ではなく、primitiveの重要contractを説明しているか。
- focused testが代表的なcoordinateまたはselected indexを示しているか。
- PR bodyにbefore/after algorithmが記録されているか。

final codeはcompactで構いません。review evidenceには、そこへ到達した階段を残します。

### 全体配列データフロー: whole-array dataflowを検討する

大きなpure kernelにだけ適用します。

確認すること:

- 各row、Account、date、cellごとに全Postingを繰り返しscanしていないか。
- coordinateまたはlaneを一度encodeし、group、classify、scatterできないか。
- itemごとのcontrol flowをaligned state arrayにできないか。
- 新しいdataflowがdeterministicでaudit可能か。

小さなadmission function、I/O boundary、editor safety orchestrationでは通常使いません。

### 記法の明瞭さ: notationが構造を見せるか判定する

確認すること:

- 新しい式は、accountingまたはreporting questionの構造を以前より直接示しているか。
- incidental mechanicsを従属させながら、重要な意味を隠していないか。
- notationから有効なtestや追加の推論が導けるか。
- focused exampleまたは形式的な方法で検証しやすくなったか。

最終判断は「巧妙か」ではなく「問題が前より明瞭になったか」です。

### 圧縮の限界: extreme brevityをprobeとして使う

確認すること:

- procedural codeの内側に、もっと小さなcomputational kernelがないか。
- 何がessential contractで、何がscaffoldingか。
- 極端に短い形でも、ここではmaintainableかつdiagnostically completeか。

これはprobeでありacceptance criterionではありません。暗黙の前提へ依存する圧縮や、人間、test、将来の自動変更に必要なevidenceを消す圧縮はrejectします。rejectされた表現も、隠れた前提を示すexperimentとして保存できます。

## 作業順序

1. `BQN_EXPLORATION_PLAYBOOK.md`のopportunity scanと`BQN_EXPLORATION_CATALOG.md`の既存card確認から、primitive、cell/rank/axis、別representation、whole-array form、新capabilityを観察する。
2. 探索では必要なだけ複数案を比較し、今回productionへ持ち込むfinite questionだけを一文で宣言する。
3. 変えてはいけないcontractを書く。
4. final expressionより先にarray modelを書く。
5. 該当するsemantic edgeをfocused testへ追加する。
6. 最小のcoherent changeを実装する。
7. 5問でreviewし、必要な場合だけ詳細lensを参照する。
8. current `main`との統合状態で検証し、`accept / revise / reject / return-to-probe`を出す。未採用だが再利用価値のある観察はcatalogへ戻す。

新しいgeneric helperより、まずdirect primitiveを使います。複数のreal consumerが同じsemanticsを証明した後にだけshared ownerを抽出します。

## Current examples

| PR | Kernel | 主に使う観点 | Important evidence |
|---|---|---|---|
| #437 | catalog exact lookup | 配列変換、境界意味論 | index-ofのabsent bound。success branchだけをconditional execution |
| #438 | request surface support | 配列変換、読める境界 | surface coordinateとcatalog coordinateを再利用。diagnostic contractを維持 |
| #439 | renderer dispatch | 配列変換、境界意味論、導出経路 | formatterを値として選択。subject/function role failureを記録して修正。17 routeをgolden test |
| #440 | MatrixResult axis uniqueness | 配列変換、境界意味論、記法の明瞭さ | native major-cell Deduplicate。emptyとnested non-adjacent duplicateのevidence |

これらは永久的なpreferred syntaxではなく、review methodの実例です。

## Repository-specific stop signs

このガイドを次の変更の根拠にしません。

- correctness decisionなしでdiagnosticsを削除または並べ替える
- strict source admissionを弱める
- multi-postingまたはprovenance evidenceをflattenする
- exact arithmeticを便利なnumeric arithmeticへ置き換える
- universal report、editor、source、accounting recordを追加する
- compatibility alias、forwarding module、fallback parser、duplicate routeを追加する
- editor ownership migrationとaccounting algorithm変更を同じsliceへ入れる
- separate explicit authorizationなしでprivate household sourceを編集する

よいBQN refactorは、ledgerのevidenceを削らずにcomputational crystalを澄ませます。探索laneは、そのcrystalにならなかった鉱石も観察可能な形で残します。