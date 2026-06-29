package main

import (
	"bytes"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func setupMinimalJournalDir(t *testing.T, journalContent string) string {
	t.Helper()
	tempDir := t.TempDir()
	writeText(t, filepath.Join(tempDir, "accounts.tsv"), strings.Join([]string{
		"assets:bank\ttype=liquid",
		"assets:cash\ttype=liquid",
		"expenses:food\tbudget=daily",
		"expenses:misc\tbudget=flex",
		"",
	}, "\n"))
	writeText(t, filepath.Join(tempDir, "journal.tsv"), journalContent)
	return tempDir
}

func readText(t *testing.T, path string) string {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read %s: %v", path, err)
	}
	return string(content)
}

func resetJournalGlobals(t *testing.T) {
	t.Helper()
	oldNow := nowFunc
	oldHook := beforeJournalReplaceHook
	oldRunner := postCheckRunner
	t.Cleanup(func() {
		nowFunc = oldNow
		beforeJournalReplaceHook = oldHook
		postCheckRunner = oldRunner
	})
	nowFunc = func() time.Time { return time.Date(2026, 6, 19, 12, 34, 56, 0, time.Local) }
	beforeJournalReplaceHook = nil
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		return postCheckResult{Command: "fake " + mode}, nil
	}
}

func journalAddArgs(extra ...string) []string {
	args := []string{
		"--date", "2026-06-19",
		"--memo", "コンビニ",
		"--from", "assets:cash",
		"--to", "expenses:food",
		"--amount", "500",
	}
	return append(args, extra...)
}

func TestJournalAddDryRunDoesNotMutate(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalJournalDir(t, "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n")
	journalPath := filepath.Join(tempDir, "journal.tsv")
	before := readText(t, journalPath)

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--meta", "receipt=yes", "--dry-run")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add --dry-run failed: %v", err)
	}

	if after := readText(t, journalPath); after != before {
		t.Fatalf("dry-run mutated journal.tsv\nbefore=%q\nafter=%q", before, after)
	}
	output := out.String()
	if !strings.Contains(output, "Mode: dry-run") || !strings.Contains(output, "Post-check: lint") || !strings.Contains(output, "Target: ") {
		t.Fatalf("preview missing required fields: %s", output)
	}
	if !strings.Contains(output, "2026-06-19\tコンビニ\tassets:cash\texpenses:food\t500\treceipt=yes") {
		t.Fatalf("preview missing exact TSV row: %s", output)
	}
}

func TestJournalAddValidationRejectsInvalidInputs(t *testing.T) {
	resetJournalGlobals(t)
	tests := []struct {
		name      string
		extra     []string
		wantError string
	}{
		{name: "invalid date", extra: []string{"--date", "2026-02-30"}, wantError: "invalid date"},
		{name: "non integer amount", extra: []string{"--amount", "10.5"}, wantError: "amount must be an integer"},
		{name: "unknown from", extra: []string{"--from", "assets:missing"}, wantError: "unknown from account"},
		{name: "unknown to", extra: []string{"--to", "expenses:missing"}, wantError: "unknown to account"},
		{name: "invalid metadata", extra: []string{"--meta", "badmeta"}, wantError: "invalid metadata token"},
		{name: "tab in memo", extra: []string{"--memo", "bad\tmemo"}, wantError: "memo must not contain TAB or newline"},
		{name: "newline in meta", extra: []string{"--meta", "note=bad\nvalue"}, wantError: "metadata token must not contain TAB or newline"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tempDir := setupMinimalJournalDir(t, "")
			args := []string{"--base", tempDir, "journal", "add"}
			baseArgs := journalAddArgs("--dry-run")
			for i := 0; i < len(tt.extra); i += 2 {
				for j := 0; j < len(baseArgs)-1; j++ {
					if baseArgs[j] == tt.extra[i] {
						baseArgs[j+1] = tt.extra[i+1]
						goto replaced
					}
				}
				baseArgs = append(baseArgs, tt.extra[i], tt.extra[i+1])
			replaced:
			}
			args = append(args, baseArgs...)
			var out bytes.Buffer
			err := runCmd(args, strings.NewReader(""), &out, os.Stderr)
			if err == nil {
				t.Fatalf("expected validation error")
			}
			if !strings.Contains(err.Error(), tt.wantError) {
				t.Fatalf("expected error containing %q, got: %v", tt.wantError, err)
			}
		})
	}
}

func TestJournalAddAppendWithTrailingNewline(t *testing.T) {
	resetJournalGlobals(t)
	original := "# comment\n\n2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n"
	tempDir := setupMinimalJournalDir(t, original)
	journalPath := filepath.Join(tempDir, "journal.tsv")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--meta", "receipt=yes", "--meta", "note=keep", "--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add failed: %v\n%s", err, out.String())
	}

	expected := original + "2026-06-19\tコンビニ\tassets:cash\texpenses:food\t500\treceipt=yes\tnote=keep\n"
	if got := readText(t, journalPath); got != expected {
		t.Fatalf("unexpected journal content\nwant=%q\n got=%q", expected, got)
	}
	if !strings.Contains(out.String(), "Post-check: skipped") {
		t.Fatalf("expected skipped post-check output: %s", out.String())
	}
}

func TestJournalAddAppendWithoutTrailingNewline(t *testing.T) {
	resetJournalGlobals(t)
	original := "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100"
	tempDir := setupMinimalJournalDir(t, original)
	journalPath := filepath.Join(tempDir, "journal.tsv")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add failed: %v", err)
	}

	expected := original + "\n2026-06-19\tコンビニ\tassets:cash\texpenses:food\t500\n"
	if got := readText(t, journalPath); got != expected {
		t.Fatalf("unexpected journal content\nwant=%q\n got=%q", expected, got)
	}
}

func TestJournalAddEmptyMemoAndNoMetadata(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalJournalDir(t, "")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	args := []string{"--base", tempDir, "journal", "add", "--date", "2026-06-19", "--memo", "", "--from", "assets:cash", "--to", "expenses:food", "--amount", "500", "--yes", "--post-check", "none"}
	var out bytes.Buffer
	if err := runCmd(args, strings.NewReader(""), &out, os.Stderr); err != nil {
		t.Fatalf("journal add failed: %v", err)
	}

	want := "2026-06-19\t\tassets:cash\texpenses:food\t500\n"
	if got := readText(t, journalPath); got != want {
		t.Fatalf("empty memo or five-field row not preserved\nwant=%q\n got=%q", want, got)
	}
}

func TestJournalAddConfirmCancelDoesNotMutate(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalJournalDir(t, "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n")
	journalPath := filepath.Join(tempDir, "journal.tsv")
	before := readText(t, journalPath)

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--post-check", "none")...), strings.NewReader("\n"), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add cancel failed: %v", err)
	}
	if got := readText(t, journalPath); got != before {
		t.Fatalf("cancel mutated journal.tsv")
	}
	if !strings.Contains(out.String(), "Cancelled. No files were modified.") {
		t.Fatalf("expected cancel output, got: %s", out.String())
	}
}

func TestJournalAddCreatesBackup(t *testing.T) {
	resetJournalGlobals(t)
	original := "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n"
	tempDir := setupMinimalJournalDir(t, original)

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add failed: %v", err)
	}

	backupPath := filepath.Join(tempDir, ".backup", "20260619-123456", "journal.tsv")
	if got := readText(t, backupPath); got != original {
		t.Fatalf("backup content mismatch\nwant=%q\n got=%q", original, got)
	}
	entries, err := filepath.Glob(filepath.Join(tempDir, ".journal.tsv.tmp-*"))
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 0 {
		t.Fatalf("temp files left behind: %v", entries)
	}
}

func TestJournalAddDoesNotOverwriteBackupInSameSecond(t *testing.T) {
	resetJournalGlobals(t)
	original := "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n"
	tempDir := setupMinimalJournalDir(t, original)
	preexistingBackup := filepath.Join(tempDir, ".backup", "20260619-123456", "journal.tsv")
	if err := os.MkdirAll(filepath.Dir(preexistingBackup), 0755); err != nil {
		t.Fatal(err)
	}
	writeText(t, preexistingBackup, "do not overwrite\n")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add failed: %v", err)
	}

	if got := readText(t, preexistingBackup); got != "do not overwrite\n" {
		t.Fatalf("preexisting backup was overwritten: %q", got)
	}
	secondBackup := filepath.Join(tempDir, ".backup", "20260619-123456-02", "journal.tsv")
	if got := readText(t, secondBackup); got != original {
		t.Fatalf("second backup content mismatch\nwant=%q\n got=%q", original, got)
	}
}

func TestJournalAddFailureBeforeRenameLeavesSourceUnchanged(t *testing.T) {
	resetJournalGlobals(t)
	original := "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n"
	tempDir := setupMinimalJournalDir(t, original)
	journalPath := filepath.Join(tempDir, "journal.tsv")
	beforeJournalReplaceHook = func(path string) error {
		return errors.New("injected failure before stale check")
	}

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err == nil {
		t.Fatalf("expected injected failure")
	}
	if got := readText(t, journalPath); got != original {
		t.Fatalf("source changed after injected pre-rename failure\nwant=%q\n got=%q", original, got)
	}
}

func TestJournalAddStaleCheckRefusesWrite(t *testing.T) {
	resetJournalGlobals(t)
	original := "2026-06-18\tBefore\tassets:cash\texpenses:misc\t100\n"
	tempDir := setupMinimalJournalDir(t, original)
	journalPath := filepath.Join(tempDir, "journal.tsv")
	beforeJournalReplaceHook = func(path string) error {
		return os.WriteFile(path, []byte(original+"2026-06-18\tOther\tassets:cash\texpenses:food\t1\n"), 0644)
	}

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err == nil {
		t.Fatalf("expected stale check error")
	}
	if !strings.Contains(err.Error(), "stale") {
		t.Fatalf("expected stale error, got: %v", err)
	}
	got := readText(t, journalPath)
	if strings.Contains(got, "コンビニ") {
		t.Fatalf("stale write appended duplicate row: %q", got)
	}
	if !strings.Contains(got, "Other") {
		t.Fatalf("expected concurrent edit to remain, got: %q", got)
	}
}

func TestJournalAddDefaultPostCheckInvoked(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalJournalDir(t, "")
	called := false
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		called = true
		if base != tempDir {
			t.Fatalf("post-check base = %s; want %s", base, tempDir)
		}
		if mode != "lint" {
			t.Fatalf("post-check mode = %s; want lint", mode)
		}
		return postCheckResult{Command: "fake lint"}, nil
	}

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal add failed: %v", err)
	}
	if !called {
		t.Fatalf("post-check runner was not called")
	}
	if !strings.Contains(out.String(), "Post-check command: fake lint") || !strings.Contains(out.String(), "Post-check: OK") {
		t.Fatalf("missing post-check output: %s", out.String())
	}
}

func TestJournalAddPostCheckFailureReportsRestore(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalJournalDir(t, "")
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		return postCheckResult{Command: "fake lint", Output: "lint failed"}, errors.New("lint failed")
	}

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "journal", "add"}, journalAddArgs("--yes")...), strings.NewReader(""), &out, os.Stderr)
	if err == nil {
		t.Fatalf("expected post-check failure")
	}
	output := out.String()
	if !strings.Contains(output, "Post-check failed.") || !strings.Contains(output, "Restore suggestion:") || !strings.Contains(output, "lint failed") {
		t.Fatalf("missing restore details after post-check failure: %s", output)
	}
	if !strings.Contains(readText(t, filepath.Join(tempDir, "journal.tsv")), "コンビニ") {
		t.Fatalf("write should remain after post-check failure")
	}
}

// ── journal reverse tests ──

func TestJournalReverseByIndex(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := strings.Join([]string{
		"2026-06-15\t給料\tincome:salary\tassets:bank\t100000",
		"2026-06-16\t買い物\tassets:cash\texpenses:food\t500",
		"2026-06-17\tコンビニ\tassets:cash\texpenses:misc\t300",
		"",
	}, "\n")
	tempDir := setupMinimalJournalDir(t, journalContent)

	var out bytes.Buffer
	// Reverse row 2 (買い物): from=assets:cash to=expenses:food amount=500
	// Expected reversal: from=expenses:food to=assets:cash amount=500 memo=[reverse]買い物
	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--index", "2", "--date", "2026-06-26", "--yes"}, strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal reverse failed: %v", err)
	}

	journalAfter := readText(t, filepath.Join(tempDir, "journal.tsv"))
	if !strings.Contains(journalAfter, "[reverse]買い物") {
		t.Fatalf("reversed journal should contain [reverse]買い物\n%s", journalAfter)
	}
	if !strings.Contains(journalAfter, "expenses:food\tassets:cash\t500") {
		t.Fatalf("reversed row should swap from/to: expenses:food -> assets:cash 500\n%s", journalAfter)
	}
	if !strings.Contains(journalAfter, "2026-06-26") {
		t.Fatalf("reversed row should have specified date\n%s", journalAfter)
	}

	output := out.String()
	if !strings.Contains(output, "Reversing journal row 2") {
		t.Fatalf("output should mention row 2: %s", output)
	}
	if !strings.Contains(output, "Original: assets:cash -> expenses:food") {
		t.Fatalf("output should show original from/to: %s", output)
	}
	if !strings.Contains(output, "Reversed: expenses:food -> assets:cash") {
		t.Fatalf("output should show reversed from/to: %s", output)
	}
}

func TestJournalReverseByID(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := strings.Join([]string{
		"2026-06-15\t給料\tincome:salary\tassets:bank\t100000",
		"2026-06-16\t買い物\tassets:cash\texpenses:food\t500",
		"2026-06-17\tコンビニ\tassets:cash\texpenses:misc\t300",
		"",
	}, "\n")
	tempDir := setupMinimalJournalDir(t, journalContent)

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--id", "買い物", "--date", "2026-06-26", "--yes"}, strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal reverse by id failed: %v", err)
	}

	journalAfter := readText(t, filepath.Join(tempDir, "journal.tsv"))
	if !strings.Contains(journalAfter, "[reverse]買い物") {
		t.Fatalf("reversed journal should contain [reverse]買い物\n%s", journalAfter)
	}
}

func TestJournalReverseDuplicateIDError(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := strings.Join([]string{
		"2026-06-15\t買い物\tassets:cash\texpenses:food\t500",
		"2026-06-16\t買い物\tassets:cash\texpenses:misc\t300",
		"",
	}, "\n")
	tempDir := setupMinimalJournalDir(t, journalContent)

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--id", "買い物", "--date", "2026-06-26", "--yes"}, strings.NewReader(""), &out, os.Stderr)
	if err == nil {
		t.Fatal("expected error for duplicate ID")
	}
	if !strings.Contains(err.Error(), "multiple journal rows match") {
		t.Fatalf("error should mention multiple matches: %v", err)
	}
}

func TestJournalReverseNotFoundError(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := "2026-06-15\t給料\tincome:salary\tassets:bank\t100000\n"
	tempDir := setupMinimalJournalDir(t, journalContent)

	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--id", "nonexistent", "--yes"}, strings.NewReader(""), io.Discard, os.Stderr)
	if err == nil {
		t.Fatal("expected error for nonexistent ID")
	}
	if !strings.Contains(err.Error(), "no journal row found") {
		t.Fatalf("error should mention not found: %v", err)
	}
}

func TestJournalReverseInvalidIndexError(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := "2026-06-15\t給料\tincome:salary\tassets:bank\t100000\n"
	tempDir := setupMinimalJournalDir(t, journalContent)

	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--index", "99", "--yes"}, strings.NewReader(""), io.Discard, os.Stderr)
	if err == nil {
		t.Fatal("expected error for out-of-range index")
	}
	if !strings.Contains(err.Error(), "invalid index") {
		t.Fatalf("error should mention invalid index: %v", err)
	}
}

func TestJournalReversePreservesMetadata(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := "2026-06-16\t買い物\tassets:cash\texpenses:food\t500\treceipt=yes\ttxn_id=abc123\n"
	tempDir := setupMinimalJournalDir(t, journalContent)

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--index", "1", "--date", "2026-06-26", "--yes"}, strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal reverse failed: %v", err)
	}

	journalAfter := readText(t, filepath.Join(tempDir, "journal.tsv"))
	if !strings.Contains(journalAfter, "receipt=yes") {
		t.Fatalf("reversed row should preserve receipt=yes metadata\n%s", journalAfter)
	}
	if !strings.Contains(journalAfter, "txn_id=abc123") {
		t.Fatalf("reversed row should preserve txn_id=abc123 metadata\n%s", journalAfter)
	}
}

func TestJournalReverseUsesTodayWhenNoDate(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := "2026-06-16\t買い物\tassets:cash\texpenses:food\t500\n"
	tempDir := setupMinimalJournalDir(t, journalContent)

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--index", "1", "--yes"}, strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("journal reverse failed: %v", err)
	}

	journalAfter := readText(t, filepath.Join(tempDir, "journal.tsv"))
	// nowFunc returns 2026-06-19
	if !strings.Contains(journalAfter, "2026-06-19") {
		t.Fatalf("reversed row should use today's date (2026-06-19)\n%s", journalAfter)
	}
}

func TestJournalReverseSameFromToError(t *testing.T) {
	resetJournalGlobals(t)
	journalContent := "2026-06-16\t調整\tassets:cash\tassets:cash\t0\n"
	tempDir := setupMinimalJournalDir(t, journalContent)

	err := runCmd([]string{"--base", tempDir, "journal", "reverse", "--index", "1", "--yes"}, strings.NewReader(""), io.Discard, os.Stderr)
	if err == nil {
		t.Fatal("expected error when from and to are the same")
	}
	if !strings.Contains(err.Error(), "from and to accounts are the same") {
		t.Fatalf("error should mention same accounts: %v", err)
	}
}
