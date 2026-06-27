package main

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

type SystemDefaults struct {
	BaseDir         string
	AccountsFile    string
	JournalFile     string
	PlanFile        string
	BudgetAllocFile string
	CycleFile       string
	ConfigFile      string
}

type ResolvedPaths struct {
	Base        string
	Accounts    string
	Journal     string
	Plan        string
	BudgetAlloc string
	Cycle       string
	Config      string
}

func LoadSystemDefaults() SystemDefaults {
	defaults := SystemDefaults{
		BaseDir:         "data",
		AccountsFile:    "accounts.tsv",
		JournalFile:     "journal.tsv",
		PlanFile:        "plan.tsv",
		BudgetAllocFile: "budget_alloc.tsv",
		CycleFile:       "cycle.tsv",
		ConfigFile:      "config.tsv",
	}
	applyEnv := func() {
		if envBase := os.Getenv("LEDGER_DATA_DIR"); envBase != "" {
			defaults.BaseDir = envBase
		}
	}

	const defaultsPath = "config/system_defaults.tsv"
	file, err := os.Open(defaultsPath)
	if err != nil {
		applyEnv()
		return defaults
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) < 2 {
			continue
		}
		key := parts[0]
		val := parts[1]
		switch key {
		case "DEFAULT_BASE_DIR":
			defaults.BaseDir = val
		case "DEFAULT_ACCOUNTS_FILE":
			defaults.AccountsFile = val
		case "DEFAULT_JOURNAL_FILE":
			defaults.JournalFile = val
		case "DEFAULT_PLAN_FILE":
			defaults.PlanFile = val
		case "DEFAULT_BUDGET_ALLOC_FILE":
			defaults.BudgetAllocFile = val
		case "DEFAULT_CYCLE_FILE":
			defaults.CycleFile = val
		case "DEFAULT_CONFIG_FILE":
			defaults.ConfigFile = val
		}
	}
	applyEnv()
	return defaults
}

func ResolvePaths(baseDir string) ResolvedPaths {
	defaults := LoadSystemDefaults()

	base := baseDir
	if base == "" {
		base = defaults.BaseDir
	}

	return ResolvedPaths{
		Base:        base,
		Accounts:    filepath.Join(base, defaults.AccountsFile),
		Journal:     filepath.Join(base, defaults.JournalFile),
		Plan:        filepath.Join(base, defaults.PlanFile),
		BudgetAlloc: filepath.Join(base, defaults.BudgetAllocFile),
		Cycle:       filepath.Join(base, defaults.CycleFile),
		Config:      filepath.Join(base, defaults.ConfigFile),
	}
}

func LoadPlanOnlyMeta() map[string]bool {
	planOnly := make(map[string]bool)
	const schemaPath = "config/meta_schema.tsv"
	file, err := os.Open(schemaPath)
	if err != nil {
		return map[string]bool{
			"anchor": true,
			"months": true,
			"offset": true,
			"recur":  true,
		}
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) >= 4 && parts[3] == "plan" {
			if parts[0] != "" {
				planOnly[parts[0]] = true
			}
		}
	}
	return planOnly
}
