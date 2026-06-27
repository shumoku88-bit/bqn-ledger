# Trial Balance Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

TBDS の opening / movement / closing と zero-sum は成立するか。

## View type

```text
accounting integrity check
```

全 account の Opening → Debit/Credit movement → Closing を表示し、借方=貸方（zero-sum）を検証する。
レポート表示の正しさを判断するための基準点。

## Review decisions (2026-06-26)

- 必須画面 ✓
- Zero-sum check が FAIL なら即座にわかる ✓

## Decision log

```text
review_state: adopted
human_decision: adopted 2026-06-26
notes: 会計整合性の基準点として必須
```
