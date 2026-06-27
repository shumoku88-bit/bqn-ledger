package main

import (
	"fmt"
	"os"
	"strings"
	"time"
)

var planOnlyMeta map[string]bool

type PlanRow struct {
	Number    int
	LineNum   int
	Fields    []string
	Closed    bool
	PlanID    string
	MissingID bool
	InvalidID bool
}

func validatePlanIDFormat(planID string) bool {
	if !strings.HasPrefix(planID, "plan-") {
		return false
	}
	parts := strings.Split(planID, "-")
	if len(parts) < 5 {
		return false
	}
	dateStr := fmt.Sprintf("%s-%s-%s", parts[1], parts[2], parts[3])
	if _, err := time.Parse("2006-01-02", dateStr); err != nil {
		return false
	}
	series := strings.Join(parts[4:], "-")
	return len(series) > 0
}

func LoadAccounts(path string) (map[string]bool, error) {
	tsv, err := ReadTSV(path)
	if err != nil {
		return nil, err
	}
	accounts := make(map[string]bool)
	for _, row := range tsv.Rows {
		if row.IsComment || row.IsEmpty {
			continue
		}
		if len(row.Fields) > 0 && row.Fields[0] != "" {
			accounts[row.Fields[0]] = true
		}
	}
	return accounts, nil
}

func LoadCompletedPlanIDs(path string) (map[string]bool, error) {
	tsv, err := ReadTSV(path)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]bool), nil
		}
		return nil, err
	}
	completed := make(map[string]bool)
	for _, row := range tsv.Rows {
		if row.IsComment || row.IsEmpty {
			continue
		}
		if len(row.Fields) > 5 {
			for _, token := range row.Fields[5:] {
				key, value, ok := strings.Cut(token, "=")
				if ok && key == "plan_id" && value != "" {
					completed[value] = true
				}
			}
		}
	}
	return completed, nil
}

func LoadPlans(path string, accounts map[string]bool, completedIDs map[string]bool) ([]PlanRow, error) {
	tsv, err := ReadTSV(path)
	if err != nil {
		return nil, err
	}
	var rows []PlanRow
	for _, row := range tsv.Rows {
		if row.IsComment || row.IsEmpty {
			continue
		}
		if err := validatePlanFields(row.Fields, accounts); err != nil {
			return nil, fmt.Errorf("%s line %d: %w", path, row.LineNum, err)
		}

		planID := ""
		missingID := true
		invalidID := false

		if len(row.Fields) > 5 {
			for _, token := range row.Fields[5:] {
				key, value, ok := strings.Cut(token, "=")
				if ok && key == "plan_id" {
					planID = value
					missingID = false
					if !validatePlanIDFormat(planID) {
						invalidID = true
					}
					break
				}
			}
		}

		closed := false
		if planID != "" && completedIDs[planID] {
			closed = true
		}

		rows = append(rows, PlanRow{
			LineNum:   row.LineNum,
			Fields:    row.Fields,
			Closed:    closed,
			PlanID:    planID,
			MissingID: missingID,
			InvalidID: invalidID,
		})
	}
	return rows, nil
}

func validatePlanFields(fields []string, accounts map[string]bool) error {
	if len(fields) < 5 {
		return fmt.Errorf("expected at least 5 tab-separated columns")
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

func validateDate(value string) error {
	parsed, err := time.Parse("2006-01-02", value)
	if err != nil || parsed.Format("2006-01-02") != value {
		return fmt.Errorf("invalid date: %s", value)
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
	key, _, ok := strings.Cut(token, "=")
	if !ok || key == "" {
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

func JournalCandidate(row PlanRow, actualDate string) []string {
	if planOnlyMeta == nil {
		planOnlyMeta = LoadPlanOnlyMeta()
	}
	result := append([]string(nil), row.Fields[:5]...)
	result[0] = actualDate
	if len(row.Fields) > 5 {
		for _, token := range row.Fields[5:] {
			key, _, ok := strings.Cut(token, "=")
			if ok && !planOnlyMeta[key] {
				result = append(result, token)
			}
		}
	}
	return result
}
