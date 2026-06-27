package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func planAddArgs(extra ...string) []string {
	args := []string{
		"--date", "2026-07-01",
		"--memo", "Google One",
		"--from", "assets:bank",
		"--to", "expenses:misc",
		"--amount", "1450",
	}
	return append(args, extra...)
}

func TestPlanAddDryRunDoesNotModifyPlan(t *testing.T) {
	tempDir := setupMinimalPlanDir(t, "")
	planPath := filepath.Join(tempDir, "plan.tsv")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "plan", "add"}, planAddArgs("--meta", "series=google-one", "--dry-run", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan add --dry-run failed: %v", err)
	}
	got, err := os.ReadFile(planPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != "" {
		t.Fatalf("dry-run modified plan.tsv: %q", string(got))
	}
	output := out.String()
	if !strings.Contains(output, "Plan append preview") || !strings.Contains(output, "plan_id=plan-2026-07-01-google-one") {
		t.Fatalf("expected plan append preview with generated plan_id, got:\n%s", output)
	}
}

func TestPlanAddYesAppendsWithGeneratedPlanID(t *testing.T) {
	tempDir := setupMinimalPlanDir(t, "")
	planPath := filepath.Join(tempDir, "plan.tsv")

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "plan", "add"}, planAddArgs("--meta", "series=google-one", "--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan add failed: %v\n%s", err, out.String())
	}
	got, err := os.ReadFile(planPath)
	if err != nil {
		t.Fatal(err)
	}
	expected := "2026-07-01\tGoogle One\tassets:bank\texpenses:misc\t1450\tseries=google-one\tplan_id=plan-2026-07-01-google-one\n"
	if string(got) != expected {
		t.Fatalf("unexpected plan.tsv after add:\nwant %q\ngot  %q", expected, string(got))
	}
}

func TestPlanAddDuplicatePlanIDGetsSuffix(t *testing.T) {
	existing := "2026-07-01\tGoogle One\tassets:bank\texpenses:misc\t1450\tseries=google-one\tplan_id=plan-2026-07-01-google-one\n"
	tempDir := setupMinimalPlanDir(t, existing)

	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "plan", "add"}, planAddArgs("--meta", "series=google-one", "--yes", "--post-check", "none")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan add duplicate failed: %v\n%s", err, out.String())
	}
	got, err := os.ReadFile(filepath.Join(tempDir, "plan.tsv"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(got), "plan_id=plan-2026-07-01-google-one-02") {
		t.Fatalf("expected duplicate suffix -02, got:\n%s", string(got))
	}
}

func TestPlanAddRejectsUnknownAccount(t *testing.T) {
	tempDir := setupMinimalPlanDir(t, "")
	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "plan", "add"}, planAddArgs("--from", "assets:missing", "--dry-run")...), strings.NewReader(""), &out, os.Stderr)
	if err == nil || !strings.Contains(err.Error(), "unknown from account") {
		t.Fatalf("expected unknown account error, got: %v", err)
	}
}

func TestPlanAddRejectsInvalidInputs(t *testing.T) {
	tests := []struct {
		name      string
		extra     []string
		wantError string
	}{
		{name: "invalid date", extra: []string{"--date", "2026-02-30"}, wantError: "invalid date"},
		{name: "invalid amount", extra: []string{"--amount", "14.50"}, wantError: "amount must be an integer"},
		{name: "invalid meta", extra: []string{"--meta", "badmeta"}, wantError: "invalid metadata token"},
		{name: "explicit plan_id meta", extra: []string{"--meta", "plan_id=plan-2026-07-01-google-one"}, wantError: "--meta plan_id"},
		{name: "duplicate explicit id", extra: []string{"--id", "plan-2026-07-01-google-one"}, wantError: "plan_id already exists"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			plan := ""
			if tt.name == "duplicate explicit id" {
				plan = "2026-07-01\tGoogle One\tassets:bank\texpenses:misc\t1450\tplan_id=plan-2026-07-01-google-one\n"
			}
			tempDir := setupMinimalPlanDir(t, plan)
			var out bytes.Buffer
			err := runCmd(append([]string{"--base", tempDir, "plan", "add"}, planAddArgs(append(tt.extra, "--dry-run")...)...), strings.NewReader(""), &out, os.Stderr)
			if err == nil || !strings.Contains(err.Error(), tt.wantError) {
				t.Fatalf("expected error containing %q, got: %v", tt.wantError, err)
			}
		})
	}
}

func TestPlanAddPostCheckLintPasses(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	var out bytes.Buffer
	err := runCmd(append([]string{"--base", tempDir, "plan", "add"}, planAddArgs("--date", "2026-01-26", "--memo", "Extra plan", "--meta", "series=extra-plan", "--yes")...), strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan add with post-check lint failed: %v\n%s", err, out.String())
	}
	if !strings.Contains(out.String(), "Post-check: OK") {
		t.Fatalf("expected post-check OK, got:\n%s", out.String())
	}
}
