package main

import (
	"fmt"
	"io"
	"path/filepath"
	"regexp"
	"strings"
)

var nonSlugChars = regexp.MustCompile(`[^a-z0-9]+`)

func runPlanAdd(args []string, opts options, in io.Reader, out io.Writer) error {
	addOpts, planID, err := parsePlanAddOptions(args)
	if err != nil {
		return err
	}
	if err := validatePostCheckMode(addOpts.postCheck); err != nil {
		return err
	}
	if hasMetaKey(addOpts.meta, "plan_id") {
		return fmt.Errorf("--meta plan_id=... is not allowed; use --id or let plan add generate plan_id")
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
	if err := validateJournalLikeAddOptions(addOpts, accounts); err != nil {
		return err
	}

	existingIDs, err := loadExistingPlanIDs(paths.Plan, paths.Journal, accounts)
	if err != nil {
		return err
	}

	if planID == "" {
		planID = generatePlanID(addOpts.date, addOpts.memo, addOpts.meta, existingIDs)
	} else {
		if containsTabOrNewline(planID) {
			return fmt.Errorf("plan_id must not contain TAB or newline: %s", planID)
		}
		if !validatePlanIDFormat(planID) {
			return fmt.Errorf("invalid plan_id: %s", planID)
		}
		if existingIDs[planID] {
			return fmt.Errorf("plan_id already exists: %s", planID)
		}
	}

	addOpts.meta = append(addOpts.meta, "plan_id="+planID)
	defaults := LoadSystemDefaults()
	return appendJournalLikeRow(baseAbs, defaults.PlanFile, "Plan", "Plan row", addOpts, in, out)
}

func parsePlanAddOptions(args []string) (journalLikeAddOptions, string, error) {
	addOpts := journalLikeAddOptions{postCheck: "lint"}
	planID := ""
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--id":
			value, next, err := optionValue(args, i)
			if err != nil {
				return addOpts, planID, err
			}
			planID = value
			i = next
		default:
			next, handled, err := parsePlanAddJournalLikeOption(args, i, &addOpts)
			if err != nil {
				return addOpts, planID, err
			}
			if !handled {
				return addOpts, planID, fmt.Errorf("unknown plan add option: %s", args[i])
			}
			i = next
		}
	}
	return addOpts, planID, nil
}

func parsePlanAddJournalLikeOption(args []string, i int, addOpts *journalLikeAddOptions) (int, bool, error) {
	switch args[i] {
	case "--date":
		value, next, err := optionValue(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.date = value
		return next, true, nil
	case "--memo":
		value, next, err := optionValueAllowEmpty(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.memo = value
		return next, true, nil
	case "--from":
		value, next, err := optionValue(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.from = value
		return next, true, nil
	case "--to":
		value, next, err := optionValue(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.to = value
		return next, true, nil
	case "--amount":
		value, next, err := optionValue(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.amount = value
		return next, true, nil
	case "--meta":
		value, next, err := optionValue(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.meta = append(addOpts.meta, value)
		return next, true, nil
	case "--dry-run":
		addOpts.dryRun = true
		return i, true, nil
	case "--yes":
		addOpts.yes = true
		return i, true, nil
	case "--post-check":
		value, next, err := optionValue(args, i)
		if err != nil {
			return i, true, err
		}
		addOpts.postCheck = value
		return next, true, nil
	default:
		return i, false, nil
	}
}

func hasMetaKey(meta []string, target string) bool {
	for _, token := range meta {
		key, _, ok := strings.Cut(token, "=")
		if ok && key == target {
			return true
		}
	}
	return false
}

func loadExistingPlanIDs(planPath string, journalPath string, accounts map[string]bool) (map[string]bool, error) {
	completedIDs, err := LoadCompletedPlanIDs(journalPath)
	if err != nil {
		return nil, err
	}
	ids := make(map[string]bool)
	for id := range completedIDs {
		ids[id] = true
	}
	plans, err := LoadPlans(planPath, accounts, completedIDs)
	if err != nil {
		return nil, err
	}
	for _, row := range plans {
		if row.PlanID != "" {
			ids[row.PlanID] = true
		}
	}
	return ids, nil
}

func generatePlanID(date string, memo string, meta []string, existing map[string]bool) string {
	source := memo
	for _, token := range meta {
		key, value, ok := strings.Cut(token, "=")
		if ok && key == "series" && value != "" {
			source = value
			break
		}
	}
	slug := slugifyPlanIDPart(source)
	base := "plan-" + date + "-" + slug
	if !existing[base] {
		return base
	}
	for i := 2; ; i++ {
		candidate := fmt.Sprintf("%s-%02d", base, i)
		if !existing[candidate] {
			return candidate
		}
	}
}

func slugifyPlanIDPart(value string) string {
	slug := strings.ToLower(strings.TrimSpace(value))
	slug = nonSlugChars.ReplaceAllString(slug, "-")
	slug = strings.Trim(slug, "-")
	if slug == "" {
		return "plan"
	}
	return slug
}
