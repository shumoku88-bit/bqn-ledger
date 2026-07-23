# config.bqn
# Reads config.tsv and exposes it as a namespace.
# Migrated from old src/core/config.bqn.

lib ← •Import "util.bqn"
loader ← •Import "loader.bqn"

ParseLine ← {
  tab ← @+9
  sep ← (⊑ tab ∊ 𝕩) ◶ ⟨ { '=' }, { tab } ⟩ @
  parts ← sep lib.SplitKeepEmpty 𝕩
  key ← 0 ⊑ parts
  val ← (1 < ≠ parts) ◶ ⟨ { "" }, { 1 ⊑ parts } ⟩ @
  ⟨ key, val ⟩
}

LoadSystemDefaults ← { 𝕩 ⋄
  file_path ← "config/system_defaults.tsv"
  raw ← loader.ReadLines file_path
  parsed ← ParseLine ¨ raw
  keys ← { 0 ⊑ 𝕩 } ¨ parsed
  values ← { 1 ⊑ 𝕩 } ¨ parsed

  Get ← {
    k ← 𝕩
    idx ← ⊑ (keys ⊐ ⟨k⟩) ∾ ⟨≠keys⟩
    (idx < ≠ keys) ? (idx ⊑ values) ; ""
  }

  {
    Get ⇐ Get,
    DefaultBaseDir ⇐ { 𝕊 ⋄ Get "DEFAULT_BASE_DIR" },
    DefaultAccountsFile ⇐ { 𝕊 ⋄ Get "DEFAULT_ACCOUNTS_FILE" },
    DefaultPlanFile ⇐ { 𝕊 ⋄ Get "DEFAULT_PLAN_FILE" },
    DefaultBudgetAllocFile ⇐ { 𝕊 ⋄ Get "DEFAULT_BUDGET_ALLOC_FILE" },
    DefaultCycleFile ⇐ { 𝕊 ⋄ Get "DEFAULT_CYCLE_FILE" },
    DefaultConfigFile ⇐ { 𝕊 ⋄ Get "DEFAULT_CONFIG_FILE" }
  }
}

Path ← {
  (0 = ≠ 𝕩) ? "config/default_config.tsv" ; {
    sys ← LoadSystemDefaults @
    def_cfg ← sys.DefaultConfigFile @
    def_path ← "config/default_config.tsv"
    is_long ← 4 ≤ ≠ 𝕩
    is_tsv ← is_long ∧ (".tsv" ≡ ¯4 ↑ 𝕩)
    target ← is_tsv ⊑ ⟨ 𝕩 ∾ "/" ∾ def_cfg, 𝕩 ⟩
    exists ← 0 = ⊑ •SH ⟨"test", "-f", target⟩
    exists ⊑ ⟨ def_path, target ⟩
  } 𝕩
}

LoadActualJournal ← {𝕊 base:
  localParsed ← ParseLine¨loader.ReadLines (Path base)
  repoParsed ← ParseLine¨loader.ReadLines "config/default_config.tsv"
  key ← "ACTUAL_JOURNAL_FILE"
  localMatches ← ({(0⊑𝕩)≡key}¨localParsed)/localParsed
  repoMatches ← ({(0⊑𝕩)≡key}¨repoParsed)/repoParsed
  {𝕊: •Out "CONFIG ERROR: duplicate value for "∾key ⋄ •Exit 1}⍟(1<≠localMatches) @
  {𝕊: •Out "CONFIG ERROR: repository default missing or duplicate for "∾key ⋄ •Exit 1}⍟(1≠≠repoMatches) @
  file ← 1⊑⊑repoMatches
  {𝕊: file↩1⊑⊑localMatches}⍟(1=≠localMatches) @
  {𝕊: •Out "CONFIG ERROR: empty value for "∾key ⋄ •Exit 1}⍟(0=≠file) @
  hasSeparator ← ∨´ ('/'=file) ∨ ((@+92)=file)
  hasControl ← ∨´ file∊(@+9)‿(@+13)
  validSuffix ← (8≤≠file) ∧ ".journal"≡¯8↑file
  {𝕊: •Out "CONFIG ERROR: "∾key∾" must be a safe .journal basename" ⋄ •Exit 1}⍟(hasSeparator ∨ hasControl ∨ ¬validSuffix) @
  {file⇐file}
}

LoadConfig ← {
  file_path ← Path 𝕩
  raw ← loader.ReadLines file_path
  parsed ← ParseLine ¨ raw
  keys ← { 0 ⊑ 𝕩 } ¨ parsed
  values ← { 1 ⊑ 𝕩 } ¨ parsed

  repo_raw ← loader.ReadLines "config/default_config.tsv"
  repo_parsed ← ParseLine ¨ repo_raw
  repo_keys ← { 0 ⊑ 𝕩 } ¨ repo_parsed
  repo_values ← { 1 ⊑ 𝕩 } ¨ repo_parsed

  Lookup ← {
    k ← 𝕩
    idx ← ⊑ (keys ⊐ ⟨k⟩) ∾ ⟨≠keys⟩
    (idx < ≠ keys) ? ⟨1, idx ⊑ values⟩ ; ⟨0, ""⟩
  }

  Get ← {
    k ← 𝕩
    idx ← ⊑ (keys ⊐ ⟨k⟩) ∾ ⟨≠keys⟩
    (idx < ≠ keys) ? (idx ⊑ values) ; ""
  }

  Required ← {
    k ← 𝕩
    v ← Get k
    (0 < ≠ v) ◶ ⟨
      { 𝕊 ⋄
        •Out "CONFIG ERROR: missing value for " ∾ k
        •Exit 1
      },
      { 𝕊 ⋄ v }
    ⟩ @
  }

  RepositoryLookup ← {
    k ← 𝕩
    idx ← ⊑ (repo_keys ⊐ ⟨k⟩) ∾ ⟨≠repo_keys⟩
    (idx < ≠ repo_keys) ? ⟨1, idx ⊑ repo_values⟩ ; ⟨0, ""⟩
  }

  EffectiveDefaultable ← {
    k ← 𝕩
    found‿v ← Lookup k
    (found ∧ (0 = ≠ v)) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: empty value for " ∾ k
        •Exit 1
      }
    ⟩ @
    (found ∧ (0 < ≠ v)) ◶ ⟨
      { 𝕊 ⋄
        repo_found‿repo_v ← RepositoryLookup k
        ((0 = repo_found) ∨ (0 = ≠ repo_v)) ◶ ⟨
          { repo_v },
          { 𝕊 ⋄
            •Out "CONFIG ERROR: missing repository default for " ∾ k
            •Exit 1
          }
        ⟩ @
      },
      { 𝕊 ⋄ v }
    ⟩ @
  }

  CsvList ← { (@+44) lib.Split 𝕩 }

  BudgetPrefix ← { 𝕊 ⋄ Required "BUDGET_PREFIX" }
  BudgetOpening ← { 𝕊 ⋄ Required "BUDGET_ID_OPENING" }
  BudgetUnassigned ← { 𝕊 ⋄ Required "BUDGET_ID_UNASSIGNED" }
  BudgetSpent ← { 𝕊 ⋄ Required "BUDGET_ID_SPENT" }

  HouseholdGroupLifeLabels ← { 𝕊 ⋄ CsvList (EffectiveDefaultable "HOUSEHOLD_GROUP_LIFE") }
  HouseholdGroupReserveLabels ← { 𝕊 ⋄ CsvList (EffectiveDefaultable "HOUSEHOLD_GROUP_RESERVE") }
  HouseholdGroupOrderLabels ← { 𝕊 ⋄ CsvList (Required "HOUSEHOLD_GROUP_ORDER") }

  PolicyBudgetStyle ← { 𝕊 ⋄
    found‿v ← Lookup "POLICY_BUDGET_STYLE"
    (found ∧ (0 = ≠ v)) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: empty value for POLICY_BUDGET_STYLE"
        •Exit 1
      }
    ⟩ @
    {𝕊: •Out "CONFIG WARNING: POLICY_BUDGET_STYLE missing, using default=envelope"}⍟(0 = found) @
    v ↩ (0 = found) ⊑ ⟨ v, "envelope" ⟩
    ( (v ≢ "envelope") ∧ (v ≢ "none") ) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: unknown POLICY_BUDGET_STYLE=" ∾ v
        •Exit 1
      }
    ⟩ @
    v
  }

  PolicyRiskStyle ← { 𝕊 ⋄
    found‿v ← Lookup "POLICY_RISK_STYLE"
    (found ∧ (0 = ≠ v)) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: empty value for POLICY_RISK_STYLE"
        •Exit 1
      }
    ⟩ @
    {𝕊: •Out "CONFIG WARNING: POLICY_RISK_STYLE missing, using default=conservative"}⍟(0 = found) @
    v ↩ (0 = found) ⊑ ⟨ v, "conservative" ⟩
    ( (v ≢ "conservative") ∧ (v ≢ "simple") ) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: unknown POLICY_RISK_STYLE=" ∾ v
        •Exit 1
      }
    ⟩ @
    v
  }

  PolicyIncomeCadence ← { 𝕊 ⋄
    v ← Get "POLICY_INCOME_CADENCE"
    {𝕊: •Out "CONFIG WARNING: POLICY_INCOME_CADENCE missing"}⍟(0 = ≠ v) @
    ( (0 < ≠ v) ∧ (v ≢ "bimonthly") ∧ (v ≢ "monthly") ∧ (v ≢ "weekly") ∧ (v ≢ "irregular") ) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: unknown POLICY_INCOME_CADENCE=" ∾ v
        •Exit 1
      }
    ⟩ @
    v
  }

  ActualJournalFile ← { 𝕊 ⋄ (LoadActualJournal 𝕩).file }
  ExecutionPlannedPaymentsEnvelope ← { 𝕊 ⋄ Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE" }

  Warnings ← { 𝕊 ⋄
    bs ← PolicyBudgetStyle @
    gl ← Get "HOUSEHOLD_GROUP_LIFE"
    gr ← Get "HOUSEHOLD_GROUP_RESERVE"
    go ← Get "HOUSEHOLD_GROUP_ORDER"
    has_groups ← (0 < ≠ gl) ∨ (0 < ≠ gr) ∨ (0 < ≠ go)
    ( (bs ≡ "none") ∧ has_groups ) ◶ ⟨
      { ⟨⟩ },
      { 𝕊 ⋄ ⟨"CONFIG WARNING: budget groups defined but budget style is none."⟩ }
    ⟩ @
  }

  {
    keys ⇐ keys,
    values ⇐ values,
    Lookup ⇐ Lookup,
    Get ⇐ Get,
    CsvList ⇐ CsvList,
    BudgetPrefix ⇐ BudgetPrefix,
    BudgetOpening ⇐ BudgetOpening,
    BudgetUnassigned ⇐ BudgetUnassigned,
    BudgetSpent ⇐ BudgetSpent,
    HouseholdGroupLifeLabels ⇐ HouseholdGroupLifeLabels,
    HouseholdGroupReserveLabels ⇐ HouseholdGroupReserveLabels,
    HouseholdGroupOrderLabels ⇐ HouseholdGroupOrderLabels,
    PolicyBudgetStyle ⇐ PolicyBudgetStyle,
    PolicyRiskStyle ⇐ PolicyRiskStyle,
    PolicyIncomeCadence ⇐ PolicyIncomeCadence,
    ActualJournalFile ⇐ {𝕊: (LoadActualJournal file_path).file},
    ExecutionPlannedPaymentsEnvelope ⇐ ExecutionPlannedPaymentsEnvelope,
    warnings ⇐ Warnings @
  }
}

{ LoadConfig ⇐ LoadConfig, LoadActualJournal⇐LoadActualJournal, LoadSystemDefaults ⇐ LoadSystemDefaults }
