# Canonical Daily Cube 監査メモ

Status: current purpose-specific view contract
Owner: report / projection
Canonical: yes for the `Day × AccountKey × Layer` view, not for every future projection
Exit: revise when this view contract or its production consumers change
Updated: 2026-07-25

## 概要

現行レポートの主要 materialized view の一つは、**Canonical Daily Cube**（`Day × AccountKey × Layer`）です。
checked Posting IR を `src_next/cube.bqn` が選択periodへ admissionし、dense cube に materializeします。

```text
checked posting facts
  -> selected-period admission
  -> Day / AccountKey / Layer coordinates
  -> signed exact delta
  -> exact accumulation
  -> dense Day × AccountKey × Layer
  -> current report consumers and validation
```

Canonical Daily Cubeは正データでも唯一の最終表現でもありません。TBDS、direct posting-evidence calculations、selected-domain viewsと並ぶ、日次座標replayに適した標準compositionです。Source truthはhuman-readable native Journalとcompanion/configuration TSVに残ります。

Cubeの`Day`はEventを配置したcoordinate axisです。`as_of`はCubeの軸ではなく、どの時点からsnapshotを観察するかを表す外側のobservation timeです。cycle、月、週は`Day`軸上の区間viewです。詳細は`docs/TIME_AS_AXIS.md`を参照してください。

## 現在のcomposition

### 軸

この**特定のCanonical view**の軸と順序は固定です。

- **Day（第0軸）**: 選択period内の連続日付。`cycle.bqn`がdomain sizeを供給する。
- **AccountKey（第1軸）**: `accounts.tsv`から解決される`(Account, Currency)`。異なるcommodityの残高を同じcellへ入れない。
- **Layer（第2軸）**: `actual / plan / budget / forecast`の4層。

店舗、party、project、trip、lifecycleなどをこのCubeへ自動追加しません。ただし、それらを別のpurpose-specific sparse projectionやdense viewのcoordinateとして使うことまで禁止する契約ではありません。

### レイヤー

| Index | Name | Source | 意味 |
|---|---|---|---|
| 0 | `actual` | configured native Journal | 現実の資産・収入・支出の動き。 |
| 1 | `plan` | `plan.tsv` | 予定された将来の動き。 |
| 2 | `budget` | `budget_alloc.tsv` + admitted Journal projection | 配賦と消費の動き。 |
| 3 | `forecast` | current reserved shape | 予測用に予約された層。 |

Layerは同じdaily coordinate上に並びますが、確定度や責務が同じという意味ではありません。

## 実装境界

- **Posting facts**: Journal routeとnon-Actual routeが、source identity、date、account coordinate、layer、exact delta、statusなどを持つchecked rowsを作る。
- **Period orchestration**: `src_next/context.bqn`の`BuildPeriodView`が同じledger-wide rowsからCubeとTBDSを構成する。
- **View admission**: `cube.PartitionRows`がstatus、day bounds、AccountKey bounds、Layer boundsを検査する。out-of-periodはこのviewからの除外であり、source-level semantic rejectionと同義ではない。
- **Dense materialization**: `cube.Materialize ⟨rows, day_count, ak_count⟩`がvalid rowsだけを`day_count × ak_count × 4`へ配置する。
- **Evidence**: valid/skipped rowsとdiagnosticsはdense cellとは別に残る。dense cell単体はcontributor posting identityを所有しない。
- **Validation**: current result contractはlayer totals、per-account totals、expense totals、conservation comparisonsなどのcompatibility fieldsも返す。

## Exact sparse grouping experiment

`src_next/exact_sparse_grouping.bqn`は、明示されたexact keysとalready-admitted exact valuesをfirst-occurrence orderでgroupingするI/O-free experimentです。

`tests/test_src_next_exact_sparse_grouping.bqn`は次を観察します。

- 空入力;
- duplicate keyの正確な加算;
- 負値;
- input totalとgrouped totalの保存;
- 決定的なfirst-occurrence順;
- contributor indexを数値groupとは別sidecarとして保持できること;
- current `cube.Materialize`のdense numeric payloadを同じgrouped factsから再構成できること;
- TBDS風のlayer/account/side movementにも同じprimitiveを再利用できること;
- commodityをpartitionまたはkeyへ含めれば、異なるdomainを直接加算しないこと。

このexperimentはまだ`cube.Materialize`のproduction accumulationを置き換えていません。Current result contractにはdense array以外のevidence、diagnostics、report-like compatibility fieldsが含まれるため、数値payload parityだけで移行完了とはみなしません。

## 多通貨との関係

Canonical Daily CubeへCurrency軸を追加することが多通貨対応の前提ではありません。

- `AccountKey = (Account, Currency)`がaccount balanceのcommodity separationを保つ。
- `journal_complete_source_admission.bqn`はmulti-currency Journal container全体をadmitするが、各ordinary transactionはsingle-domainでbalanceする。
- `journal_currency_proof_carrier_stage2a.bqn`はsource coefficient、commodity、domain、calculation scaleをuntyped deltaへ落とさず保持する。
- `selected_domain_context.bqn`は一つのselected currencyを選び、そのdomain内でexact scaleをそろえてからcurrent `BuildPeriodView`へ渡す。
- exact sparse grouping kernel自体はcurrency-awareではない。measure ownerが先にcompatible arithmetic domainを決め、domainをpartitionまたはkeyとして保持する。
- valuation、FX gain/loss、tax、rate derivationはsource quantity groupingとは別のreport-specific concernである。

## TBDSとの関係

TBDSは同じchecked Posting IRから、pre-period rowsをopening evidenceとして使い、selected periodのdebit/credit movementとclosing stateを作ります。Cubeのout-of-period admissionとTBDSのperiod splitは意味が異なるため、共通grouping primitiveを使えても共通admission policyへ潰してはいけません。詳細は`docs/TBDS_CONTRACT.md`を参照してください。

## 現在のinvariants

- rejected factsはordinary numeric outputへ入らない。
- PlanはActual balanceへ影響しない。
- 異なるcommodityは直接加算しない。
- exact amount evidenceはauthorized domain内でexactにgroupされる。
- sparse grouped totalとadmitted input totalは一致する。
- dense outputを作る場合、対応するsparse grouped valuesと一致する。
- source transaction / posting evidenceはdense numeric resultの外側から到達可能である。
- `tests/test_src_next_cube.bqn`と`checks/check-src-next-*`はcurrent Canonical result contractを継続検査する。
