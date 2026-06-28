package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type issueAddOptions struct {
	date   string
	status string
	title  string
	amount string
	memo   string
	dryRun bool
	yes    bool
}

func runIssueAdd(args []string, opts options, in io.Reader, out io.Writer) error {
	addOpts, err := parseIssueAddOptions(args)
	if err != nil {
		return err
	}

	baseAbs, err := filepath.Abs(opts.base)
	if err != nil {
		return fmt.Errorf("resolve base path: %w", err)
	}

	// Validate options
	if err := validateIssueAddOptions(&addOpts); err != nil {
		return err
	}

	issuesPath := filepath.Join(baseAbs, "issues.tsv")

	// Read existing or create new snapshot
	var snapshot rawFileSnapshot
	if _, err := os.Stat(issuesPath); os.IsNotExist(err) {
		// File does not exist, initialize with header
		header := []byte("date\tstatus\ttitle\tamount\tmemo\n")
		snapshot = rawFileSnapshot{
			path:    issuesPath,
			content: header,
			mode:    0644,
			size:    int64(len(header)),
			sha256:  "", // dummy sha
		}
	} else {
		snapshot, err = readRawFileSnapshot(issuesPath)
		if err != nil {
			return err
		}
	}

	// Build row content
	row := []string{addOpts.date, addOpts.status, addOpts.title, addOpts.amount, addOpts.memo}
	proposed := appendRowContent(snapshot.content, row)

	// Output dry run or print proposed change
	if addOpts.dryRun {
		fmt.Fprintln(out, "Proposed row:")
		fmt.Fprintln(out, strings.Join(row, "\t"))
		fmt.Fprintln(out, "(Dry-run mode, no changes saved)")
		return nil
	}

	// Print proposed changes and confirm
	fmt.Fprintf(out, "File: %s\n", issuesPath)
	fmt.Fprintln(out, "Proposed row:")
	fmt.Fprintln(out, strings.Join(row, "\t"))

	if !addOpts.yes {
		ok, err := confirmAppend(in, out)
		if err != nil {
			return err
		}
		if !ok {
			return errors.New("aborted by user")
		}
	}

	// Atomic write (backup and atomic swap)
	if snapshot.sha256 == "" {
		// New file: no backup needed, no checkStale needed.
		// Just write atomically using temp file and rename.
		dir := filepath.Dir(issuesPath)
		base := filepath.Base(issuesPath)
		tmp, err := os.CreateTemp(dir, "."+base+".tmp-*")
		if err != nil {
			return fmt.Errorf("create temp file: %w", err)
		}
		tmpPath := tmp.Name()
		cleanup := true
		defer func() {
			if cleanup {
				_ = os.Remove(tmpPath)
			}
		}()

		if _, err := tmp.Write(proposed); err != nil {
			_ = tmp.Close()
			return fmt.Errorf("write temp file: %w", err)
		}
		if err := tmp.Chmod(snapshot.mode.Perm()); err != nil {
			_ = tmp.Close()
			return fmt.Errorf("chmod temp file: %w", err)
		}
		if err := tmp.Sync(); err != nil {
			_ = tmp.Close()
			return fmt.Errorf("sync temp file: %w", err)
		}
		if err := tmp.Close(); err != nil {
			return fmt.Errorf("close temp file: %w", err)
		}
		if err := os.Rename(tmpPath, issuesPath); err != nil {
			return fmt.Errorf("rename temp file to %s: %w", issuesPath, err)
		}
		cleanup = false
	} else {
		backupDir := filepath.Join(baseAbs, ".backup")
		timestamp := nowFunc().Format("20060102150405")
		backupPath := filepath.Join(backupDir, "issues.tsv."+timestamp+".bak")

		if err := writeSingleFileAtomic(snapshot, proposed, backupPath); err != nil {
			return err
		}
	}

	fmt.Fprintln(out, "OK: Issue row appended.")
	return nil
}

func parseIssueAddOptions(args []string) (issueAddOptions, error) {
	opts := issueAddOptions{
		status: "open",
		amount: "0",
	}

	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--date":
			val, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.date = val
			i = next
		case "--status":
			val, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.status = val
			i = next
		case "--title":
			val, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.title = val
			i = next
		case "--amount":
			val, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.amount = val
			i = next
		case "--memo":
			val, next, err := optionValueAllowEmpty(args, i)
			if err != nil {
				return opts, err
			}
			opts.memo = val
			i = next
		case "--dry-run":
			opts.dryRun = true
		case "--yes":
			opts.yes = true
		default:
			return opts, fmt.Errorf("unknown option: %s", args[i])
		}
	}
	return opts, nil
}

func validateIssueAddOptions(opts *issueAddOptions) error {
	// 1. Date validation
	if opts.date == "" {
		opts.date = nowFunc().Format("2006-01-02")
	} else {
		_, err := time.Parse("2006-01-02", opts.date)
		if err != nil {
			return fmt.Errorf("invalid date format (expected YYYY-MM-DD): %s", opts.date)
		}
	}

	// 2. Status validation
	switch opts.status {
	case "open", "resolved", "dropped":
		// ok
	default:
		return fmt.Errorf("invalid status: %s (expected 'open', 'resolved', or 'dropped')", opts.status)
	}

	// 3. Title validation
	if opts.title == "" {
		return errors.New("title is required")
	}
	if containsTabOrNewline(opts.title) {
		return errors.New("title must not contain TAB or newline")
	}

	// 4. Amount validation
	if !isInteger(opts.amount) {
		return fmt.Errorf("amount must be an integer: %s", opts.amount)
	}

	// 5. Memo validation
	if containsTabOrNewline(opts.memo) {
		return errors.New("memo must not contain TAB or newline")
	}

	return nil
}
