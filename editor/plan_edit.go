package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"path/filepath"
	"strconv"
	"strings"
)

type planEditOptions struct {
	index     int
	planID    string
	date      string
	amount    string
	showAll   bool
	dryRun    bool
	yes       bool
	postCheck string
}

func runPlanEdit(args []string, opts options, in io.Reader, out io.Writer) error {
	editOpts, err := parsePlanEditOptions(args)
	if err != nil {
		return err
	}
	if editOpts.index == 0 && editOpts.planID == "" {
		return errors.New("must specify plan to edit using --index or --id")
	}
	if editOpts.date == "" && editOpts.amount == "" {
		return errors.New("must specify at least one of --date or --amount")
	}
	if editOpts.date != "" {
		if err := validateDate(editOpts.date); err != nil {
			return err
		}
	}
	if editOpts.amount != "" && !isInteger(editOpts.amount) {
		return fmt.Errorf("amount must be an integer: %s", editOpts.amount)
	}
	if err := validatePostCheckMode(editOpts.postCheck); err != nil {
		return err
	}

	baseAbs, err := filepath.Abs(opts.base)
	if err != nil {
		return fmt.Errorf("resolve base path: %w", err)
	}
	paths := ResolvePaths(baseAbs)

	accounts, err := LoadAccounts(paths.Accounts)
	if err != nil {
		return err
	}
	completedIDs, err := LoadCompletedPlanIDs(paths.Journal)
	if err != nil {
		return err
	}
	allRows, err := LoadPlans(paths.Plan, accounts, completedIDs)
	if err != nil {
		return err
	}

	rows := selectablePlanRows(allRows, editOpts.showAll)
	selected, err := selectPlanRow(rows, editOpts.index, editOpts.planID, editOpts.showAll)
	if err != nil {
		return err
	}
	if selected.Closed {
		return errors.New("cannot edit closed plan")
	}
	if selected.MissingID {
		return errors.New("cannot edit plan without plan_id")
	}
	if selected.InvalidID {
		return fmt.Errorf("cannot edit plan with invalid plan_id: %s", selected.PlanID)
	}

	oldFields := append([]string(nil), selected.Fields...)
	newFields := append([]string(nil), selected.Fields...)
	if editOpts.date != "" {
		newFields[0] = editOpts.date
	}
	if editOpts.amount != "" {
		newFields[4] = editOpts.amount
	}
	if strings.Join(oldFields, "\t") == strings.Join(newFields, "\t") {
		return errors.New("edit would not change the selected plan row")
	}

	snapshot, err := readRawFileSnapshot(paths.Plan)
	if err != nil {
		return err
	}
	oldLine := strings.Join(oldFields, "\t")
	newLine := strings.Join(newFields, "\t")
	proposed, err := replaceExactLine(snapshot.content, selected.LineNum, oldLine, newLine)
	if err != nil {
		return err
	}
	backupPath := chooseBackupPath(baseAbs, filepath.Base(paths.Plan), nowFunc())

	mode := "confirm"
	if editOpts.dryRun {
		mode = "dry-run"
	} else if editOpts.yes {
		mode = "yes"
	}
	printPlanEditPreview(out, paths.Plan, mode, editOpts.postCheck, backupPath, *selected, oldLine, newLine)

	if editOpts.dryRun {
		fmt.Fprintln(out, "Dry-run only. No files were modified.")
		return nil
	}
	if !editOpts.yes {
		confirmed, err := confirmPlanEdit(in, out)
		if err != nil {
			return err
		}
		if !confirmed {
			fmt.Fprintln(out, "Cancelled. No files were modified.")
			return nil
		}
	}

	if err := writeSingleFileAtomic(snapshot, proposed, backupPath); err != nil {
		return err
	}
	fmt.Fprintf(out, "Wrote: %s\n", paths.Plan)
	fmt.Fprintf(out, "Backup: %s\n", backupPath)

	if editOpts.postCheck == "none" {
		fmt.Fprintln(out, "Post-check: skipped")
		return nil
	}
	result, err := postCheckRunner(baseAbs, editOpts.postCheck)
	if result.Command != "" {
		fmt.Fprintf(out, "Post-check command: %s\n", result.Command)
	}
	if err != nil {
		fmt.Fprintln(out, "Post-check failed.")
		fmt.Fprintf(out, "Source: %s\n", paths.Plan)
		fmt.Fprintf(out, "Backup: %s\n", backupPath)
		fmt.Fprintf(out, "Restore suggestion: cp %q %q\n", backupPath, paths.Plan)
		if result.Output != "" {
			fmt.Fprintln(out, result.Output)
		}
		return fmt.Errorf("post-write check failed: %w", err)
	}
	fmt.Fprintln(out, "Post-check: OK")
	return nil
}

func parsePlanEditOptions(args []string) (planEditOptions, error) {
	opts := planEditOptions{postCheck: "lint"}
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--index":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			n, err := strconv.Atoi(value)
			if err != nil || n < 1 {
				return opts, fmt.Errorf("invalid index value: %s", value)
			}
			opts.index = n
			i = next
		case "--id":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.planID = value
			i = next
		case "--date":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.date = value
			i = next
		case "--amount":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.amount = value
			i = next
		case "--all":
			opts.showAll = true
		case "--dry-run":
			opts.dryRun = true
		case "--yes":
			opts.yes = true
		case "--post-check":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.postCheck = value
			i = next
		default:
			return opts, fmt.Errorf("unknown edit option: %s", args[i])
		}
	}
	return opts, nil
}

func selectablePlanRows(allRows []PlanRow, showAll bool) []PlanRow {
	if showAll {
		rows := append([]PlanRow(nil), allRows...)
		for i := range rows {
			rows[i].Number = i + 1
		}
		return rows
	}
	rows := []PlanRow{}
	num := 1
	for _, r := range allRows {
		if !r.Closed {
			r.Number = num
			rows = append(rows, r)
			num++
		}
	}
	return rows
}

func selectPlanRow(rows []PlanRow, index int, planID string, showAll bool) (*PlanRow, error) {
	if index > 0 {
		if index < 1 || index > len(rows) {
			return nil, fmt.Errorf("invalid plan index: %d (available: 1-%d)", index, len(rows))
		}
		return &rows[index-1], nil
	}
	for i := range rows {
		if rows[i].PlanID == planID {
			return &rows[i], nil
		}
	}
	if showAll {
		return nil, fmt.Errorf("plan_id not found: %s", planID)
	}
	return nil, fmt.Errorf("plan_id not found or already closed: %s", planID)
}

func replaceExactLine(content []byte, lineNum int, oldLine string, newLine string) ([]byte, error) {
	if lineNum < 1 {
		return nil, fmt.Errorf("invalid line number: %d", lineNum)
	}
	text := string(content)
	parts := strings.SplitAfter(text, "\n")
	if lineNum > len(parts) || (lineNum == len(parts) && parts[lineNum-1] == "") {
		return nil, fmt.Errorf("line %d not found", lineNum)
	}
	idx := lineNum - 1
	lineWithEnding := parts[idx]
	ending := ""
	line := lineWithEnding
	if strings.HasSuffix(line, "\n") {
		ending = "\n"
		line = strings.TrimSuffix(line, "\n")
	}
	if strings.HasSuffix(line, "\r") {
		line = strings.TrimSuffix(line, "\r")
		ending = "\r" + ending
	}
	if line != oldLine {
		return nil, fmt.Errorf("line %d changed during edit; refusing to rewrite a different row", lineNum)
	}
	parts[idx] = newLine + ending
	return []byte(strings.Join(parts, "")), nil
}

func printPlanEditPreview(out io.Writer, target string, mode string, postCheck string, backupPath string, row PlanRow, oldLine string, newLine string) {
	fmt.Fprintln(out, "Plan edit preview")
	fmt.Fprintf(out, "Target: %s\n", target)
	fmt.Fprintf(out, "Line: %d\n", row.LineNum)
	fmt.Fprintf(out, "Plan ID: %s\n", row.PlanID)
	fmt.Fprintf(out, "Mode: %s\n", mode)
	fmt.Fprintf(out, "Post-check: %s\n", postCheck)
	fmt.Fprintf(out, "Backup: %s\n", backupPath)
	fmt.Fprintln(out, "Diff:")
	fmt.Fprintf(out, "- %s\n", oldLine)
	fmt.Fprintf(out, "+ %s\n", newLine)
}

func confirmPlanEdit(in io.Reader, out io.Writer) (bool, error) {
	fmt.Fprint(out, "Rewrite this plan row? [y/N]: ")
	reader := bufio.NewReader(in)
	text, err := reader.ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return false, err
	}
	answer := strings.ToLower(strings.TrimSpace(text))
	return answer == "y" || answer == "yes", nil
}
