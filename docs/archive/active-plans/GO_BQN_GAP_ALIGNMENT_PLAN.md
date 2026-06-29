# Go/BQN Editor Gap Alignment Plan

Status: **Active Draft / Ready for Implementation**
Date: 2026-06-29

This document outlines the concrete steps required to close all behavioral, functional, and safety gaps between the original Go editor and the new BQN + Bash editor implementation, ensuring 100% equivalence before permanently removing the Go editor.

---

## 1. Background

During Phase 2 of the Go editor removal process, the BQN + Bash editor implementation was successfully bootstrapped. However, to prioritize data safety and workflow parity, we reverted the active wrapper (`tools/edit`) to use the Go editor. 

We will now close the remaining safety and functional gaps systematically before switching the dispatcher permanently.

---

## 2. Identified Gaps

### A. Dynamic Schema Parsing (`config/meta_schema.tsv`)
* **Go Editor**: Reads `config/meta_schema.tsv` dynamically at runtime. Keys with target `plan` are registered as plan-only metadata and automatically stripped from the metadata when finishing a plan (e.g. converting a plan row into a journal row).
* **BQN Editor**: Hardcodes these plan-only keys (`anchor`, `months`, `offset`, `recur`). If a user customizes `meta_schema.tsv`, the BQN editor fails to respect the new definitions.

### B. Concurrent Write Protection (Stale Checks)
* **Go Editor**: Reads the file size, modification timestamp, and computes a SHA256 hash of the target TSV file at start. Right before performing the atomic write, it re-verifies these parameters against the current file on disk (`checkStale`). If the file was changed by another process, it aborts the write to prevent data loss.
* **BQN Editor + Bash Wrapper**: Lacks strict SHA256 stale checking before writing.

### C. Exact Row Replacement Safety
* **Go Editor**: In `plan edit` and `plan finish`, it ensures that the line content at the target line number matches the expected `oldLine` exactly. If it has drifted, the rewrite is aborted.
* **BQN Editor + Bash Wrapper**: Lacks exact line matching assertion right before writing.

### D. TTY Check and Built-in Interactive Prompts
* **Go Editor**: Detects if stdin is a TTY. If running interactively, it prompts the user inside the editor process (e.g., prompting for actual date in `plan finish`).
* **BQN Editor**: Lacks interactive terminal prompt capability (relies entirely on wrapper/caller scripts).

---

## 3. Plan to Close Gaps (Action Items)

### Step 1: BQN-Side Dynamic Schema Parsing
Extend the BQN editor modules to parse `config/meta_schema.tsv` dynamically:
1. Import `config.bqn` or use `loader.bqn` to read `config/meta_schema.tsv`.
2. Extract all keys where the 4th column is `"plan"`.
3. Use this dynamic list of keys instead of the hardcoded `planOnlyKeys` inside `RunFinish`.

### Step 2: Bash-Side Safety Features in `tools/edit`
Enhance `tools/edit` and `tools/lib/safe-write.sh` to implement strict stale and drift checking:
1. **SHA256 Stale Check**:
   - When launching `tools/edit`, calculate and store the target file's size, modification time (using `stat` or `date`), and SHA256 hash (using `shasum -a 256` or `openssl dgst -sha256`).
   - Before writing the temporary file back in `safe-write.sh`, re-calculate these parameters and verify they match the initial state. Abort if a mismatch is detected.
2. **Exact Line Matching**:
   - Before replacing a line in `safe-write.sh` (e.g. for `plan edit` or `plan finish`), check that the line at the target line number matches `oldLine` exactly. Abort if it differs.

### Step 3: Parity Test Suite (`checks/check-editor-parity.sh`)
Build an automated, black-box parity testing tool to assert identical behavior:
1. Runs the Go editor (`tools/edit.bin`) and BQN editor dispatcher (`bqn src_edit/editor_cmd.bqn`) on identical copies of fixture directories.
2. Exercises all 8 CLI commands:
   - `journal add` / `journal reverse`
   - `budget add`
   - `issue add`
   - `plan list` (text and tsv formats)
   - `plan add` / `plan edit` / `plan finish`
3. Verifies that:
   - Exit codes match exactly.
   - Stdout and Stderr outputs match character-for-character.
   - Resulting TSV file modifications are byte-for-byte identical.

---

## 4. Migration & Verification Phases

```mermaid
graph TD
    A["Phase A: Implement Dynamic Schema in BQN"] --> B["Phase B: Implement SHA256 & Line Assertions in Bash"]
    B --> C["Phase C: Implement Black-box Parity Test Suite"]
    C --> D["Phase D: Verify Parity Across All 8 Commands"]
    D --> E["Phase E: Switch Dispatcher and Remove Go Dependency"]
```

1. **Phase A**: Update `src_edit/editor_cmd.bqn` to dynamically read plan-only keys.
2. **Phase B**: Add robust TTY detection, exact line matching, and SHA256 stale checking in `tools/edit` and `safe-write.sh`.
3. **Phase C**: Write `checks/check-editor-parity.sh` and hook it into `tools/check.sh`.
4. **Phase D**: Run parity testing until all test cases produce identical outputs.
5. **Phase E**: Change the `tools/edit` symlink/dispatch to point to the BQN path, verify, and archive the `editor/` Go codebase.
