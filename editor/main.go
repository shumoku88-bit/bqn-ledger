package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"time"
)

type options struct {
	base       string
	index      int
	planID     string
	actualDate string
	showAll    bool
	apply      bool
	format     string
}

func main() {
	if err := runCmd(os.Args[1:], os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "ERROR:", err)
		os.Exit(2)
	}
}

func runCmd(args []string, in io.Reader, out io.Writer, errOut io.Writer) error {
	opts := options{base: LoadSystemDefaults().BaseDir}
	var remainingArgs []string

	for i := 0; i < len(args); i++ {
		if args[i] == "--base" {
			if i+1 >= len(args) {
				return errors.New("missing value for --base")
			}
			opts.base = args[i+1]
			i++
		} else {
			remainingArgs = append(remainingArgs, args[i])
		}
	}

	if len(remainingArgs) == 0 {
		printHelp(errOut)
		return errors.New("command is required")
	}

	cmd := remainingArgs[0]
	cmdArgs := remainingArgs[1:]

	switch cmd {
	case "help":
		return printHelp(out)
	case "journal":
		if len(cmdArgs) < 1 {
			return errors.New("journal subcommand is required ('add' or 'reverse')")
		}
		switch cmdArgs[0] {
		case "add":
			return runJournalAdd(cmdArgs[1:], opts, in, out)
		case "reverse":
			return runJournalReverse(cmdArgs[1:], opts, in, out)
		default:
			return fmt.Errorf("unknown journal subcommand: %s (expected 'add' or 'reverse')", cmdArgs[0])
		}
	case "budget":
		if len(cmdArgs) < 1 || cmdArgs[0] != "add" {
			return errors.New("unknown budget subcommand (expected 'add')")
		}
		return runBudgetAdd(cmdArgs[1:], opts, in, out)
	case "issue":
		if len(cmdArgs) < 1 || cmdArgs[0] != "add" {
			return errors.New("unknown issue subcommand (expected 'add')")
		}
		return runIssueAdd(cmdArgs[1:], opts, in, out)
	case "plan":
		if len(cmdArgs) < 1 {
			return errors.New("plan subcommand is required ('list', 'add', 'finish', or 'edit')")
		}
		switch cmdArgs[0] {
		case "list":
			return runPlanList(cmdArgs[1:], opts, out)
		case "add":
			return runPlanAdd(cmdArgs[1:], opts, in, out)
		case "finish":
			return runPlanFinish(cmdArgs[1:], opts, in, out)
		case "edit":
			return runPlanEdit(cmdArgs[1:], opts, in, out)
		default:
			return fmt.Errorf("unknown plan subcommand: %s", cmdArgs[0])
		}
	default:
		printHelp(errOut)
		return fmt.Errorf("unknown command: %s", cmd)
	}
}

func printHelp(out io.Writer) error {
	helpText := fmt.Sprintf(`Go Source TSV Editor
Usage:
  tools/edit [--base <dir>] <command> [options]

Commands:
  journal add --date <date> --memo <memo> --from <account> --to <account> --amount <amount> [--meta key=value] [--dry-run] [--yes] [--post-check lint|none|full]
  journal reverse --id <txn_id> [--date <date>] | --index <number> [--date <date>]
  budget add --date <date> --memo <memo> --from <account> --to <account> --amount <amount> [--meta key=value] [--dry-run] [--yes] [--post-check lint|none|full]
  plan list [--all] [--format <tsv|text>]
  plan add --date <date> --memo <memo> --from <account> --to <account> --amount <amount> [--meta key=value] [--id <plan_id>] [--dry-run] [--yes] [--post-check lint|none|full]
  plan finish [--index <number>] [--id <plan_id>] [--actual-date <date>] [--apply]
  plan edit [--index <number>] [--id <plan_id>] [--date <date>] [--amount <amount>] [--dry-run] [--yes] [--post-check lint|none|full]
  issue add --date <date> --status <status> --title <title> --amount <amount> --memo <memo> [--dry-run] [--yes]


Global Options:
  --base <dir>    Base directory of datasets (default: %q)
`, LoadSystemDefaults().BaseDir)
	_, err := fmt.Fprint(out, helpText)
	return err
}

func runPlanList(args []string, opts options, out io.Writer) error {
	for i := 0; i < len(args); i++ {
		if args[i] == "--all" {
			opts.showAll = true
		} else if args[i] == "--format" {
			if i+1 >= len(args) {
				return errors.New("missing value for --format")
			}
			f := args[i+1]
			if f != "tsv" && f != "text" {
				return fmt.Errorf("invalid format: %s (expected 'tsv' or 'text')", f)
			}
			opts.format = f
			i++
		} else {
			return fmt.Errorf("unknown list argument: %s", args[i])
		}
	}

	paths := ResolvePaths(opts.base)
	accountsPath := paths.Accounts
	journalPath := paths.Journal
	planPath := paths.Plan

	accounts, err := LoadAccounts(accountsPath)
	if err != nil {
		return err
	}

	completedIDs, err := LoadCompletedPlanIDs(journalPath)
	if err != nil {
		return err
	}

	allRows, err := LoadPlans(planPath, accounts, completedIDs)
	if err != nil {
		return err
	}

	var rows []PlanRow
	if opts.showAll {
		rows = allRows
		for i := range rows {
			rows[i].Number = i + 1
		}
	} else {
		num := 1
		for _, r := range allRows {
			if !r.Closed {
				r.Number = num
				rows = append(rows, r)
				num++
			}
		}
	}

	if opts.format == "tsv" {
		printRowsTSV(out, rows)
	} else {
		printRows(out, rows)
	}
	return nil
}

func printRows(out io.Writer, rows []PlanRow) {
	fmt.Fprintln(out, "Plan rows:")
	for _, r := range rows {
		status := ""
		if r.Closed {
			status = " [CLOSED]"
		} else if r.MissingID {
			status = " [MISSING-ID]"
		} else if r.InvalidID {
			status = " [INVALID-ID]"
		}

		fields := r.Fields
		fmt.Fprintf(
			out,
			"%d: %s\t%s\t%s -> %s\t%s%s\n",
			r.Number,
			fields[0],
			fields[1],
			fields[2],
			fields[3],
			fields[4],
			status,
		)
	}
}

func printRowsTSV(out io.Writer, rows []PlanRow) {
	for _, r := range rows {
		statusTSV := ""
		statusDisplay := ""
		if r.Closed {
			statusTSV = "CLOSED"
			statusDisplay = " [CLOSED]"
		} else if r.MissingID {
			statusTSV = "MISSING-ID"
			statusDisplay = " [MISSING-ID]"
		} else if r.InvalidID {
			statusTSV = "INVALID-ID"
			statusDisplay = " [INVALID-ID]"
		}

		fields := r.Fields
		// human-readable output display (tab replaced with spaces)
		display := fmt.Sprintf(
			"%d: %s  %s  %s -> %s  %s%s",
			r.Number,
			fields[0],
			fields[1],
			fields[2],
			fields[3],
			fields[4],
			statusDisplay,
		)

		fmt.Fprintf(
			out,
			"%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			r.Number,
			r.PlanID,
			fields[0],
			fields[1],
			fields[2],
			fields[3],
			fields[4],
			statusTSV,
			display,
		)
	}
}

func promptPlanFinishActualDate(reader *bufio.Reader, out io.Writer) (string, error) {
	today := nowFunc().Format("2006-01-02")

	for {
		fmt.Fprintf(out, "Use today's payment date (%s)? [Y/n]: ", today)
		answer, err := reader.ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return "", err
		}
		switch strings.ToLower(strings.TrimSpace(answer)) {
		case "", "y", "yes":
			return today, nil
		case "n", "no":
			for {
				fmt.Fprint(out, "Payment date (YYYY-MM-DD, today or earlier): ")
				input, err := reader.ReadString('\n')
				if err != nil && !errors.Is(err, io.EOF) {
					return "", err
				}
				input = strings.TrimSpace(input)
				if input == "" {
					fmt.Fprintln(out, "Payment date is required.")
					continue
				}
				if err := validatePlanFinishActualDate(input); err != nil {
					fmt.Fprintln(out, err)
					continue
				}
				return input, nil
			}
		default:
			fmt.Fprintln(out, "Please answer y or n.")
		}
	}
}

func validatePlanFinishActualDate(actualDate string) error {
	if err := validateDate(actualDate); err != nil {
		return err
	}
	now := nowFunc()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	parsed, err := time.ParseInLocation("2006-01-02", actualDate, now.Location())
	if err != nil {
		return fmt.Errorf("invalid actual date format (expected YYYY-MM-DD): %w", err)
	}
	if parsed.After(today) {
		return fmt.Errorf("payment date cannot be in the future: %s", actualDate)
	}
	return nil
}

func runPlanFinish(args []string, opts options, in io.Reader, out io.Writer) error {
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--index":
			if i+1 >= len(args) {
				return errors.New("missing value for --index")
			}
			idx, err := strconv.Atoi(args[i+1])
			if err != nil {
				return fmt.Errorf("invalid index value: %s", args[i+1])
			}
			opts.index = idx
			i++
		case "--id":
			if i+1 >= len(args) {
				return errors.New("missing value for --id")
			}
			opts.planID = args[i+1]
			i++
		case "--actual-date":
			if i+1 >= len(args) {
				return errors.New("missing value for --actual-date")
			}
			opts.actualDate = args[i+1]
			i++
		case "--all":
			opts.showAll = true
		case "--apply":
			opts.apply = true
		default:
			return fmt.Errorf("unknown finish option: %s", args[i])
		}
	}

	if opts.index == 0 && opts.planID == "" {
		return errors.New("must specify plan to finish using --index or --id")
	}

	paths := ResolvePaths(opts.base)
	accountsPath := paths.Accounts
	journalPath := paths.Journal
	planPath := paths.Plan

	accounts, err := LoadAccounts(accountsPath)
	if err != nil {
		return err
	}

	completedIDs, err := LoadCompletedPlanIDs(journalPath)
	if err != nil {
		return err
	}

	allRows, err := LoadPlans(planPath, accounts, completedIDs)
	if err != nil {
		return err
	}

	var rows []PlanRow
	if opts.showAll {
		rows = allRows
		for i := range rows {
			rows[i].Number = i + 1
		}
	} else {
		num := 1
		for _, r := range allRows {
			if !r.Closed {
				r.Number = num
				rows = append(rows, r)
				num++
			}
		}
	}

	var selected *PlanRow
	if opts.index > 0 {
		if opts.index < 1 || opts.index > len(rows) {
			return fmt.Errorf("invalid plan index: %d (available: 1-%d)", opts.index, len(rows))
		}
		selected = &rows[opts.index-1]
	} else if opts.planID != "" {
		for i := range rows {
			if rows[i].PlanID == opts.planID {
				selected = &rows[i]
				break
			}
		}
		if selected == nil {
			return fmt.Errorf("plan_id not found or already closed: %s", opts.planID)
		}
	}

	if selected.Closed {
		return fmt.Errorf("plan is already closed")
	}
	if selected.MissingID {
		return errors.New("cannot finish plan without plan_id")
	}
	if selected.InvalidID {
		return fmt.Errorf("cannot finish plan with invalid plan_id: %s", selected.PlanID)
	}

	inputReader := bufio.NewReader(in)

	actualDate := opts.actualDate
	if actualDate == "" {
		var err error
		actualDate, err = promptPlanFinishActualDate(inputReader, out)
		if err != nil {
			return err
		}
	}
	if err := validatePlanFinishActualDate(actualDate); err != nil {
		return err
	}

	candidate := JournalCandidate(*selected, actualDate)

	addOpts := journalLikeAddOptions{
		date:      candidate[0],
		memo:      candidate[1],
		from:      candidate[2],
		to:        candidate[3],
		amount:    candidate[4],
		meta:      candidate[5:],
		dryRun:    !opts.apply,
		yes:       false,
		postCheck: "lint",
	}

	return appendJournalLikeRow(opts.base, "journal.tsv", "Journal (from plan)", "Journal row", addOpts, inputReader, out)
}
