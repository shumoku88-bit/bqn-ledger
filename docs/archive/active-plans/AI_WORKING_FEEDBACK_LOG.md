# AI Working Feedback Log

Status: active intake log
Date: 2026-06-28

この文書は、pit（AI作業相棒）が実作業中に気づいた **作業品質・トークン効率・デバッグ効率・安全性** に関する意見を一時的に集める intake log です。

Process:

- `docs/AI_WORKING_FEEDBACK_PROCESS.md`

重要:

- **Feedback entry is not an implementation request.**
- このログは実装バックログではありません。
- ここへ記録された `Idea` を、AI が勝手に実装してはいけません。
- 根本原因の仕分けは classification review で行います。
- 実装は classification 後に作られた approved plan からのみ開始します。

## 目的

- 作業のたびに出た小さな改善案を失わない。
- ある程度溜まったら、人間がレビューして次のどれかに振り分ける。
  - すぐ AGENTS.md / docs / check に反映する作業ルール
  - devtools / lint / helper script として実装する候補
  - 既存ツール（rtk / sqz / query / bqn-dump 等）の改善候補
  - 採用しない、または後回しにする案
- 過去の大きな提案集である [DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md](../completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md) を、今後の実作業から更新・発展させる材料にする。

## pit への記入ルール

作業後、改善余地に気づいた時だけ追記する。毎回必須ではない。

- 長文にしない。1件あたり数行でよい。
- 具体的な「困った場面」と「改善案」を分ける。
- 実データ TSV の内容は書かない。
- すぐ実装しない。ここはまず収集場所。
- 既にある devtools で解決できる場合は、そのツール名を書く。
- Intake 時点では 5層分類を無理に確定しない。分類は review stage で行う。

## 記入テンプレート

```md
### YYYY-MM-DD: short title

- Context: 何の作業中に起きたか
- Friction: 何にトークン/時間/注意を使ったか
- Idea: どう改善できそうか
- Candidate type: rule / docs / check / devtool / existing-tool-improvement / no-action
- Related tool/doc: 任意
```

## Review policy

溜まってきたら、人間がまとめてレビューする。

現行の review process は `docs/AI_WORKING_FEEDBACK_PROCESS.md` を正とする。
分類 snapshot は原則として次へ置く。

```text
docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-YYYY-MM-DD.md
```

レビュー時の判断軸:

1. 正データ保護や fail-closed に効くか
2. AI の探索トークンを減らすか
3. デバッグ往復を減らすか
4. 既存 devtools で代替できるか
5. ツール化するほど頻出か
6. tool / coding / architecture / verification / workflow のどの層が主因か
7. 局所修正より先に、根本原因を減らせないか

分類結果はそのまま実装バックログにしない。
採用候補は Planning stage で選び、approved plan にしたものだけを実装する。

完了・採用済みになったまとまりは、後で completed plan へ退避する。

## Entries

<!-- New feedback entries go below. -->

### 2026-07-11: Contract-validity-first audit classification

- Context: Currency Stage 2 B2 post-implementation claim-to-evidence audit.
- Friction: A handcrafted `state=ok / currency=USD` namespace was initially classified as a material runtime mismatch before confirming that the B1 constructor cannot produce it. Separately, the normalized exact-range test initially assumed a generic numeric boundary rather than probing the current parser boundary.
- Idea: In focused runtime audits, classify each examined input first as source-derived / contract-valid constructed / forged defensive input before assigning materiality. For runtime exactness boundaries, run a few small owner-module probes before selecting test constants. During actual-diff review, combine working-tree, staged, and `base...HEAD` views according to state so uncommitted corrections are not omitted.
- Candidate type: rule / docs
- Related tool/doc: `docs/archive/audits/`, `src_next/exact_decimal.bqn`, `AGENTS.md`, `rtk git diff`

### 2026-07-09: Stage 2 merge left TODO routing stale

- Context: PR #132 merged the Stage 2 minimal domain-proof runtime slice.
- Friction: mandatory L1 `TODO.md` routing still pointed new agents at already-completed runtime implementation work, which adds reread / rediscovery churn, duplicate-work risk, and token waste.
- Idea: when an Active TODO slice completes, synchronize L1 routing in the same change; if that is not possible, leave an explicit routing follow-up instead of silently leaving completed work Active.
- Candidate type: rule / docs / workflow
- Related tool/doc: `TODO.md`, `AGENTS.md`

### 2026-06-28: docs archive move needs link validation

- Context: docs整理後のリンク修正作業
- Friction: archive 移動後、active docs だけでなく archive 内の相対リンク切れも手動確認が必要だった
- Idea: local Markdown link checker を check/devtool 化し、active docs は fail、archive は policy に応じて warn/fail に分ける
- Candidate type: check / devtool
- Related tool/doc: `tools/check.sh`, `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`

### 2026-06-30: BQN precedence & function role gotchas

- Context: BQNエディタにおける plan edit / journal reverse 実装およびデバッグ
- Friction: 
  - BQNの右結合的な関数適用規則により `sys.DefaultJournalFile @ ∾ ...` が右側全体を引数として飲み込んでしまい、メタデータ出力が消えた。
  - `𝕊/𝕩/𝕨` を含まない `{ ... }` ブロックが即時評価されるため、`⍟`（条件適用）によるガードが機能せず無条件に変数が書き換わった。
  - 小文字の変数名に代入した関数（例: `f ← { ... }`）は構文上「主語（値）」扱いになるため、`f 1` などで "Double subjects" 構文エラーになり、大文字 `F` で始める必要があった。
- Idea: AIがBQNを編集・デバッグする際、これらの特有のハマりどころ（Gotchas）を `AGENTS.md` や開発者ガイドラインにルールとして明文化する。
- Candidate type: rule / docs
- Related tool/doc: `AGENTS.md`, `docs/CONVENTIONS.md`

### 2026-07-04: BQN catch (⎊) variable scope and partial config gotchas

- Context: envelopes JSON export implementation and no-cycle fallback validation
- Friction:
  - Inside `json.IsString` catch block `{ 2 = •Type (⊑ (1 ↑ val)) } ⎊ { 0 } val`, using outer-scoped `val` inside the left operand prevented `⎊` from catching the "Fill element needed" crash when `val` was a generic empty list `⟨⟩`.
  - When creating test fixtures, writing a partial `config.tsv` overrides the default configurations without merging, causing missing key errors (e.g. `HOUSEHOLD_GROUP_LIFE` missing).
  - Updating a golden summary file caused test failures because the check script contained duplicate static `grep` assertions for the exact same values.
- Idea:
  - Document that BQN catch `⎊` left operand must operate strictly on its argument `𝕩` rather than outer-scoped variables to ensure errors are captured.
  - Require test fixtures with custom configs to inherit/copy `config/default_config.tsv` keys completely.
  - Simplify test scripts to delegate exact value checks to golden files, keeping `grep` checks in `.sh` files generic (e.g. regex for key existence or type).
- Candidate type: rule / docs / check
- Related tool/doc: `AGENTS.md`, `src_next/json.bqn`, `checks/check-src-next-envelope-computation.sh`

### 2026-07-05: Subprocess testing debug visibility & temporary pipeline SIGPIPE

- Context: A4 config resolution negative tests implementation and verification slice (PR #45, #47, #48)
- Friction:
  - Subprocess-level negative tests (using `•SH` on `.bqn` probes) only report exit code 1 to the parent test runner. When the assertion fails, it's hard to diagnose *why* or *where* the subprocess failed without manually executing the probe command in the terminal.
  - Intermittent SIGPIPE (exit code 141) occurred during the execution of `check.sh` under `rtk` wrapper, causing the test suite to fail halfway without a clear BQN-level trace.
- Idea:
  - Add stdout/stderr capturing or auto-dumping helper in `test_lib.bqn` for `•SH` calls so that when a subprocess test fails, it prints the captured output inline.
  - Review how `rtk` or pipeline consumers handle SIGPIPE, ensuring robust logging or exit status handling to avoid fragile CI/check failures.
- Candidate type: existing-tool-improvement / check
- Related tool/doc: `tests/test_src_next_config_required_negative.bqn`, `tools/check.sh`
- Review outcome:
  - Subprocess debug visibility: `resolved` for the selected first slice through PR #59 → #60 → #61.
  - Root cause was refined to failure evidence being retained but not surfaced at the nearest useful assertion owner.
  - `tests/test_lib.bqn` now owns generic failure-only evidence surfacing; domain expectations remain in the individual negative test.
  - Controlled red-path regression coverage was added; GitHub Actions `Run check.sh` and `Coverage` were green before merge.
  - Broader subprocess migration is not authorized by momentum.
  - Temporary SIGPIPE / exit 141 remains separate `observe-more` work.
- Review record: `../completed-plans/SUBPROCESS_DEBUG_VISIBILITY_REVIEW-2026-07-05.md`

### 2026-07-13: Public-command fidelity must be tested before final rehearsal

- Context: Israel ordinary journal readiness and later four-path synthetic rehearsal.
- Friction: Phase 1 used `--post-check none` for focused metadata checks, so the documented default `lint` path was not exercised until Phase 5; only then did the valid ILS-then-JPY sequence reveal append-success followed by `mixed_currency_domains` failure without rollback.
- Idea: Separate focused contract tests from public-use rehearsal, and run at least one exact documented command with its default options in the earliest readiness phase. Do not add a bypass flag that is absent from the acceptance command merely to make a focused fixture pass.
- Candidate type: rule / verification / workflow
- Related tool/doc: `checks/check-edit-bqn-currency-m2.sh`, `checks/check-israel-travel-four-path-rehearsal.sh`, `docs/ISRAEL_TRAVEL_EDITOR_USAGE.md`

### 2026-07-13: Green-path check output consumes excessive context

- Context: Repeated `env -u LEDGER_DATA_DIR rtk bash ./tools/check.sh` validation across the Israel multi-PR sequence.
- Friction: Successful section checks emitted a large amount of repetitive output through `rtk`, consuming substantial conversation context even though only phase/result summaries were needed; red-path evidence must still remain complete.
- Idea: Evaluate a green-path summary mode or existing `rtk` / `sqz` improvement that reports phase names, counts, and final PASS while preserving full stdout/stderr for the failing check. Do not hide failure output with unconditional redirection.
- Candidate type: existing-tool-improvement / check
- Related tool/doc: `tools/check.sh`, `rtk`, `sqz`, `docs/QUALITY_BAR.md`

### 2026-07-13: Coverage leaves Python bytecode during clean-tree gates

- Context: Running `tools/coverage` before each Israel phase commit and PR.
- Friction: The command repeatedly created ignored `tools/__pycache__/` content, requiring manual removal before reliable clean-tree and scope review.
- Idea: Check whether `tools/coverage` can internally prevent bytecode generation, for example with the equivalent of `PYTHONDONTWRITEBYTECODE=1`, without changing coverage semantics.
- Candidate type: existing-tool-improvement
- Related tool/doc: `tools/coverage`, `git status`

### 2026-07-13: Completion records cannot contain their own final merge hash

- Context: Phase 5 moved its active plan to completed and was required to record every merge commit in the same PR.
- Friction: A PR's final merge commit does not exist while that PR's completed record is being authored; satisfying the requirement literally would need an otherwise unnecessary follow-up PR.
- Idea: Standardize completion evidence so the closing PR records its PR number, branch commit, and checks, names PR metadata as the merge-hash owner, and the final human/pit report records the resolved merge commit after merge.
- Candidate type: rule / docs / workflow
- Related tool/doc: `docs/DOCS_LIFECYCLE_CONTRACT.md`, completed-plan templates, GitHub PR metadata
