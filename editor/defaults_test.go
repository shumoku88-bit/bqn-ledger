package main

import "testing"

func TestLoadSystemDefaultsHonorsLedgerDataDir(t *testing.T) {
	t.Setenv("LEDGER_DATA_DIR", "moko/data")

	defaults := LoadSystemDefaults()
	if defaults.BaseDir != "moko/data" {
		t.Fatalf("BaseDir = %q; want %q", defaults.BaseDir, "moko/data")
	}
}

func TestResolvePathsUsesLedgerDataDirDefault(t *testing.T) {
	t.Setenv("LEDGER_DATA_DIR", "moko/data")

	paths := ResolvePaths("")
	if paths.Base != "moko/data" {
		t.Fatalf("Base = %q; want %q", paths.Base, "moko/data")
	}
	if paths.Journal != "moko/data/journal.tsv" {
		t.Fatalf("Journal = %q; want %q", paths.Journal, "moko/data/journal.tsv")
	}
}
