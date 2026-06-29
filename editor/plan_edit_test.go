package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPlanEditDryRunDoesNotModifyPlan(t *testing.T) {
	plan := "2026-07-01\tPhone\tassets:bank\texpenses:misc\t3000\tplan_id=plan-2026-07-01-phone\n"
	tempDir := setupMinimalPlanDir(t, plan)
	planPath := filepath.Join(tempDir, "plan.tsv")

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "edit", "--index", "1", "--date", "2026-07-05", "--amount", "3500", "--dry-run", "--post-check", "none"}, strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan edit --dry-run failed: %v", err)
	}
	got, err := os.ReadFile(planPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != plan {
		t.Fatalf("dry-run modified plan.tsv:\n%s", got)
	}
	output := out.String()
	if !strings.Contains(output, "Plan edit preview") || !strings.Contains(output, "- 2026-07-01") || !strings.Contains(output, "+ 2026-07-05") {
		t.Fatalf("expected diff preview, got:\n%s", output)
	}
}

func TestPlanEditYesUpdatesOnlySelectedRow(t *testing.T) {
	plan := strings.Join([]string{
		"# comment",
		"2026-07-01\tPhone\tassets:bank\texpenses:misc\t3000\tplan_id=plan-2026-07-01-phone",
		"2026-08-01\tFood\tassets:bank\texpenses:food\t1000\tplan_id=plan-2026-08-01-food",
		"",
	}, "\n")
	tempDir := setupMinimalPlanDir(t, plan)

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "edit", "--id", "plan-2026-07-01-phone", "--date", "2026-07-03", "--amount", "3333", "--yes", "--post-check", "none"}, strings.NewReader(""), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan edit failed: %v\n%s", err, out.String())
	}
	got, err := os.ReadFile(filepath.Join(tempDir, "plan.tsv"))
	if err != nil {
		t.Fatal(err)
	}
	want := strings.Join([]string{
		"# comment",
		"2026-07-03\tPhone\tassets:bank\texpenses:misc\t3333\tplan_id=plan-2026-07-01-phone",
		"2026-08-01\tFood\tassets:bank\texpenses:food\t1000\tplan_id=plan-2026-08-01-food",
		"",
	}, "\n")
	if string(got) != want {
		t.Fatalf("unexpected plan.tsv after edit:\nwant %q\ngot  %q", want, string(got))
	}
	if !strings.Contains(out.String(), "Backup:") || !strings.Contains(out.String(), "Post-check: skipped") {
		t.Fatalf("expected backup and post-check output, got:\n%s", out.String())
	}
}

func TestPlanEditRejectsClosedPlan(t *testing.T) {
	plan := "2026-07-01\tPhone\tassets:bank\texpenses:misc\t3000\tplan_id=plan-2026-07-01-phone\n"
	tempDir := setupMinimalPlanDir(t, plan)
	writeText(t, filepath.Join(tempDir, "journal.tsv"), "2026-07-01\tPhone\tassets:bank\texpenses:misc\t3000\tplan_id=plan-2026-07-01-phone\n")

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "edit", "--all", "--index", "1", "--date", "2026-07-03", "--dry-run"}, strings.NewReader(""), &out, os.Stderr)
	if err == nil || !strings.Contains(err.Error(), "cannot edit closed plan") {
		t.Fatalf("expected closed-plan error, got: %v", err)
	}
}
