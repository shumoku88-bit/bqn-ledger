package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func resetPlanFinishPromptGlobals(t *testing.T, now time.Time) {
	t.Helper()
	oldNow := nowFunc
	oldPostCheck := postCheckRunner
	t.Cleanup(func() {
		nowFunc = oldNow
		postCheckRunner = oldPostCheck
	})
	nowFunc = func() time.Time { return now }
	postCheckRunner = func(base string, mode string) (postCheckResult, error) {
		return postCheckResult{Command: "mocked " + mode}, nil
	}
}

func TestPlanFinishPromptsForTodayDate(t *testing.T) {
	resetPlanFinishPromptGlobals(t, time.Date(2026, 1, 12, 9, 0, 0, 0, time.Local))
	tempDir := setupTestDir(t, "plan-completion")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	inBuf := bytes.NewBufferString("y\ny\n")
	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--apply"}, inBuf, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan finish failed: %v\n%s", err, outBuf.String())
	}

	journalContent := readText(t, journalPath)
	expectedRow := "2026-01-12\tUnfulfilled phone\tassets:bank\texpenses:misc\t1500\tplan_id=plan-2026-01-10-phone"
	if !strings.Contains(journalContent, expectedRow) {
		t.Fatalf("expected journal to contain today-date row, got:\n%s", journalContent)
	}
	if !strings.Contains(outBuf.String(), "Use today's payment date") {
		t.Fatalf("expected prompt for today's payment date, got:\n%s", outBuf.String())
	}
}

func TestPlanFinishPromptsForPastDate(t *testing.T) {
	resetPlanFinishPromptGlobals(t, time.Date(2026, 1, 12, 9, 0, 0, 0, time.Local))
	tempDir := setupTestDir(t, "plan-completion")
	journalPath := filepath.Join(tempDir, "journal.tsv")

	inBuf := bytes.NewBufferString("n\n2026-01-11\ny\n")
	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--apply"}, inBuf, &outBuf, os.Stderr)
	if err != nil {
		t.Fatalf("runCmd plan finish failed: %v\n%s", err, outBuf.String())
	}

	journalContent := readText(t, journalPath)
	expectedRow := "2026-01-11\tUnfulfilled phone\tassets:bank\texpenses:misc\t1500\tplan_id=plan-2026-01-10-phone"
	if !strings.Contains(journalContent, expectedRow) {
		t.Fatalf("expected journal to contain past-date row, got:\n%s", journalContent)
	}
	if !strings.Contains(outBuf.String(), "Payment date (YYYY-MM-DD, today or earlier)") {
		t.Fatalf("expected prompt for past payment date, got:\n%s", outBuf.String())
	}
}

func TestPlanFinishRejectsFutureActualDate(t *testing.T) {
	resetPlanFinishPromptGlobals(t, time.Date(2026, 1, 12, 9, 0, 0, 0, time.Local))
	tempDir := setupTestDir(t, "plan-completion")

	var outBuf bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--index", "1", "--actual-date", "2026-01-13"}, bytes.NewBufferString(""), &outBuf, os.Stderr)
	if err == nil {
		t.Fatal("expected future actual date to be rejected")
	}
	if !strings.Contains(err.Error(), "payment date cannot be in the future") {
		t.Fatalf("expected future-date error, got: %v", err)
	}
}
