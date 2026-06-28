package main

import (
	"bufio"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// Allowed shared/core/helper modules in src_next.
// Section modules are NOT allowed to be imported by other section modules
// unless specifically allowed in legacyExceptions.
var allowedImports = map[string]bool{
	"format.bqn":           true,
	"report_labels.bqn":    true,
	"context.bqn":          true,
	"tbds.bqn":             true,
	"cube.bqn":             true,
	"loader.bqn":           true,
	"cycle.bqn":            true,
	"projection.bqn":       true,
	"account_key.bqn":      true,
	"household_policy.bqn": true,
	"config.bqn":           true,
	"date.bqn":             true,
	"util.bqn":             true,
	"actual_snapshot.bqn":  true,
	"trial_balance.bqn":    true,
	"unavailable.bqn":      true,
}

// Section modules (the targets of checking inter-dependencies)
var sectionModules = map[string]bool{
	"balances.bqn":             true,
	"ytd_summary.bqn":          true,
	"cycle_summary.bqn":        true,
	"planned_payments.bqn":     true,
	"recent_journal.bqn":       true,
	"readiness_check.bqn":      true,
	"actual_comparison.bqn":    true,
	"household_metadata.bqn":   true,
	"plan_journal_overlap.bqn": true,
	"envelope_computation.bqn": true,
	"outlook.bqn":              true,
	"snapshot.bqn":             true,
	"expense_breakdown.bqn":    true,
	"daily_trend.bqn":          true,
}

// Legacy exceptions for section-to-section dependencies.
// TODO: These legacy couplings should be resolved in the future to keep modules strictly decoupled.
var legacyExceptions = map[string]map[string]bool{
	"readiness_check.bqn": {
		"plan_journal_overlap.bqn": true,
	},
	"daily_trend.bqn": {
		"plan_journal_overlap.bqn": true,
	},
	"outlook.bqn": {
		"envelope_computation.bqn": true,
	},
}

// Allowed fields on BuildContext (ctx.xxxx) inside sections
var allowedCtxFields = map[string]bool{
	"base":     true,
	"cy":       true,
	"resolved": true,
	"cube":     true,
	"tbds":     true,
	"options":  true,
}

func TestBQNModuleDependencies(t *testing.T) {
	// Root dir of the project is parent of editor/
	srcNextDir := filepath.Join("..", "src_next")

	importRegex := regexp.MustCompile(`•Import\s+"([^"]+)"`)
	ctxFieldRegex := regexp.MustCompile(`ctx\.([a-zA-Z0-9_]+)`)

	err := filepath.WalkDir(srcNextDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(d.Name(), ".bqn") {
			return nil
		}

		// Only check defined section modules
		isSection := sectionModules[d.Name()]
		if !isSection {
			return nil
		}

		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()

		t.Logf("Checking dependency hygiene for section: %s", d.Name())
		scanner := bufio.NewScanner(file)
		lineNum := 0
		for scanner.Scan() {
			lineNum++
			line := scanner.Text()

			// Skip comments
			trimmed := strings.TrimSpace(line)
			if strings.HasPrefix(trimmed, "#") {
				continue
			}

			// Rule A: Check Imports
			imports := importRegex.FindAllStringSubmatch(line, -1)
			for _, match := range imports {
				importedFile := filepath.Base(match[1])
				// Self-imports are forbidden
				if importedFile == d.Name() {
					t.Errorf("%s:%d: self-import is invalid: %s", path, lineNum, importedFile)
				}
				if sectionModules[importedFile] {
					// Check if it's a defined legacy exception
					if allowed, ok := legacyExceptions[d.Name()]; !ok || !allowed[importedFile] {
						t.Errorf("%s:%d: forbidden import of section module: %s (add to legacyExceptions if intended)", path, lineNum, importedFile)
					}
				} else {
					// If not in allowed list, raise error
					if !allowedImports[importedFile] {
						t.Errorf("%s:%d: imported file %q is not in the allowed shared/core modules list", path, lineNum, importedFile)
					}
				}
			}

			// Rule B: Check Ctx fields
			ctxMatches := ctxFieldRegex.FindAllStringSubmatch(line, -1)
			for _, match := range ctxMatches {
				field := match[1]
				if !allowedCtxFields[field] {
					t.Errorf("%s:%d: access to unauthorized BuildContext field 'ctx.%s' (allowed fields: base, cy, resolved, cube, tbds, options)", path, lineNum, field)
				}
			}
		}

		return scanner.Err()
	})

	if err != nil {
		t.Fatalf("failed to walk src_next directory: %v", err)
	}
}
