# Read-only repository system-default filenames for application/editor routing.

io ← •Import "source_io.bqn"
rows ← •Import "config_rows.bqn"
Load ← {𝕊:
  table ← rows.Build io.ReadLines "config/system_defaults.tsv"
  Required ← {𝕊 key:
    matches ← table.Matches key
    {𝕊:•Out "CONFIG ERROR: system default missing or duplicate: "∾key ⋄ •Exit 1}⍟(1≠≠matches) @
    value ← 1⊑⊑matches
    {𝕊:•Out "CONFIG ERROR: empty system default: "∾key ⋄ •Exit 1}⍟(0=≠value) @
    value
  }
  {
    DefaultBaseDir⇐{𝕊:Required "DEFAULT_BASE_DIR"},
    DefaultAccountsFile⇐{𝕊:Required "DEFAULT_ACCOUNTS_FILE"},
    DefaultPlanFile⇐{𝕊:Required "DEFAULT_PLAN_FILE"},
    DefaultCycleFile⇐{𝕊:Required "DEFAULT_CYCLE_FILE"},
    DefaultConfigFile⇐{𝕊:Required "DEFAULT_CONFIG_FILE"}
  }
}

{Load⇐Load}
