# Actual Comparison Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

前サイクル同時点と比べて何が増減したか。

## View type

```text
period comparison (current vs previous cycle, same elapsed days)
```

## Review decisions (2026-06-26)

- Lane 列: 削除（分類より変化量が重要） ✓
- ソート: |diff| 降順 ✓
- diff=0 の行: 表示する（「変わらない」の確認のため） ✓
- stopped 行: 表示する ✓
- 全件表示 ✓

## Decision log

```text
review_state: adopted
human_decision: adopted 2026-06-26
notes: Lane列削除, |diff|降順, 全件表示(diff=0含む), stoppedも表示
```
