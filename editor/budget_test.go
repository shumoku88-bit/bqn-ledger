package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func setupMinimalBudgetDir(t *testing.T, budgetContent string) string {
	t.Helper()
	tempDir := t.TempDir()
	writeText(t, filepath.Join(tempDir, "accounts.tsv"), strings.Join([]string{
		"budget:opening\tkind=opening",
		"budget:unassigned\tkind=unassigned",
		"budget:daily\tkind=envelope",
		"budget:flex\tkind=envelope",
		"budget:reserve\tkind=envelope",
		"",
	}, "\n"))
	writeText(t, filepath.Join(tempDir, "budget_alloc.tsv"), budgetContent)
	return tempDir
}

func budgetAddArgs(extra ...string) []string {
	args := []string{
		"--date", "2026-06-19",
		"--memo", "alloc",
		"--from", "budget:unassigned",
		"--to", "budget:daily",
		"--amount", "1000",
	}
	return append(args, extra...)
}

func TestBudgetAddDryRunDoesNotMutate(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalBudgetDir(t, "2026-06-18\talloc\tbudget:unassigned\tbudget:flex\t500\n")
	budgetPath := filepath.Join(tempDir, "budget_alloc.tsv")
	before := readText(t, budgetPath)

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "budget", "add"}, budgetAddArgs("--meta", "note=dry", "--dry-run")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("budget add --dry-run failed: %v", err)
	}

	if after := readText(t, budgetPath); after != before {
		t.Fatalf("dry-run mutated budget_alloc.tsv\nbefore=%q\nafter=%q", before, after)
	}
	output := out.String()
	if !strings.Contains(output, "Budget allocation append preview") || !strings.Contains(output, "Mode: dry-run") || !strings.Contains(output, "Post-check: lint") {
		t.Fatalf("preview missing required fields: %s", output)
	}
	if !strings.Contains(output, "2026-06-19\talloc\tbudget:unassigned\tbudget:daily\t1000\tnote=dry") {
		t.Fatalf("preview missing exact TSV row: %s", output)
	}
}

func TestBudgetAddAppendCreatesBudgetBackup(t *testing.T) {
	resetJournalGlobals(t)
	original := "2026-06-18\talloc\tbudget:unassigned\tbudget:flex\t500\n"
	tempDir := setupMinimalBudgetDir(t, original)
	budgetPath := filepath.Join(tempDir, "budget_alloc.tsv")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "budget", "add"}, budgetAddArgs("--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("budget add failed: %v", err)
	}

	expected := original + "2026-06-19\talloc\tbudget:unassigned\tbudget:daily\t1000\n"
	if got := readText(t, budgetPath); got != expected {
		t.Fatalf("unexpected budget_alloc content\nwant=%q\n got=%q", expected, got)
	}
	backupPath := filepath.Join(tempDir, ".backup", "20260619-123456", "budget_alloc.tsv")
	if got := readText(t, backupPath); got != original {
		t.Fatalf("budget backup content mismatch\nwant=%q\n got=%q", original, got)
	}
	if strings.Contains(out.String(), "journal.tsv") {
		t.Fatalf("budget add output referenced journal.tsv unexpectedly: %s", out.String())
	}
}

func TestBudgetAddValidationRejectsUnknownBudgetAccount(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalBudgetDir(t, "")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "budget", "add"}, budgetAddArgs("--to", "budget:missing", "--dry-run")...), strings.NewReader(""), &out, os.Stderr)
	if err == nil {
		t.Fatalf("expected unknown account validation error")
	}
	if !strings.Contains(err.Error(), "unknown to account") {
		t.Fatalf("expected unknown to account error, got: %v", err)
	}
}

func TestBudgetAddDefaultPostCheckInvoked(t *testing.T) {
	resetJournalGlobals(t)
	tempDir := setupMinimalBudgetDir(t, "")
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
	err := runCmd(append([]string{"--base", tempDir, "budget", "add"}, budgetAddArgs("--yes")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("budget add failed: %v", err)
	}
	if !called {
		t.Fatalf("post-check runner was not called")
	}
	if !strings.Contains(out.String(), "Post-check command: fake lint") || !strings.Contains(out.String(), "Post-check: OK") {
		t.Fatalf("missing post-check output: %s", out.String())
	}
}
