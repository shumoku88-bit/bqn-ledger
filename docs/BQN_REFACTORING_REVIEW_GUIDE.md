# BQN Refactoring Review Guide

Status: boundedなBQN refactorのためのproposed review gate

## 目的

このガイドは、BQN refactorを毎回同じ方法で確認するためのものです。code golfの規則ではなく、repository全体を一人の書き方へ統一するものでもありません。

目標は次です。

> 会計上の意味、ownership、diagnostics、provenance、fail-closed behaviorを保ちながら、データ変換をコード上でより直接見えるようにする。

`src/`、`src_edit/`、retained shared ownerと、そのfocused testにある小さなrefactorで使います。correctness変更とownership migrationは別sliceのまま保ちます。

## Hard gates

該当するgateが一つでも通らないrefactorは採用しません。

1. **Finite question**: 編集前に、一つのboundedな変換またはownership questionを宣言する。
2. **Meaning preservation**: 別のcorrectness sliceで明示的に許可しない限り、値、順序、diagnostics、provenance、exact arithmetic、rejection behaviorを変えない。
3. **Owner preservation**: 短縮のためにutility bag、forwarding wrapper、universal context、新しいhidden policy ownerを作らない。
4. **Evaluation preservation**: 選ばれていないbranch、formatter、parser、高価な計算をeagerに実行する形へ変えない。
5. **Edge evidence**: 該当するempty、nested、not-found、duplicate、boundary、malformed inputをcharacterizeする。
6. **Focused scope**: 実装とfocused testが一つのcoherent finite sliceに収まる。
7. **Full verification**: focused test、`tools/check.sh`、coverage、final patch reviewをcurrent `main`との統合状態で通す。

行数はevidenceでありgateではありません。contractを隠す短いコードは改善ではありません。

## Review lenses

該当するlensごとに `green`、`improve`、`blocked`、`not-applicable` を記録します。人物への評価ではなく、変更内容の具体的なevidenceを書きます。

### Marshall Lochbaum: array transformationを露出させる

確認すること:

- repeated scan、mutable accumulation、branch ladderを、一つのprimitiveまたはcoordinate transformationとして表せるか。
- input shape、中間coordinate、output shapeが見えるか。
- first-class functionを実行前に選択しているか。
- 選んだBQN primitiveが、その操作の直接ownerになっているか。

よいevidenceには、exact lookupの`index-of`、major-cell uniquenessの`Deduplicate`、classify/group key、mask、selection、aligned function arrayなどがあります。

diagnostic stepが反復して見えるという理由だけでstrict admissionを圧縮しません。

### Roger Hui: semantic edgeを証明する

確認すること:

- empty inputでは何が起きるか。
- not-found valueは何か。selection前に安全か。
- nested major cellが意図したequalityで比較されるか。
- rank、scalar対one-element list、ordering、duplicate semanticsを保っているか。
- accounting contractがexactnessを要求する場所で、演算と比較がexactか。

primitive置換は、edge semanticsがtestされるまで未完了です。

### John Scholes: declarationを読める形に保つ

確認すること:

- 各named functionが一つの目的を表しているか。
- admission、coordinate resolution、grouping、publicationなどの意味あるstageが残っているか。
- 消えたものはincidental temporaryか。それとも必要なdomain boundaryか。
- mutationの手順ではなく、resultの宣言として読めるか。

accountingまたはapplication上の意味を持つ名前は残し、そのnamed boundary内のkernelを短くします。

### Adám Brudzewsky: derivation pathを残す

確認すること:

- 将来のreaderが、procedural formからfinal idiomへ至る道筋を追えるか。
- 短いcommentがsyntaxの実況ではなく、primitiveの重要contractを説明しているか。
- focused testが代表的なcoordinateまたはselected indexを示しているか。
- PR bodyにbefore/after algorithmが記録されているか。

final codeはcompactで構いません。review evidenceには、そこへ到達した階段を残します。

### Aaron Hsu: whole-array dataflowを検討する

大きなpure kernelにだけ適用します。

確認すること:

- 各row、Account、date、cellごとに全Postingを繰り返しscanしていないか。
- coordinateまたはlaneを一度encodeし、group、classify、scatterできないか。
- itemごとのcontrol flowをaligned state arrayにできないか。
- 新しいdataflowがdeterministicでaudit可能か。

小さなadmission function、I/O boundary、editor safety orchestrationでは通常 `not-applicable` です。

### Kenneth Iverson: notationが構造を見せるか判定する

確認すること:

- 新しい式は、accountingまたはreporting questionの構造を以前より直接示しているか。
- incidental mechanicsを従属させながら、重要な意味を隠していないか。
- notationから有効なtestや追加の推論が導けるか。
- focused exampleまたは形式的な方法で検証しやすくなったか。

最終判断は「巧妙か」ではなく「問題が前より明瞭になったか」です。

### Arthur Whitney: extreme brevityをprobeとして使う

確認すること:

- procedural codeの内側に、もっと小さなcomputational kernelがないか。
- 何がessential contractで、何がscaffoldingか。
- 極端に短い形でも、ここではmaintainableかつdiagnostically completeか。

これはprobeでありacceptance criterionではありません。暗黙の前提へ依存する圧縮や、人間、test、将来の自動変更に必要なevidenceを消す圧縮はrejectします。

## Standard review sequence

### 1. Finite questionを宣言する

一文で書きます。

> Can `<current procedural form>` become `<array-native form>` while preserving `<named contracts>`?

### 2. Contractを固定する

変えてはいけない性質を列挙します。該当するordering、empty behavior、diagnostics、provenance、arithmetic、output bytes、evaluation behaviorを含めます。

### 3. Final expressionより先にarray modelを書く

```text
input cells / columns
→ coordinate, mask, classification, group, or selected function
→ output cells / columns
```

これを明確に書けないsliceは、まだ圧縮の準備ができていません。

### 4. Semantic edgeをcharacterizeする

該当するものへfocused evidenceを追加します。

- empty
- unknown / not found
- nested cell
- non-adjacent duplicate
- invalid rank or shape
- boundary index
- eager evaluation対conditional evaluation
- exact arithmetic failure

### 5. 最小のcoherent changeを実装する

新しいgeneric helperより、まずdirect primitiveを使います。複数のreal consumerが同じsemanticsを証明した後にだけshared ownerを抽出します。

### 6. Lens reviewを記録する

```markdown
## BQN refactor lenses

- Marshall: green — <visible array transformation>
- Hui: green — <edge semantics and tests>
- Scholes: green — <names and boundaries retained>
- Adám: green — <derivation/comment/test evidence>
- Aaron: not-applicable — <why>
- Iverson: green — <problem structure made clearer>
- Whitney: green — <compression considered without deleting contracts>
```

### 7. Decisionを出す

- **accept**: hard gateがすべて通り、notationが変換を以前より直接示す。
- **revise**: 意味は保たれているが、shape、naming、test、説明のいずれかが不明瞭。
- **reject**: contractを隠す、ownershipを広げる、correctnessとrefactorを混ぜる、未検証のBQN behaviorへ依存する。

## Pull request evidence template

```markdown
## Finite question

Can ...?

## Before

<procedural stages>

## Array model

<input> → <coordinate/mask/group/function> → <output>

## Change

- ...

## Preserved contracts

- ...

## Edge evidence

- empty: ...
- not found: ...
- nested / duplicate: ...
- evaluation order: ...

## BQN refactor lenses

- Marshall: ...
- Hui: ...
- Scholes: ...
- Adám: ...
- Aaron: ...
- Iverson: ...
- Whitney: ...

## Verification

- [ ] focused test
- [ ] full `tools/check.sh`
- [ ] coverage
- [ ] current-main integration
- [ ] final bounded patch review
```

## Current examples

| PR | Kernel | Primary lenses | Important evidence |
|---|---|---|---|
| #437 | catalog exact lookup | Marshall, Hui | index-ofのabsent bound。success branchだけをconditional execution |
| #438 | request surface support | Marshall, Scholes | surface coordinateとcatalog coordinateを再利用。diagnostic contractを維持 |
| #439 | renderer dispatch | Marshall, Hui, Adám | formatterを値として選択。subject/function role failureを記録して修正。17 routeをgolden test |
| #440 | MatrixResult axis uniqueness | Marshall, Hui, Iverson | native major-cell Deduplicate。emptyとnested non-adjacent duplicateのevidence |

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

よいBQN refactorは、ledgerのevidenceを削らずにcomputational crystalを澄ませます。
