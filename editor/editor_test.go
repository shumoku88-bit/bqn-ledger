package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func setupTestDir(t *testing.T, fixtureName string) string {
	t.Helper()
	tempDir := t.TempDir()

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("failed to get cwd: %v", err)
	}
	fixtureDir := filepath.Join(cwd, "..", "fixtures", fixtureName)

	files, err := os.ReadDir(fixtureDir)
	if err != nil {
		t.Fatalf("failed to read fixture dir %s: %v", fixtureDir, err)
	}

	for _, f := range files {
		if f.IsDir() {
			continue
		}
		srcPath := filepath.Join(fixtureDir, f.Name())
		dstPath := filepath.Join(tempDir, f.Name())
		if err := copyFile(srcPath, dstPath); err != nil {
			t.Fatalf("failed to copy %s to temp: %v", f.Name(), err)
		}
	}

	return tempDir
}

func writeText(t *testing.T, path string, content string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatalf("failed to write %s: %v", path, err)
	}
}

func setupMinimalPlanDir(t *testing.T, planContent string) string {
	t.Helper()
	tempDir := t.TempDir()
	writeText(t, filepath.Join(tempDir, "accounts.tsv"), strings.Join([]string{
		"assets:bank\ttype=liquid",
		"expenses:misc\tbudget=flex",
		"expenses:food\tbudget=daily",
		"",
	}, "\n"))
	writeText(t, filepath.Join(tempDir, "journal.tsv"), "")
	writeText(t, filepath.Join(tempDir, "plan.tsv"), planContent)
	return tempDir
}

func TestTSVBasics(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	planPath := filepath.Join(tempDir, "plan.tsv")

	tsv, err := ReadTSV(planPath)
	if err != nil {
		t.Fatalf("ReadTSV failed: %v", err)
	}

	if len(tsv.Rows) < 4 {
		t.Errorf("Expected at least 4 rows, got %d", len(tsv.Rows))
	}

	if tsv.SHA256 == "" {
		t.Errorf("SHA256 hash was empty")
	}

	if err := tsv.CheckStale(); err != nil {
		t.Errorf("Expected file not to be stale: %v", err)
	}
}

func TestPlanIDValidation(t *testing.T) {
	tests := []struct {
		id    string
		valid bool
	}{
		{"plan-2026-01-10-phone", true},
		{"plan-2026-12-31-abc-123", true},
		{"plan-2026-01-10-", false},
		{"plan-2026-02-30-series", false},
		{"plan-26-01-10-series", false},
		{"plan-2026-01-series", false},
		{"plan-2026-01-10", false},
		{"2026-01-10-phone", false},
	}

	for _, tt := range tests {
		t.Run(tt.id, func(t *testing.T) {
			if got := validatePlanIDFormat(tt.id); got != tt.valid {
				t.Errorf("validatePlanIDFormat(%q) = %v; want %v", tt.id, got, tt.valid)
			}
		})
	}
}

func TestPlanCompletionLogicAndFilter(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "list"}, nil, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan list failed: %v", err)
	}

	output := outBuf.String()
	if strings.Contains(output, "Rent") {
		t.Errorf("Expected CLOSED plan 'Rent' to be filtered out of normal list, but got: %s", output)
	}
	if !strings.Contains(output, "Unfulfilled phone") {
		t.Errorf("Expected open plan 'Unfulfilled phone' to appear, but got: %s", output)
	}
	if !strings.Contains(output, "Unplanned food") {
		t.Errorf("Expected 'Unplanned food' to appear, but got: %s", output)
	}
	if !strings.Contains(output, "[MISSING-ID]") {
		t.Errorf("Expected [MISSING-ID] indicator for Unplanned food, but got: %s", output)
	}
}

func TestPlanListAllOptions(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "list", "--all"}, nil, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan list --all failed: %v", err)
	}

	output := outBuf.String()
	if !strings.Contains(output, "Rent") {
		t.Errorf("Expected CLOSED plan 'Rent' to appear with --all, but got: %s", output)
	}
	if !strings.Contains(output, "[CLOSED]") {
		t.Errorf("Expected [CLOSED] indicator for Rent, but got: %s", output)
	}
	if !strings.Contains(output, "[MISSING-ID]") {
		t.Errorf("Expected [MISSING-ID] indicator, but got: %s", output)
	}
}

func TestPlanFinishPreviewDoesNotMutate(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	planPath := filepath.Join(tempDir, "plan.tsv")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	pStatBefore, err := os.Stat(planPath)
	if err != nil {
		t.Fatal(err)
	}
	jStatBefore, err := os.Stat(journalPath)
	if err != nil {
		t.Fatal(err)
	}

	var outBuf bytes.Buffer
	err = runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-12"}, nil, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan finish failed: %v", err)
	}

	output := outBuf.String()
	if !strings.Contains(output, "Dry-run only. No files were modified.") {
		t.Errorf("Expected preview warning, got: %s", output)
	}
	if !strings.Contains(output, "2026-01-12\tUnfulfilled phone\tassets:bank\texpenses:misc\t1500\tplan_id=plan-2026-01-10-phone") {
		t.Errorf("Expected correct candidate output, got: %s", output)
	}

	pStatAfter, err := os.Stat(planPath)
	if err != nil {
		t.Fatal(err)
	}
	jStatAfter, err := os.Stat(journalPath)
	if err != nil {
		t.Fatal(err)
	}

	if pStatBefore.ModTime() != pStatAfter.ModTime() || pStatBefore.Size() != pStatAfter.Size() {
		t.Errorf("plan.tsv was mutated during preview")
	}
	if jStatBefore.ModTime() != jStatAfter.ModTime() || jStatBefore.Size() != jStatAfter.Size() {
		t.Errorf("journal.tsv was mutated during preview")
	}
}

func TestPlanFinishApply(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	planPath := filepath.Join(tempDir, "plan.tsv")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	pStatBefore, err := os.Stat(planPath)
	if err != nil {
		t.Fatal(err)
	}

	// Mock input 'y\n' for confirmation
	inBuf := bytes.NewBufferString("y\n")
	var outBuf bytes.Buffer

	// Stub out the post-check runner to bypass bqn lint in the unit test environment
	oldPostCheck := postCheckRunner
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		return postCheckResult{Command: "mocked"}, nil
	}
	defer func() { postCheckRunner = oldPostCheck }()

	err = runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-12", "--apply"}, inBuf, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan finish --apply failed: %v", err)
	}

	output := outBuf.String()
	if !strings.Contains(output, "Wrote:") {
		t.Errorf("Expected 'Wrote:' in stdout, got: %s", output)
	}

	// Verify journal.tsv got appended with plan_id
	journalBytes, err := os.ReadFile(journalPath)
	if err != nil {
		t.Fatal(err)
	}
	journalContent := string(journalBytes)
	expectedRow := "2026-01-12\tUnfulfilled phone\tassets:bank\texpenses:misc\t1500\tplan_id=plan-2026-01-10-phone"
	if !strings.Contains(journalContent, expectedRow) {
		t.Errorf("Expected journal.tsv to contain appended row, but got content:\n%s", journalContent)
	}

	// Verify plan list now hides this completed plan
	var listBuf bytes.Buffer
	err = runCmd([]string{"--base", tempDir, "plan", "list"}, nil, &listBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan list failed: %v", err)
	}
	listOutput := listBuf.String()
	if strings.Contains(listOutput, "Unfulfilled phone") {
		t.Errorf("Expected completed plan 'Unfulfilled phone' to disappear from list, but it is still there: %s", listOutput)
	}

	// Verify plan.tsv was not mutated
	pStatAfter, err := os.Stat(planPath)
	if err != nil {
		t.Fatal(err)
	}
	if pStatBefore.ModTime() != pStatAfter.ModTime() || pStatBefore.Size() != pStatAfter.Size() {
		t.Errorf("plan.tsv was mutated during finish apply (it should remain unchanged)")
	}
}

func TestPlanFinishPreviewByID(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--id", "plan-2026-01-24-book", "--actual-date", "2026-01-26"}, nil, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan finish --id failed: %v", err)
	}

	output := outBuf.String()
	if !strings.Contains(output, "2026-01-26\tPlanned book\tassets:bank\texpenses:misc\t2000\tplan_id=plan-2026-01-24-book") {
		t.Errorf("Expected candidate selected by plan_id, got: %s", output)
	}
}

func TestPlanFinishRejectsClosedPlan(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--all", "--index", "2", "--actual-date", "2026-01-16"}, nil, &outBuf, os.Stderr)
	if err == nil {
		t.Fatalf("expected closed plan to be rejected")
	}
	if !strings.Contains(err.Error(), "already closed") {
		t.Fatalf("expected already closed error, got: %v", err)
	}
}

func TestPlanListRejectsInvalidPlanFields(t *testing.T) {
	tests := []struct {
		name      string
		planLine  string
		wantError string
	}{
		{
			name:      "invalid date",
			planLine:  "2026-02-30\tBad date\tassets:bank\texpenses:misc\t100\tplan_id=plan-2026-02-30-bad",
			wantError: "invalid date",
		},
		{
			name:      "invalid amount",
			planLine:  "2026-01-10\tBad amount\tassets:bank\texpenses:misc\t10.5\tplan_id=plan-2026-01-10-bad",
			wantError: "amount must be an integer",
		},
		{
			name:      "invalid metadata",
			planLine:  "2026-01-10\tBad meta\tassets:bank\texpenses:misc\t100\tplan_id",
			wantError: "invalid metadata token",
		},
		{
			name:      "unknown account",
			planLine:  "2026-01-10\tBad account\tassets:missing\texpenses:misc\t100\tplan_id=plan-2026-01-10-bad",
			wantError: "unknown from account",
		},
		{
			name:      "too few columns",
			planLine:  "2026-01-10\tToo short\tassets:bank\texpenses:misc",
			wantError: "expected at least 5",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tempDir := setupMinimalPlanDir(t, tt.planLine+"\n")
			var outBuf bytes.Buffer
			err := runCmd([]string{"--base", tempDir, "plan", "list"}, nil, &outBuf, os.Stderr)
			if err == nil {
				t.Fatalf("expected error for invalid plan line")
			}
			if !strings.Contains(err.Error(), tt.wantError) {
				t.Fatalf("expected error containing %q, got: %v", tt.wantError, err)
			}
		})
	}
}

func TestJournalCandidateStripsPlanOnlyMetadata(t *testing.T) {
	row := PlanRow{Fields: []string{
		"2026-01-10",
		"Recurring",
		"assets:bank",
		"expenses:misc",
		"1000",
		"recur=monthly",
		"anchor=income:salary",
		"offset=1",
		"months=2",
		"series=recurring",
		"plan_id=plan-2026-01-10-recurring",
		"note=keep",
	}}

	candidate := strings.Join(JournalCandidate(row, "2026-01-11"), "\t")
	if strings.Contains(candidate, "recur=") || strings.Contains(candidate, "anchor=") || strings.Contains(candidate, "offset=") || strings.Contains(candidate, "months=") {
		t.Fatalf("plan-only metadata was not stripped: %s", candidate)
	}
	if !strings.Contains(candidate, "series=recurring") || !strings.Contains(candidate, "plan_id=plan-2026-01-10-recurring") || !strings.Contains(candidate, "note=keep") {
		t.Fatalf("expected non-plan-only metadata to be preserved: %s", candidate)
	}
}

func TestPlanFinishRejectsMissingID(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	// index 3 in plan-completion fixture is 'Unplanned food' which lacks a plan_id
	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "3", "--actual-date", "2026-01-25"}, nil, &outBuf, os.Stderr)
	if err == nil {
		t.Fatal("expected error for plan with missing plan_id")
	}
	if !strings.Contains(err.Error(), "cannot finish plan without plan_id") {
		t.Errorf("expected missing plan_id error, got: %v", err)
	}
}

func TestPlanFinishRejectsInvalidID(t *testing.T) {
	invalidPlanLine := "2026-01-10\tBad ID\tassets:bank\texpenses:misc\t1000\tplan_id=invalid-id-format\n"
	tempDir := setupMinimalPlanDir(t, invalidPlanLine)
	
	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-12"}, nil, &outBuf, os.Stderr)
	if err == nil {
		t.Fatal("expected error for plan with invalid plan_id format")
	}
	if !strings.Contains(err.Error(), "cannot finish plan with invalid plan_id: invalid-id-format") {
		t.Errorf("expected invalid plan_id format error, got: %v", err)
	}
}

func TestPlanFinishCancelDoesNotMutate(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	jStatBefore, err := os.Stat(journalPath)
	if err != nil {
		t.Fatal(err)
	}

	// Mock input 'n\n' for cancel
	inBuf := bytes.NewBufferString("n\n")
	var outBuf bytes.Buffer

	err = runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-12", "--apply"}, inBuf, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("expected runCmd to complete without error on cancel")
	}

	output := outBuf.String()
	if !strings.Contains(output, "Cancelled. No files were modified.") {
		t.Errorf("expected cancel message, got: %s", output)
	}

	jStatAfter, err := os.Stat(journalPath)
	if err != nil {
		t.Fatal(err)
	}
	if jStatBefore.ModTime() != jStatAfter.ModTime() || jStatBefore.Size() != jStatAfter.Size() {
		t.Errorf("journal.tsv was mutated despite cancel")
	}
}

func TestPlanFinishPostCheckFailure(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	inBuf := bytes.NewBufferString("y\n")
	var outBuf bytes.Buffer

	// Stub out the post-check runner to return an error simulating BQN lint failure
	oldPostCheck := postCheckRunner
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		return postCheckResult{Command: "mocked-failed-lint", Output: "LINT FAIL: wrong role"}, fmt.Errorf("lint error")
	}
	defer func() { postCheckRunner = oldPostCheck }()

	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-12", "--apply"}, inBuf, &outBuf, os.Stderr)
	if err == nil {
		t.Fatal("expected runCmd to fail when post-check fails")
	}

	output := outBuf.String()
	if !strings.Contains(output, "Post-check failed.") {
		t.Errorf("expected 'Post-check failed.' in output, got: %s", output)
	}
	if !strings.Contains(output, "Restore suggestion:") {
		t.Errorf("expected restore instruction in output, got: %s", output)
	}
	if !strings.Contains(output, "LINT FAIL: wrong role") {
		t.Errorf("expected post-check tool output, got: %s", output)
	}

	// File must be written even if post-check fails (backup and restore suggestion are printed)
	journalBytes, err := os.ReadFile(journalPath)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(journalBytes), "plan-2026-01-10-phone") {
		t.Errorf("journal should still have been modified before post-check failed")
	}
}

func TestPlanFinishRejectsDoubleFinish(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	// Apply finish once
	inBuf := bytes.NewBufferString("y\n")
	var outBuf bytes.Buffer
	oldPostCheck := postCheckRunner
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		return postCheckResult{Command: "mocked"}, nil
	}
	defer func() { postCheckRunner = oldPostCheck }()

	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-12", "--apply"}, inBuf, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("first apply failed: %v", err)
	}

	// Try finishing the same plan_id again
	var outBuf2 bytes.Buffer
	err = runCmd([]string{"--base", tempDir, "plan", "finish", "--id", "plan-2026-01-10-phone", "--actual-date", "2026-01-12"}, nil, &outBuf2, os.Stderr)
	if err == nil {
		t.Fatal("expected double finish on same plan_id to be rejected")
	}
	if !strings.Contains(err.Error(), "already closed") {
		t.Errorf("expected already closed error, got: %v", err)
	}
}

func TestPlanListTSVFormat(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "list", "--format", "tsv"}, nil, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan list --format tsv failed: %v", err)
	}

	output := outBuf.String()
	lines := strings.Split(strings.TrimSpace(output), "\n")
	if len(lines) == 0 {
		t.Fatalf("expected rows, got empty output")
	}

	for _, line := range lines {
		parts := strings.Split(line, "\t")
		if len(parts) != 9 {
			t.Errorf("expected 9 tab-separated fields, got %d in line: %q", len(parts), line)
		}
		if parts[0] == "" {
			t.Errorf("expected non-empty number field")
		}
		if strings.Contains(line, "Unfulfilled phone") {
			if parts[1] != "plan-2026-01-10-phone" {
				t.Errorf("expected plan_id to be 'plan-2026-01-10-phone', got %q", parts[1])
			}
			if parts[7] != "" {
				t.Errorf("expected status to be empty (open plan), got %q", parts[7])
			}
			expectedDisplay := "1: 2026-01-10  Unfulfilled phone  assets:bank -> expenses:misc  1500"
			if parts[8] != expectedDisplay {
				t.Errorf("expected display field to be %q, got %q", expectedDisplay, parts[8])
			}
		}
	}
}

func TestPlanListInvalidFormat(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "list", "--format", "json"}, nil, &outBuf, os.Stderr)
	if err == nil {
		t.Fatalf("expected error for invalid format 'json'")
	}
	if !strings.Contains(err.Error(), "invalid format: json") {
		t.Errorf("expected error to contain 'invalid format: json', got: %v", err)
	}
}
