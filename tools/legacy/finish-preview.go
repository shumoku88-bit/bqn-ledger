package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

var planOnlyMeta = map[string]bool{
	"anchor": true,
	"months": true,
	"offset": true,
	"recur":  true,
}

type planRow struct {
	Number    int
	Line      int
	Fields    []string
	Closed    bool
	PlanID    string
	MissingID bool
}

type options struct {
	base       string
	index      int
	actualDate string
	listOnly   bool
	showAll    bool
}

func main() {
	if err := run(os.Args[1:], os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "ERROR:", err)
		os.Exit(2)
	}
}

func run(args []string, in io.Reader, out io.Writer) error {
	opts, err := parseOptions(args)
	if err != nil {
		return err
	}

	accounts, err := loadAccounts(filepath.Join(opts.base, "accounts.tsv"))
	if err != nil {
		return err
	}
	completedIDs, err := loadCompletedPlanIDs(filepath.Join(opts.base, "journal.tsv"))
	if err != nil {
		return err
	}
	allRows, err := loadPlan(filepath.Join(opts.base, "plan.tsv"), accounts, completedIDs)
	if err != nil {
		return err
	}

	var rows []planRow
	if opts.showAll {
		rows = allRows
	} else {
		for _, r := range allRows {
			if !r.Closed {
				rows = append(rows, r)
			}
		}
		// Re-index for the target list
		for i := range rows {
			rows[i].Number = i + 1
		}
	}

	printRows(out, rows, opts.showAll)
	if opts.listOnly {
		return nil
	}
	if len(rows) == 0 {
		return errors.New("plan.tsv has no selectable rows")
	}

	reader := bufio.NewReader(in)
	selected := opts.index
	if selected == 0 {
		fmt.Fprint(out, "Select plan row number: ")
		text, err := reader.ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return err
		}
		selected, err = strconv.Atoi(strings.TrimSpace(text))
		if err != nil {
			return errors.New("plan row number must be an integer")
		}
	}
	if selected < 1 || selected > len(rows) {
		return fmt.Errorf("plan row number must be between 1 and %d", len(rows))
	}

	selectedRow := rows[selected-1]
	if selectedRow.Closed {
		return fmt.Errorf("plan row %d is already closed (completed)", selected)
	}

	date := opts.actualDate
	if date == "" {
		fmt.Fprint(out, "Actual date (YYYY-MM-DD): ")
		text, err := reader.ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return err
		}
		date = strings.TrimSpace(text)
	}
	if err := validateDate(date); err != nil {
		return err
	}

	candidate := journalCandidate(selectedRow, date)
	fmt.Fprintln(out)
	fmt.Fprintln(out, "Preview only. No files will be modified.")
	fmt.Fprintln(out, "Journal candidate:")
	fmt.Fprintln(out, strings.Join(candidate, "\t"))
	fmt.Fprintln(out, "Plan action:")
	fmt.Fprintln(out, "UNCHANGED (recurrence and two-file updates are not implemented)")
	return nil
}

func parseOptions(args []string) (options, error) {
	opts := options{base: "."}
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--base":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.base = value
			i = next
		case "--index":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.index, err = strconv.Atoi(value)
			if err != nil {
				return opts, errors.New("--index must be an integer")
			}
			i = next
		case "--actual-date":
			value, next, err := optionValue(args, i)
			if err != nil {
				return opts, err
			}
			opts.actualDate = value
			i = next
		case "--list":
			opts.listOnly = true
		case "--all":
			opts.showAll = true
		default:
			return opts, fmt.Errorf("unknown option: %s", args[i])
		}
	}
	return opts, nil
}

func optionValue(args []string, index int) (string, int, error) {
	if index+1 >= len(args) || strings.HasPrefix(args[index+1], "--") {
		return "", index, fmt.Errorf("missing value for %s", args[index])
	}
	return args[index+1], index + 1, nil
}

func loadAccounts(path string) (map[string]bool, error) {
	lines, err := readLines(path)
	if err != nil {
		return nil, err
	}
	accounts := make(map[string]bool)
	for _, line := range lines {
		if ignoredLine(line) {
			continue
		}
		name := strings.Split(line, "\t")[0]
		if name != "" {
			accounts[name] = true
		}
	}
	return accounts, nil
}

func loadCompletedPlanIDs(path string) (map[string]bool, error) {
	lines, err := readLines(path)
	if err != nil {
		// If journal.tsv doesn't exist yet, return empty completed list
		if os.IsNotExist(err) || errors.Is(err, os.ErrNotExist) {
			return make(map[string]bool), nil
		}
		return nil, err
	}
	completed := make(map[string]bool)
	for _, line := range lines {
		if ignoredLine(line) {
			continue
		}
		fields := strings.Split(line, "\t")
		if len(fields) < 5 {
			continue
		}
		for _, token := range fields[5:] {
			key, value, ok := strings.Cut(token, "=")
			if ok && key == "plan_id" {
				completed[value] = true
			}
		}
	}
	return completed, nil
}

func loadPlan(path string, accounts map[string]bool, completedIDs map[string]bool) ([]planRow, error) {
	lines, err := readLines(path)
	if err != nil {
		return nil, err
	}
	rows := make([]planRow, 0)
	for lineIndex, line := range lines {
		if ignoredLine(line) {
			continue
		}
		fields := strings.Split(line, "\t")
		if err := validatePlanFields(fields, accounts); err != nil {
			return nil, fmt.Errorf("%s line %d: %w", path, lineIndex+1, err)
		}
		planID := ""
		for _, token := range fields[5:] {
			key, value, ok := strings.Cut(token, "=")
			if ok && key == "plan_id" {
				planID = value
				break
			}
		}
		closed := false
		if planID != "" && completedIDs[planID] {
			closed = true
		}
		rows = append(rows, planRow{
			Number:    len(rows) + 1,
			Line:      lineIndex + 1,
			Fields:    fields,
			Closed:    closed,
			PlanID:    planID,
			MissingID: planID == "",
		})
	}
	return rows, nil
}

func readLines(path string) ([]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	defer f.Close()

	var lines []string
	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 64*1024), 1024*1024)
	for scanner.Scan() {
		lines = append(lines, strings.TrimSuffix(scanner.Text(), "\r"))
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	return lines, nil
}

func ignoredLine(line string) bool {
	return line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "\\")
}

func validatePlanFields(fields []string, accounts map[string]bool) error {
	if len(fields) < 5 {
		return errors.New("expected at least 5 tab-separated columns")
	}
	if err := validateDate(fields[0]); err != nil {
		return err
	}
	if fields[2] == "" || !accounts[fields[2]] {
		return fmt.Errorf("unknown from account: %s", fields[2])
	}
	if fields[3] == "" || !accounts[fields[3]] {
		return fmt.Errorf("unknown to account: %s", fields[3])
	}
	if !isInteger(fields[4]) {
		return fmt.Errorf("amount must be an integer: %s", fields[4])
	}
	for _, token := range fields[5:] {
		if !validMetaToken(token) {
			return fmt.Errorf("invalid metadata token: %s", token)
		}
	}
	return nil
}

func isInteger(value string) bool {
	if value == "" {
		return false
	}
	body := value
	if body[0] == '-' {
		body = body[1:]
	}
	if body == "" {
		return false
	}
	for _, char := range body {
		if char < '0' || char > '9' {
			return false
		}
	}
	return true
}

func validMetaToken(token string) bool {
	key, value, ok := strings.Cut(token, "=")
	if !ok || key == "" || value == "" {
		return false
	}
	for _, char := range key {
		isLower := char >= 'a' && char <= 'z'
		isDigit := char >= '0' && char <= '9'
		if !isLower && !isDigit && char != '_' && char != '-' {
			return false
		}
	}
	return true
}

func validateDate(value string) error {
	parsed, err := time.Parse("2006-01-02", value)
	if err != nil || parsed.Format("2006-01-02") != value {
		return fmt.Errorf("invalid date: %s", value)
	}
	return nil
}

func journalCandidate(row planRow, actualDate string) []string {
	result := append([]string(nil), row.Fields[:5]...)
	result[0] = actualDate
	for _, token := range row.Fields[5:] {
		key, _, ok := strings.Cut(token, "=")
		if ok && !planOnlyMeta[key] {
			result = append(result, token)
		}
	}
	return result
}

func printRows(out io.Writer, rows []planRow, showAll bool) {
	fmt.Fprintln(out, "Plan rows:")
	for _, row := range rows {
		fields := row.Fields
		status := ""
		if row.Closed {
			status = " [CLOSED]"
		} else if row.MissingID {
			status = " [MISSING-ID]"
		}
		fmt.Fprintf(
			out,
			"%d: %s\t%s\t%s -> %s\t%s%s\n",
			row.Number,
			fields[0],
			fields[1],
			fields[2],
			fields[3],
			fields[4],
			status,
		)
	}
}
