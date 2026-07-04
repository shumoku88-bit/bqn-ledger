# Golden Assertion Ownership Plan — 2026-07-04

Status: completed / review result `resolved`

## 1. Purpose

この文書は、AI Working Feedback Classification Review の A5 を最初の full process trial として扱った planning / execution / review record です。

Adopted classification item:

- `A5 Golden + exact grep 重複`
- Primary: `D Verification / Test`
- Secondary: `C Architecture / Design`
- Root cause hypothesis: 同一期待値を複数 test surface が所有している
- Systemic direction: assertion ownership policy

Related process:

- `docs/AI_WORKING_FEEDBACK_PROCESS.md`
- `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md`
- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`

## 2. Original evidence

Primary target:

- `checks/check-src-next-envelope-computation.sh`
- `fixtures/src-next-envelope-computation/expected/src_next_summary.txt`

Observed flow before implementation:

1. `tools/report-next-summary` の出力から envelope summary を抽出する。
2. `diff -u "$expected" "$actual_summary"` で golden file と exact comparison する。
3. その直後に `grep -q` で同じ exact key/value lines を再検証する。

重複対象には、次のような exact values が含まれていました。

- allocated / actual_spent / remaining
- unassigned values / status
- funding base / backing status
- execution planned sentinel/status fields
- source/provenance rows

## 3. Ownership decision

今回の slice では次を採用しました。

### Golden file owns

- exact machine-summary key/value
- exact row ordering
- exact source/provenance rows
- fixture snapshot に属する exact status/sentinel values

### Shell check owns

- command success / file existence
- forbidden field absence
- invariant-style negative checks
- exclusion boundaries
- human report assertions not covered by machine-summary golden

Core rule:

> Golden と完全に同じ exact machine-summary expectation を shell `grep -q` が再所有しない。

## 4. Scope

Implementation scope:

- `checks/check-src-next-envelope-computation.sh`

Reference-only scope:

- `fixtures/src-next-envelope-computation/expected/src_next_summary.txt`

## 5. Non-goals preserved

今回の implementation では次を行いませんでした。

- 全 repository の golden/check cleanup
- 全 `grep` assertion の棚卸し
- test framework の新設
- check scaffolder の作成
- generic golden framework の再設計
- BQN calculation semantics の変更
- envelope calculation semantics の変更
- human report contract の再設計
- config semantics の変更
- source TSV の変更
- expected golden values の変更
- A4 / 22 / 20 など他 classification item の同時実装

## 6. Implementation result

Implemented by:

- PR #40 `test: remove duplicate assertions in envelope-computation check`
- merged commit: `003373040804b9844dc50a07d30353b82550faf7`

Diff scope:

- changed files: 1
- additions: 1
- deletions: 26

Result:

- `diff -u "$expected" "$actual_summary"` を exact machine-summary values の主所有者として維持した。
- golden file と完全重複していた exact `grep -q` assertions を削除した。
- unknown `envelope_role` leakage prevention を維持した。
- later-work field leakage prevention を維持した。
- human report assertions を維持した。
- BQN / source TSV / config semantics / unrelated checks は変更しなかった。

## 7. Verification result

PR #40 に記録された結果:

- `bash checks/check-src-next-envelope-computation.sh` -> PASS
- `bash tools/check.sh` -> PASS

したがって、targeted check と full test suite の両方で regression は観測されませんでした。

## 8. Review / Learning

Review result:

- `resolved`

### 8.1 Root-cause hypothesis

Supported.

Exact expected values の ownership が golden file と shell assertions に分散していたため、期待値変更時に複数箇所の同期が必要でした。

今回、duplicate exact assertions を削除し、machine-summary exact values の主所有者を golden diff に寄せました。

### 8.2 Friction reduction

Observed improvement:

- golden expectation 更新時に、同じ exact values を shell `grep -q` へ追随させる必要が減った。
- 同じ意味の二重正本が減った。
- 新しい helper / framework / scaffolder を増やさずに改善できた。
- test semantics や accounting semantics を広げず、小さい差分で完了した。

### 8.3 Boundary preservation

The cleanup did not collapse all checks into the golden file.

Preserved responsibilities include:

- unknown role leakage negative boundary
- later-work field leakage prevention
- human output assertions

これは「`grep` を減らす」ではなく「owner を決める」という original plan の目的に合致します。

### 8.4 New small observation

PR #40 の追加コメント:

```text
Semantic boundary checks for the Stage 4a prototype are now delegated to expected/src_next_summary.txt.
```

は、実際の責務より少し広く読めます。

理由:

- exact machine-summary assertions は golden へ委譲された。
- しかし semantic / negative boundary checks の一部は shell に残っている。

より正確な表現候補:

```text
Exact machine-summary values are verified by the golden diff above.
```

Decision:

- A5 を reopen しない。
- この wording issue 単独では即修正 PR を要求しない。
- 同種の ownership wording drift が再発する場合は Intake 候補とする。

## 9. Process trial result

この A5 slice で、最初の full loop が完了しました。

```text
Intake
  -> Classification
  -> Planning
  -> Execution
  -> Verification
  -> Merge
  -> Review / Learning
```

Process-level result:

- classification item をそのまま backlog として実装しなかった。
- A5 だけを選んだ。
- implementation 前に ownership hypothesis を置いた。
- small diff へ落とした。
- targeted / full verification を記録した。
- merge 後に learning を plan へ戻した。

この trial では、AI efficiency 改善の成果が新しい tool 追加ではなく、26 行の重複 assertion 削除として現れました。

## 10. Final decision

A5 scope is complete.

Result:

- `resolved`

Next action:

> A5 から次の item を自動選択しない。必要なら classification review へ戻り、次の planning item を改めて選ぶ。

このファイルは今後、completed historical record として読む。
