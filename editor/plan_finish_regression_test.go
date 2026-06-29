package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestPlanFinishFuturePlanUsesActualTodayAndClosesPlan(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	journalPath := filepath.Join(tempDir, "journal.tsv")
	planPath := filepath.Join(tempDir, "plan.tsv")

	const planID = "plan-2026-06-24-google-one"
	writeText(t, journalPath, strings.Join([]string{
		"2026-06-01\tOpening\tequity:opening-balances\tassets:bank\t100000",
		"",
	}, "\n"))
	writeText(t, planPath, strings.Join([]string{
		"2026-06-24\tgoogle-one\tassets:bank\texpenses:misc\t1450\tseries=google-one\tplan_id=" + planID,
		"",
	}, "\n"))

	oldNow := nowFunc
	nowFunc = func() time.Time { return time.Date(2026, 6, 23, 12, 0, 0, 0, time.Local) }
	defer func() { nowFunc = oldNow }()

	oldPostCheck := postCheckRunner
	postCheckRunner = runBQNPostCheck
	defer func() { postCheckRunner = oldPostCheck }()

	var out bytes.Buffer
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--id", planID, "--actual-date", "2026-06-23", "--apply"}, strings.NewReader("y\n"), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan finish future plan with actual today failed: %v\n%s", err, out.String())
	}

	journalBytes, err := os.ReadFile(journalPath)
	if err != nil {
		t.Fatal(err)
	}
	journal := string(journalBytes)
	expected := "2026-06-23\tgoogle-one\tassets:bank\texpenses:misc\t1450\tseries=google-one\tplan_id=" + planID
	if !strings.Contains(journal, expected) {
		t.Fatalf("journal.tsv does not contain actual-date row %q; got:\n%s", expected, journal)
	}
	for _, line := range strings.Split(strings.TrimSpace(journal), "\n") {
		if strings.HasPrefix(line, "2026-06-24\tgoogle-one\t") {
			t.Fatalf("journal.tsv contains future actual row; got:\n%s", journal)
		}
	}

	var listAll bytes.Buffer
	if err := runCmd([]string{"--base", tempDir, "plan", "list", "--all"}, nil, &listAll, os.Stderr); err != nil {
		t.Fatalf("plan list --all failed: %v", err)
	}
	if !strings.Contains(listAll.String(), "google-one") || !strings.Contains(listAll.String(), "[CLOSED]") {
		t.Fatalf("plan list --all did not mark plan as closed; got:\n%s", listAll.String())
	}

	var listOpen bytes.Buffer
	if err := runCmd([]string{"--base", tempDir, "plan", "list"}, nil, &listOpen, os.Stderr); err != nil {
		t.Fatalf("plan list failed: %v", err)
	}
	if strings.Contains(listOpen.String(), planID) || strings.Contains(listOpen.String(), "google-one") {
		t.Fatalf("closed plan remained in open plan list; got:\n%s", listOpen.String())
	}

	runBQNCommand(t, "src_next/report.bqn", tempDir)
}

func TestPlanFinishFuturePlanPromptUsesTodayAndClosesPlan(t *testing.T) {
	tempDir := setupTestDir(t, "plan-completion")
	journalPath := filepath.Join(tempDir, "journal.tsv")
	planPath := filepath.Join(tempDir, "plan.tsv")

	const planID = "plan-2026-06-24-google-one"
	writeText(t, journalPath, strings.Join([]string{
		"2026-06-01\tOpening\tequity:opening-balances\tassets:bank\t100000",
		"",
	}, "\n"))
	writeText(t, planPath, strings.Join([]string{
		"2026-06-24\tgoogle-one\tassets:bank\texpenses:misc\t1450\tseries=google-one\tplan_id=" + planID,
		"",
	}, "\n"))

	oldNow := nowFunc
	nowFunc = func() time.Time { return time.Date(2026, 6, 23, 12, 0, 0, 0, time.Local) }
	defer func() { nowFunc = oldNow }()

	oldPostCheck := postCheckRunner
	postCheckRunner = runBQNPostCheck
	defer func() { postCheckRunner = oldPostCheck }()

	var out bytes.Buffer
	// First "y" accepts Go's today prompt; second "y" confirms the append.
	err := runCmd([]string{"--base", tempDir, "plan", "finish", "--id", planID, "--apply"}, strings.NewReader("y\ny\n"), &out, os.Stderr)
	if err != nil {
		t.Fatalf("plan finish future plan via today prompt failed: %v\n%s", err, out.String())
	}
	if !strings.Contains(out.String(), "Use today's payment date (2026-06-23)?") {
		t.Fatalf("expected today prompt in output; got:\n%s", out.String())
	}

	journalBytes, err := os.ReadFile(journalPath)
	if err != nil {
		t.Fatal(err)
	}
	journal := string(journalBytes)
	expected := "2026-06-23\tgoogle-one\tassets:bank\texpenses:misc\t1450\tseries=google-one\tplan_id=" + planID
	if !strings.Contains(journal, expected) {
		t.Fatalf("journal.tsv does not contain prompted today row %q; got:\n%s", expected, journal)
	}
	if strings.Contains(journal, "2026-06-24\tgoogle-one\t") {
		t.Fatalf("journal.tsv contains future actual row; got:\n%s", journal)
	}

	var listAll bytes.Buffer
	if err := runCmd([]string{"--base", tempDir, "plan", "list", "--all"}, nil, &listAll, os.Stderr); err != nil {
		t.Fatalf("plan list --all failed: %v", err)
	}
	if !strings.Contains(listAll.String(), "google-one") || !strings.Contains(listAll.String(), "[CLOSED]") {
		t.Fatalf("plan list --all did not mark prompted plan as closed; got:\n%s", listAll.String())
	}

	runBQNCommand(t, "src_next/report.bqn", tempDir)
}

func runBQNCommand(t *testing.T, args ...string) {
	t.Helper()
	cmd := exec.Command("bqn", args...)
	cmd.Dir = ".."
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("bqn %s failed: %v\n%s", strings.Join(args, " "), err, string(output))
	}
}
