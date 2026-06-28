# エンジンの設計評価と発展の方向性

本ドキュメントは、現在の `bqn-ledger` エンジンの設計上の特徴と、今後想定され得る中長期的な発展のステップについて整理したメモである。

ここでは、直近の実装計画ではなく、エンジンをどう守り、どの方向なら無理なく育てられるかを扱う。

## 1. 現状の設計に対する評価

### 特徴と利点

* **コンパクトな実装**:
  計算コアは BQN で記述されており、少ないコード量で多くの計算を表現している。変更時の影響範囲を追いやすい一方、意味が圧縮されやすいため、fixture / report contract / docs が意味を開く役割を持つ。
* **一貫したデータ構造 (Canonical Daily Cube)**:
  取引・予定・予算配賦を `Day × Account × Layer` の3次元データ構造へ投影してからレポートを生成する。これにより、レポート間で数値の入口が散らばりにくい。
* **責務の分離**:
  BQN は読み取り専用の正本数値エンジンとして扱う。source TSV の書き込み、preview、diff、confirm、backup、atomic write は Go や shell など外側のモジュールに任せる。
* **設定駆動 (Context)**:
  勘定科目の役割 (`role=asset` など)、budget prefix、cycle policy などを `accounts.tsv` / `config.tsv` / `cycle.tsv` から読み込む。生活スタイルの変化は、できるだけコード修正ではなく source TSV / config TSV の変更で吸収する。

### 守るべき中心

```text
BQN = 秤
Go  = 手袋
```

BQN は重さを測る。Go は元データに触る手を安全にする。

したがって、Go 側に残高計算・封筒計算・cycle 計算を持ち込まない。BQN 側も source TSV を勝手に変更しない。

## 2. 今後の段階的な発展の方向性

現在の構成から、実用性や堅牢性を高めるための発展の道筋を三つに分ける。

### 段階 1：ローカルにおける安全な編集サイクルの確立

直近の本線は、ローカル環境で source TSV を壊さず扱える編集サイクルを作ることである。

ただし、複数ファイル更新をいきなり実装しない。段階をさらに分ける。

#### 段階 1a：read-only list / preview

* `plan list`
* `plan finish preview`
* TSV parser / writer の基礎
* empty field / comment / blank line / metadata の保持
* dry-run no mutation

この段階では source TSV を変更しない。

#### 段階 1b：single-file append

* `journal add` safe append
* `budget add` safe append
* stale check
* atomic write
* `.backup/` 作成
* post-write BQN lint

この段階でも、複数ファイルをまたぐ transaction は実装しない。

#### 段階 1c：multi-file apply

* `plan finish apply`
* `journal.tsv` と `plan.tsv` をまたぐ更新
* operation record
* recovery 手順
* failure injection tests
* idempotency key

この段階は、safe workflow / recovery / report contract が揃うまで実装しない。

### 段階 2：複数環境での利用と安全な同期

PC だけでなく、モバイル端末などからも記録・閲覧できるようにする拡張である。

ただし、最初から multi-writer にしない。

最初の候補は次の形にする。

```text
PC:
  source TSV の正本を持つ

mobile / other device:
  直接 source TSV を編集しない
  入力メモ / append request / draft event を作る

取り込み:
  PC側で preview
  BQN check
  Go safe append
```

この段階で扱う候補:

* portable capture
* lightweight view
* draft event / append request
* conflict detection
* sync import preview

「どこでも記録できること」と「どこからでも正本を書き換えること」は分けて扱う。

### 段階 3：研究枝としての推論・汎用化

宣言的ルール定義や Datalog 連携は、将来的な研究枝として扱う。

ここでの目的は、現在の canonical engine をすぐ汎用会計エンジンへ変形することではない。まずは BQN export / report contract を安定させ、その外側で検算・説明・相談を行う。

候補:

* BQN export を Datalog / Prolog / AI が読む
* 数値整合性とは別に、税制・申告・生活判断の論理検査を行う
* Plan / Actual / Residual を説明レイヤで解釈する
* Datalog 側は source-of-truth ではなく、検算・説明・相談レイヤに置く

当面は、Projection や Layer 契約そのものを設定ファイルで自由に定義する方向へ進まない。`Day × Account × Layer` の固定契約を守る。

## 3. やらないこと

この方向性メモでは、以下を直近の実装目標にしない。

* BQN の Canonical Daily Cube を Go で再実装する
* Go に残高計算・封筒計算・cycle resolver を持たせる
* `plan finish apply` を operation log / recovery なしで実装する
* `plan.tsv` から履行済み行を削除する
* `status=done` や `actual_date=...` を自動追記する
* source-of-truth を単一 `events.tsv` へ即座に統合する
* Projection / Layer ルールをすぐ完全設定駆動にする
* Datalog / AI を正本数値エンジンにする

## 4. 位置づけ

この文書は実装指示ではない。

直近の実装判断は、次の文書を優先する。

* `TODO.md`
* `docs/GO_EDITOR_NEXT_PLAN.md`
* `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md`
* `docs/GO_SOURCE_TSV_EDITOR_APPEND_ONLY_DECISIONS.md`
* `docs/SAFE_WORKFLOW_REDESIGN.md`

この文書は、それらをまたぐ長期的な見取り図として扱う。
