# config.bqn
# Reads config.tsv and exposes it as a namespace.
# Migrated from old src/core/config.bqn.

lib ← •Import "util.bqn"

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
  raw ← lib.LoadLines file_path
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
    DefaultJournalFile ⇐ { 𝕊 ⋄ Get "DEFAULT_JOURNAL_FILE" },
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

LoadConfig ← {
  file_path ← Path 𝕩
  raw ← lib.LoadLines file_path
  parsed ← ParseLine ¨ raw
  keys ← { 0 ⊑ 𝕩 } ¨ parsed
  values ← { 1 ⊑ 𝕩 } ¨ parsed

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

  CsvList ← { (@+44) lib.Split 𝕩 }

  BudgetPrefix ← { 𝕊 ⋄ Required "BUDGET_PREFIX" }
  BudgetOpening ← { 𝕊 ⋄ Required "BUDGET_ID_OPENING" }
  BudgetUnassigned ← { 𝕊 ⋄ Required "BUDGET_ID_UNASSIGNED" }
  BudgetSpent ← { 𝕊 ⋄ Required "BUDGET_ID_SPENT" }

  HouseholdGroupLifeLabels ← { 𝕊 ⋄ CsvList (Required "HOUSEHOLD_GROUP_LIFE") }
  HouseholdGroupReserveLabels ← { 𝕊 ⋄ CsvList (Required "HOUSEHOLD_GROUP_RESERVE") }
  HouseholdGroupOrderLabels ← { 𝕊 ⋄ CsvList (Required "HOUSEHOLD_GROUP_ORDER") }

  PolicyBudgetStyle ← { 𝕊 ⋄
    v ← Get "POLICY_BUDGET_STYLE"
    v ↩ (0 = ≠ v) ⊑ ⟨ v, "envelope" ⟩
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
    v ← Get "POLICY_RISK_STYLE"
    v ↩ (0 = ≠ v) ⊑ ⟨ v, "conservative" ⟩
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
    ( (0 < ≠ v) ∧ (v ≢ "bimonthly") ∧ (v ≢ "monthly") ∧ (v ≢ "weekly") ∧ (v ≢ "irregular") ) ◶ ⟨
      { @ },
      { 𝕊 ⋄
        •Out "CONFIG ERROR: unknown POLICY_INCOME_CADENCE=" ∾ v
        •Exit 1
      }
    ⟩ @
    v
  }

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
    warnings ⇐ Warnings @
  }
}

{ LoadConfig ⇐ LoadConfig, LoadSystemDefaults ⇐ LoadSystemDefaults }
