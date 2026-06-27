# UNAVAILABLE_SENTINEL_CONTRACT

Status: canonical
Date: 2026-06-27

## 目的

`src_next` モジュール間で「計算不能・データ欠損・設定不足」を表現する sentinel 文字列の taxonomy を定義する。

## Sentinel 一覧

| sentinel | 意味 | 典型的な原因 |
|----------|------|-------------|
| `unavailable/no_policy` | ポリシー未設定 | `budget_style=none`、target 未定義 |
| `unavailable/no_cycle` | サイクル期間欠損 | `cycle.tsv` 不在、mode 未設定 |
| `unavailable/no_data` | データ不在 | サイクルは有効だが journal が空、または期間内に取引なし |

## 契約

1. **プレフィックス**: すべての sentinel は `"unavailable/"` で始まる。
2. **判定**: `IsUnavailable(s)` は `"unavailable/" StartsWith s` と等価。
3. **拡張**: 新しい sentinel を追加する場合は `src_next/unavailable.bqn` のコメントリストとこの文書の両方を更新する。
4. **非公開**: sentinel は machine-readable 出力に現れるが、人間向けレポートでは適切なラベル（「unknown」「利用不可」等）に変換される。

## 実装

正本定義: `src_next/unavailable.bqn`

```bqn
unav ← •Import "unavailable.bqn"
unav.IsUnavailable value   # 1 if value starts with "unavailable/"
unav.StartsWith            # general dyadic prefix-match
unav.noPolicy              # "unavailable/no_policy"
unav.noCycle               # "unavailable/no_cycle"
unav.noData                # "unavailable/no_data"
```

現在の利用モジュール:
- `src_next/envelope_computation.bqn` — 文字列リテラル + `IsUnavailable` / `StartsWith`
- `src_next/snapshot.bqn` — 文字列リテラル + `IsUnavailable`

## 非目標

- 人間向け表示ラベルの提供（それは `format.bqn` または各モジュールの責務）
- エラーコード体系（sentinel は「理由」の識別であり、エラーハンドリング機構ではない）
- 自動リカバリ（sentinel は観測値。リカバリは呼び出し側の判断）
