package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type journalLikeAddOptions struct {
	date      string
	memo      string
	from      string
	to        string
	amount    string
	meta      []string
	dryRun    bool
	yes       bool
	postCheck string
}

type rawFileSnapshot struct {
	path    string
	content []byte
	mode    os.FileMode
	size    int64
	modTime time.Time
	sha256  string
}

type postCheckResult struct {
	Command string
	Output  string
}

var nowFunc = time.Now
var beforeJournalReplaceHook func(string) error
var postCheckRunner = runBQNPostCheck

func runJournalAdd(args []string, opts options, in io.Reader, out io.Writer) error {
	addOpts, err := parseJournalLikeAddOptions(args, "journal")
	if err != nil {
		return err
	}
	defaults := LoadSystemDefaults()
	return appendJournalLikeRow(opts.base, defaults.JournalFile, "Journal", "Journal row", addOpts, in, out)
}

func runBudgetAdd(args []string, opts options, in io.Reader, out io.Writer) error {
	addOpts, err := parseJournalLikeAddOptions(args, "budget")
	if err != nil {
		return err
	}
	defaults := LoadSystemDefaults()
	return appendJournalLikeRow(opts.base, defaults.BudgetAllocFile, "Budget allocation", "Budget row", addOpts, in, out)
}

func runJournalReverse(args []string, opts options, in io.Reader, out io.Writer) error {
	var targetID string
	var targetIndex int
	var reverseDate string
	yes := false
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--id":
			value, next, err := optionValue(args, i)
			if err != nil {
				return err
			}
			targetID = value
			i = next
		case "--index":
			value, next, err := optionValue(args, i)
			if err != nil {
				return err
			}
			idx, err := parseInt(value)
			if err != nil {
				return fmt.Errorf("invalid --index value: %s", value)
			}
			targetIndex = idx
			i = next
		case "--date":
			value, next, err := optionValue(args, i)
			if err != nil {
				return err
			}
			reverseDate = value
			i = next
		case "--yes":
			yes = true
		default:
			return fmt.Errorf("unknown journal reverse option: %s", args[i])
		}
	}

	if targetID == "" && targetIndex == 0 {
		return errors.New("must specify target using --id or --index")
	}

	journalPath := filepath.Join(opts.base, LoadSystemDefaults().JournalFile)

	// Read journal.tsv raw lines (skip comments and empty lines)
	rawLines, err := readJournalDataLines(journalPath)
	if err != nil {
		return err
	}

	// Find target row
	var targetLine string
	if targetIndex > 0 {
		if targetIndex < 1 || targetIndex > len(rawLines) {
			return fmt.Errorf("invalid index %d (journal has %d data rows)", targetIndex, len(rawLines))
		}
		targetLine = rawLines[targetIndex-1]
	} else {
		// Search by memo (source_id)
		var matches []int
		for i, line := range rawLines {
			fields := strings.Split(line, "\t")
			if len(fields) >= 2 && fields[1] == targetID {
				matches = append(matches, i+1)
			}
		}
		if len(matches) == 0 {
			return fmt.Errorf("no journal row found with id: %s", targetID)
		}
		if len(matches) > 1 {
			return fmt.Errorf("multiple journal rows match id %s (indices: %v). Use --index to specify", targetID, matches)
		}
		targetLine = rawLines[matches[0]-1]
		targetIndex = matches[0]
	}

	// Parse original fields
	fields := strings.Split(targetLine, "\t")
	if len(fields) < 5 {
		return fmt.Errorf("journal row %d has fewer than 5 fields", targetIndex)
	}

	originalDate := fields[0]
	originalMemo := fields[1]
	originalFrom := fields[2]
	originalTo := fields[3]
	originalAmount := fields[4]
	originalMeta := fields[5:]

	if originalFrom == originalTo {
		return fmt.Errorf("cannot reverse row %d: from and to accounts are the same", targetIndex)
	}

	// Build reversed row: swap from/to, prefix memo with [reverse]
	date := reverseDate
	if date == "" {
		date = nowFunc().Format("2006-01-02")
	}
	reversedMemo := "[reverse]" + originalMemo

	addOpts := journalLikeAddOptions{
		date:      date,
		memo:      reversedMemo,
		from:      originalTo,
		to:        originalFrom,
		amount:    originalAmount,
		meta:      originalMeta,
		dryRun:    false,
		yes:       yes,
		postCheck: "lint",
	}

	fmt.Fprintf(out, "Reversing journal row %d (date=%s, memo=%s)\n", targetIndex, originalDate, originalMemo)
	fmt.Fprintf(out, "  Original: %s -> %s  %s\n", originalFrom, originalTo, originalAmount)
	fmt.Fprintf(out, "  Reversed: %s -> %s  %s\n", originalTo, originalFrom, originalAmount)

	r := bufio.NewReader(in)
	return appendJournalLikeRow(opts.base, LoadSystemDefaults().JournalFile, "Journal reverse", "Reversed row", addOpts, r, out)
}

// readJournalDataLines reads journal.tsv and returns non-comment, non-empty lines.
func readJournalDataLines(path string) ([]string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	var lines []string
	for _, line := range strings.Split(string(content), "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") || strings.HasPrefix(trimmed, "\\") {
			continue
		}
		lines = append(lines, strings.TrimSuffix(line, "\r"))
	}
	return lines, nil
}

func parseInt(s string) (int, error) {
	var n int
	for _, c := range s {
		if c < '0' || c > '9' {
			return 0, fmt.Errorf("not a valid integer: %s", s)
		}
		n = n*10 + int(c-'0')
	}
	return n, nil
}

func parseJournalLikeAddOptions(args []string, commandName string) (journalLikeAddOptions, error) {
	addOpts := journalLikeAddOptions{postCheck: "lint"}
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--date":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.date = value
			i = next
		case "--memo":
			value, next, err := optionValueAllowEmpty(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.memo = value
			i = next
		case "--from":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.from = value
			i = next
		case "--to":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.to = value
			i = next
		case "--amount":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.amount = value
			i = next
		case "--meta":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.meta = append(addOpts.meta, value)
			i = next
		case "--dry-run":
			addOpts.dryRun = true
		case "--yes":
			addOpts.yes = true
		case "--post-check":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, err
			}
			addOpts.postCheck = value
			i = next
		default:
			return addOpts, fmt.Errorf("unknown %s add option: %s", commandName, args[i])
		}
	}
	return addOpts, nil
}

func optionValue(args []string, index int) (string, int, error) {
	if index+1 >= len(args) || strings.HasPrefix(args[index+1], "--") {
		return "", index, fmt.Errorf("missing value for %s", args[index])
	}
	return args[index+1], index + 1, nil
}

func optionValueAllowEmpty(args []string, index int) (string, int, error) {
	if index+1 >= len(args) {
		return "", index, fmt.Errorf("missing value for %s", args[index])
	}
	return args[index+1], index + 1, nil
}

func appendJournalLikeRow(base string, filename string, previewTitle string, rowTitle string, opts journalLikeAddOptions, in io.Reader, out io.Writer) error {
	baseAbs, err := filepath.Abs(base)
	if err != nil {
		return fmt.Errorf("resolve base path: %w", err)
	}
	targetPath := filepath.Join(baseAbs, filename)
	paths := ResolvePaths(baseAbs)
	accountsPath := paths.Accounts

	accounts, err := LoadAccounts(accountsPath)
	if err != nil {
		return err
	}
	if err := validateJournalLikeAddOptions(opts, accounts); err != nil {
		return err
	}
	if err := validatePostCheckMode(opts.postCheck); err != nil {
		return err
	}

	row := buildJournalLikeRow(opts)
	snapshot, err := readRawFileSnapshot(targetPath)
	if err != nil {
		return err
	}
	proposed := appendRowContent(snapshot.content, row)
	backupPath := chooseBackupPath(baseAbs, filepath.Base(targetPath), nowFunc())

	mode := "confirm"
	if opts.dryRun {
		mode = "dry-run"
	} else if opts.yes {
		mode = "yes"
	}
	printJournalLikeAppendPreview(out, previewTitle, targetPath, mode, opts.postCheck, backupPath, rowTitle, row)

	if opts.dryRun {
		fmt.Fprintln(out, "Dry-run only. No files were modified.")
		return nil
	}

	if !opts.yes {
		confirmed, err := confirmAppend(in, out)
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
	fmt.Fprintf(out, "Wrote: %s\n", targetPath)
	fmt.Fprintf(out, "Backup: %s\n", backupPath)

	if opts.postCheck == "none" {
		fmt.Fprintln(out, "Post-check: skipped")
		return nil
	}

	result, err := postCheckRunner(baseAbs, opts.postCheck)
	if result.Command != "" {
		fmt.Fprintf(out, "Post-check command: %s\n", result.Command)
	}
	if err != nil {
		fmt.Fprintln(out, "Post-check failed.")
		fmt.Fprintf(out, "Source: %s\n", targetPath)
		fmt.Fprintf(out, "Backup: %s\n", backupPath)
		fmt.Fprintf(out, "Restore suggestion: cp %q %q\n", backupPath, targetPath)
		if result.Output != "" {
			fmt.Fprintln(out, result.Output)
		}
		return fmt.Errorf("post-write check failed: %w", err)
	}
	fmt.Fprintln(out, "Post-check: OK")
	return nil
}

func validateJournalLikeAddOptions(opts journalLikeAddOptions, accounts map[string]bool) error {
	if opts.date == "" {
		return errors.New("missing --date")
	}
	if err := validateDate(opts.date); err != nil {
		return err
	}
	fields := []struct {
		name  string
		value string
	}{
		{"memo", opts.memo},
		{"from", opts.from},
		{"to", opts.to},
		{"amount", opts.amount},
	}
	for _, field := range fields {
		if containsTabOrNewline(field.value) {
			return fmt.Errorf("%s must not contain TAB or newline", field.name)
		}
	}
	if opts.from == "" || !accounts[opts.from] {
		return fmt.Errorf("unknown from account: %s", opts.from)
	}
	if opts.to == "" || !accounts[opts.to] {
		return fmt.Errorf("unknown to account: %s", opts.to)
	}
	if !isInteger(opts.amount) {
		return fmt.Errorf("amount must be an integer: %s", opts.amount)
	}
	for _, token := range opts.meta {
		if containsTabOrNewline(token) {
			return fmt.Errorf("metadata token must not contain TAB or newline: %s", token)
		}
		if !validMetaToken(token) {
			return fmt.Errorf("invalid metadata token: %s", token)
		}
	}
	return nil
}

func validatePostCheckMode(mode string) error {
	switch mode {
	case "lint", "none", "full":
		return nil
	default:
		return fmt.Errorf("invalid --post-check mode: %s", mode)
	}
}

func containsTabOrNewline(value string) bool {
	return strings.ContainsAny(value, "\t\n\r")
}

func buildJournalLikeRow(opts journalLikeAddOptions) []string {
	row := []string{opts.date, opts.memo, opts.from, opts.to, opts.amount}
	row = append(row, opts.meta...)
	return row
}

func appendRowContent(original []byte, row []string) []byte {
	line := strings.Join(row, "\t") + "\n"
	result := append([]byte(nil), original...)
	if len(result) > 0 && result[len(result)-1] != '\n' {
		result = append(result, '\n')
	}
	result = append(result, []byte(line)...)
	return result
}

func readRawFileSnapshot(path string) (rawFileSnapshot, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return rawFileSnapshot{}, fmt.Errorf("read %s: %w", path, err)
	}
	stat, err := os.Stat(path)
	if err != nil {
		return rawFileSnapshot{}, fmt.Errorf("stat %s: %w", path, err)
	}
	hash := sha256.Sum256(content)
	return rawFileSnapshot{
		path:    path,
		content: content,
		mode:    stat.Mode(),
		size:    stat.Size(),
		modTime: stat.ModTime(),
		sha256:  hex.EncodeToString(hash[:]),
	}, nil
}

func (s rawFileSnapshot) checkStale() error {
	content, err := os.ReadFile(s.path)
	if err != nil {
		return fmt.Errorf("stale check read %s: %w", s.path, err)
	}
	stat, err := os.Stat(s.path)
	if err != nil {
		return fmt.Errorf("stale check stat %s: %w", s.path, err)
	}
	hash := sha256.Sum256(content)
	currentHash := hex.EncodeToString(hash[:])
	if stat.Size() != s.size || !stat.ModTime().Equal(s.modTime) || currentHash != s.sha256 {
		if currentHash != s.sha256 {
			return fmt.Errorf("file %s is stale; it changed during editing", s.path)
		}
	}
	return nil
}

func chooseBackupPath(base string, filename string, ts time.Time) string {
	stamp := ts.Format("20060102-150405")
	candidate := filepath.Join(base, ".backup", stamp, filename)
	if _, err := os.Stat(candidate); os.IsNotExist(err) {
		return candidate
	}
	for i := 2; ; i++ {
		candidate = filepath.Join(base, ".backup", fmt.Sprintf("%s-%02d", stamp, i), filename)
		if _, err := os.Stat(candidate); os.IsNotExist(err) {
			return candidate
		}
	}
}

func printJournalLikeAppendPreview(out io.Writer, title string, target string, mode string, postCheck string, backupPath string, rowTitle string, row []string) {
	fmt.Fprintf(out, "%s append preview\n", title)
	fmt.Fprintf(out, "Target: %s\n", target)
	fmt.Fprintf(out, "Mode: %s\n", mode)
	fmt.Fprintf(out, "Post-check: %s\n", postCheck)
	fmt.Fprintf(out, "Backup: %s\n", backupPath)
	fmt.Fprintf(out, "%s:\n", rowTitle)
	fmt.Fprintln(out, strings.Join(row, "\t"))
}

func confirmAppend(in io.Reader, out io.Writer) (bool, error) {
	fmt.Fprint(out, "Append this row? [y/N]: ")
	reader := bufio.NewReader(in)
	text, err := reader.ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return false, err
	}
	answer := strings.ToLower(strings.TrimSpace(text))
	return answer == "y" || answer == "yes", nil
}

func writeSingleFileAtomic(snapshot rawFileSnapshot, proposed []byte, backupPath string) error {
	if err := os.MkdirAll(filepath.Dir(backupPath), 0755); err != nil {
		return fmt.Errorf("create backup directory: %w", err)
	}
	if err := os.WriteFile(backupPath, snapshot.content, snapshot.mode.Perm()); err != nil {
		return fmt.Errorf("write backup %s: %w", backupPath, err)
	}
	if beforeJournalReplaceHook != nil {
		if err := beforeJournalReplaceHook(snapshot.path); err != nil {
			return err
		}
	}
	if err := snapshot.checkStale(); err != nil {
		return err
	}

	dir := filepath.Dir(snapshot.path)
	base := filepath.Base(snapshot.path)
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
	if err := os.Rename(tmpPath, snapshot.path); err != nil {
		return fmt.Errorf("rename temp file: %w", err)
	}
	cleanup = false
	return nil
}

func runBQNPostCheck(base string, mode string) (postCheckResult, error) {
	root, err := findProjectRoot()
	if err != nil {
		return postCheckResult{}, err
	}
	var cmd *exec.Cmd
	switch mode {
	case "lint":
		cmd = exec.Command("bqn", "src_next/report.bqn", base)
	case "full":
		cmd = exec.Command("./tools/check.sh")
	default:
		return postCheckResult{Command: "post-check none"}, nil
	}
	cmd.Dir = root
	output, err := cmd.CombinedOutput()
	return postCheckResult{Command: strings.Join(cmd.Args, " "), Output: string(output)}, err
}

func findProjectRoot() (string, error) {
	candidates := []string{}
	if cwd, err := os.Getwd(); err == nil {
		candidates = append(candidates, cwd)
	}
	if exe, err := os.Executable(); err == nil {
		candidates = append(candidates, filepath.Dir(exe))
	}
	seen := map[string]bool{}
	for _, start := range candidates {
		dir := start
		for {
			if !seen[dir] {
				seen[dir] = true
				if _, err := os.Stat(filepath.Join(dir, "src_next", "report.bqn")); err == nil {
					return dir, nil
				}
			}
			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
		}
	}
	return "", errors.New("could not find project root containing src_next/report.bqn")
}
