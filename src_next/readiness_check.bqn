# readiness_check.bqn
# Compact report readiness surface for src_next Stage 4 trial.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
fmt ← •Import "format.bqn"
cube ← •Import "cube.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# Build: extract readiness counts and warning lists from context.
# Args: ctx (context namespace with ctx.cube)
# Returns: readiness namespace.
Build ← {𝕊 ctx:
  result ← ctx.cube
  resolved ← ctx.resolved

  # Metadata checks
  roles ← resolved.roles
  accounts ← resolved.accounts
  types ← resolved.types
  budgets ← resolved.budgets
  classes ← resolved.spend_classes
  kinds ← resolved.kinds
  envelope_roles ← resolved.envelope_roles
  raw_accounts ← resolved.raw_accounts
  raw_metas ← resolved.raw_metadata

  # Unknown enum checks
  valid_roles ← ⟨"asset", "liability", "equity", "income", "expense", "budget", "unknown"⟩
  unknown_role_mask ← ¬ (roles ∊ valid_roles)
  unknown_role_accounts ← unknown_role_mask / resolved.account_keys

  valid_types ← ⟨"", "liquid", "savings", "invest"⟩
  unknown_type_mask ← ¬ (types ∊ valid_types)
  unknown_type_accounts ← unknown_type_mask / resolved.account_keys

  valid_classes ← ⟨"", "fixed", "variable"⟩
  unknown_spend_class_mask ← ¬ (classes ∊ valid_classes)
  unknown_spend_class_accounts ← unknown_spend_class_mask / resolved.account_keys

  valid_envelope_roles ← ⟨"", "dynamic", "execution", "unassigned"⟩
  unknown_envelope_role_mask ← ¬ (envelope_roles ∊ valid_envelope_roles)
  unknown_envelope_role_accounts ← unknown_envelope_role_mask / resolved.account_keys

  has_env_role ← ¬ (""⊸≡¨ envelope_roles)
  kind_envelope ← "envelope"⊸≡¨ kinds
  kind_unassigned ← "unassigned"⊸≡¨ kinds
  bad_unassigned_role ← kind_unassigned ∧ has_env_role ∧ (¬ "unassigned"⊸≡¨ envelope_roles)
  bad_envelope_role ← kind_envelope ∧ ("unassigned"⊸≡¨ envelope_roles)
  bad_non_envelope_role ← (¬ (kind_envelope ∨ kind_unassigned)) ∧ has_env_role
  inconsistent_envelope_role_mask ← bad_unassigned_role ∨ bad_envelope_role ∨ bad_non_envelope_role
  inconsistent_envelope_role_accounts ← inconsistent_envelope_role_mask / resolved.account_keys

  # Duplicate checks
  first_acc_idx ← raw_accounts ⊐ raw_accounts
  dup_acc_mask ← (↕ ≠ raw_accounts) ≠ first_acc_idx
  duplicate_accounts ← dup_acc_mask / raw_accounts

  DupKeys ← { 
    keys ← { ( 𝕩 ⊐ '=' ) ↑ 𝕩 }¨ 𝕩
    ( (↕ ≠ keys) ≠ keys ⊐ keys ) / keys 
  }
  dup_keys_list ← DupKeys¨ raw_metas
  has_dup_keys ← { 0 < ≠ 𝕩 }¨ dup_keys_list
  accounts_with_dup_keys ← has_dup_keys / resolved.account_keys

  # Missing metadata checks (warnings)
  missing_role_mask ← ""⊸≡¨ roles
  missing_role_accounts ← missing_role_mask / resolved.account_keys

  is_asset ← "asset"⊸≡¨ roles
  missing_type_mask ← is_asset ∧ (""⊸≡¨ types)
  missing_type_accounts ← missing_type_mask / resolved.account_keys

  is_expense ← "expense"⊸≡¨ roles
  missing_spend_mask ← is_expense ∧ (""⊸≡¨ classes)
  missing_spend_accounts ← missing_spend_mask / resolved.account_keys

  is_var_exp ← is_expense ∧ ("variable"⊸≡¨ classes)
  missing_budget_mask ← is_var_exp ∧ (""⊸≡¨ budgets)
  missing_budget_accounts ← missing_budget_mask / resolved.account_keys

  # Stale plans and future journal rows (from skipped_rows)
  skipped ← result.skipped_rows

  # Stale plans: source_file is "plan.tsv" and day_index < 0
  is_stale_plan ← { ("plan.tsv" ≡ 𝕩.source_file) ∧ (𝕩.day_index < 0) }¨ skipped
  stale_plan_rows ← is_stale_plan / skipped
  stale_plans ← { ⟨ 𝕩.date, 𝕩.message, •Fmt 𝕩.delta ⟩ }¨ stale_plan_rows

  # Future journal rows: source_file is "journal.tsv" and day_index >= day_count
  is_future_journal ← { ("journal.tsv" ≡ 𝕩.source_file) ∧ (𝕩.day_index ≥ ctx.cy.day_count) }¨ skipped
  future_journal_rows ← is_future_journal / skipped
  future_journals ← { ⟨ 𝕩.date, 𝕩.message, •Fmt 𝕩.delta ⟩ }¨ future_journal_rows

  {
    valid_rows      ⇐ result.valid_count,
    skipped_rows    ⇐ result.skipped_count,
    skipped_status             ⇐ result.skipped_summary.status,
    skipped_day_before_start   ⇐ result.skipped_summary.day_before_start,
    skipped_day_after_end      ⇐ result.skipped_summary.day_after_end,
    skipped_account_key_index  ⇐ result.skipped_summary.account_key_index,
    skipped_layer_index        ⇐ result.skipped_summary.layer_index,
    skipped_unknown            ⇐ result.skipped_summary.unknown,
    skipped_invalid_count       ⇐ result.skipped_summary.invalid_count,
    skipped_out_of_period_count ⇐ result.skipped_summary.out_of_period_count,
    unknown_account_count      ⇐ result.skipped_summary.unknown_account,
    out_of_cycle_skipped_count ⇐ result.skipped_summary.day_after_end,

    unknown_role_accounts ⇐ unknown_role_accounts,
    unknown_type_accounts ⇐ unknown_type_accounts,
    unknown_spend_class_accounts ⇐ unknown_spend_class_accounts,
    unknown_envelope_role_accounts ⇐ unknown_envelope_role_accounts,
    inconsistent_envelope_role_accounts ⇐ inconsistent_envelope_role_accounts,
    duplicate_accounts ⇐ duplicate_accounts,
    accounts_with_dup_keys ⇐ accounts_with_dup_keys,

    missing_role_accounts ⇐ missing_role_accounts,
    missing_type_accounts ⇐ missing_type_accounts,
    missing_spend_accounts ⇐ missing_spend_accounts,
    missing_budget_accounts ⇐ missing_budget_accounts,
    stale_plans ⇐ stale_plans,
    future_journals ⇐ future_journals
  }
}

Format ← {𝕊 summary:
  out ← "--- SrcNext Readiness Check ---" ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_valid_projection_rows: " ∾ (•Fmt summary.valid_rows) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_projection_rows: " ∾ (•Fmt summary.skipped_rows) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_status: " ∾ (•Fmt summary.skipped_status) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_day_before_start: " ∾ (•Fmt summary.skipped_day_before_start) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_day_after_end: " ∾ (•Fmt summary.skipped_day_after_end) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_account_key_index: " ∾ (•Fmt summary.skipped_account_key_index) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_layer_index: " ∾ (•Fmt summary.skipped_layer_index) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_unknown: " ∾ (•Fmt summary.skipped_unknown) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_invalid: " ∾ (•Fmt summary.skipped_invalid_count) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_skipped_out_of_period: " ∾ (•Fmt summary.skipped_out_of_period_count) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_unknown_account_count: " ∾ (•Fmt summary.unknown_account_count) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_out_of_cycle_skipped_count: " ∾ (•Fmt summary.out_of_cycle_skipped_count) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_unknown_role_accounts_count: " ∾ (•Fmt ≠ summary.unknown_role_accounts) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_unknown_type_accounts_count: " ∾ (•Fmt ≠ summary.unknown_type_accounts) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_unknown_spend_class_accounts_count: " ∾ (•Fmt ≠ summary.unknown_spend_class_accounts) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_unknown_envelope_role_accounts_count: " ∾ (•Fmt ≠ summary.unknown_envelope_role_accounts) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_inconsistent_envelope_role_accounts_count: " ∾ (•Fmt ≠ summary.inconsistent_envelope_role_accounts) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_duplicate_accounts_count: " ∾ (•Fmt ≠ summary.duplicate_accounts) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_accounts_with_dup_keys_count: " ∾ (•Fmt ≠ summary.accounts_with_dup_keys) ∾ (@+10)
  out ↩ out ∾ "src_next_readiness_missing_role_accounts_count: " ∾ (•Fmt ≠ summary.missing_role_accounts) ∾ (@+10)
  out
}

# FormatHuman: render report readiness check as human-readable text.
FormatHuman ← {𝕊 ctx:
  summary ← Build ctx
  overlap_mod ← •Import "plan_journal_overlap.bqn"
  overlap ← overlap_mod.Build ctx
  duplicate_plans ← overlap.strong_overlap_keys ∾ overlap.ambiguous_overlap_keys

  # Read file lines counts for input files
  base ← ctx.base
  cycDisp ← fmt.RangeDisp ⟨ctx.cy.start, ctx.cy.end_exclusive⟩

  # Read files to get total line counts
  j_lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  p_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")

  out ← (L "readiness.section_title") ∾ (@+10)
  out ↩ out ∾ (@+10)
  out ↩ out ∾ "[Input files]" ∾ (@+10)
  out ↩ out ∾ "  journal rows      : " ∾ (•Fmt ≠ j_lines) ∾ (@+10)
  out ↩ out ∾ "  plan rows         : " ∾ (•Fmt ≠ p_lines) ∾ (@+10)
  out ↩ out ∾ "  accounts defined  : " ∾ (•Fmt ctx.resolved.count) ∾ (@+10)
  out ↩ out ∾ "  cycle             : " ∾ cycDisp ∾ (@+10)
  out ↩ out ∾ (@+10)

  OutIndented ← {𝕊 accts:
    res ← ""
    { res ↩ res ∾ "    - " ∾ 𝕩 ∾ (@+10) }¨ accts
    res
  }

  out ↩ out ∾ "[Report readiness]" ∾ (@+10)
  out ↩ out ∾ "  accounts missing role metadata  : " ∾ (•Fmt ≠ summary.missing_role_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.missing_role_accounts
  out ↩ out ∾ "  assets missing type             : " ∾ (•Fmt ≠ summary.missing_type_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.missing_type_accounts
  out ↩ out ∾ "  expenses missing spend_class    : " ∾ (•Fmt ≠ summary.missing_spend_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.missing_spend_accounts
  out ↩ out ∾ "  variable expenses without budget: " ∾ (•Fmt ≠ summary.missing_budget_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.missing_budget_accounts
  out ↩ out ∾ (@+10)

  out ↩ out ∾ "[Data hygiene warnings]" ∾ (@+10)
  out ↩ out ∾ "  unknown role accounts           : " ∾ (•Fmt ≠ summary.unknown_role_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.unknown_role_accounts
  out ↩ out ∾ "  unknown type accounts           : " ∾ (•Fmt ≠ summary.unknown_type_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.unknown_type_accounts
  out ↩ out ∾ "  unknown spend_class accounts    : " ∾ (•Fmt ≠ summary.unknown_spend_class_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.unknown_spend_class_accounts
  out ↩ out ∾ "  unknown envelope_role accounts  : " ∾ (•Fmt ≠ summary.unknown_envelope_role_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.unknown_envelope_role_accounts
  out ↩ out ∾ "  inconsistent envelope_role      : " ∾ (•Fmt ≠ summary.inconsistent_envelope_role_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.inconsistent_envelope_role_accounts
  out ↩ out ∾ "  duplicate accounts              : " ∾ (•Fmt ≠ summary.duplicate_accounts) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.duplicate_accounts
  out ↩ out ∾ "  accounts with duplicate keys    : " ∾ (•Fmt ≠ summary.accounts_with_dup_keys) ∾ (@+10)
  out ↩ out ∾ OutIndented summary.accounts_with_dup_keys
  out ↩ out ∾ "  future journal rows             : " ∾ (•Fmt ≠ summary.future_journals) ∾ (@+10)
  {
    out ↩ out ∾ "    - " ∾ (0⊑𝕩) ∾ " " ∾ (1⊑𝕩) ∾ " (" ∾ (2⊑𝕩) ∾ ")" ∾ (@+10)
  }¨ summary.future_journals

  out ↩ out ∾ "  plan rows already in journal    : " ∾ (•Fmt ≠ duplicate_plans) ∾ (@+10)
  {
    # 5-field key: date, memo, from, to, amount
    out ↩ out ∾ "    - " ∾ (0⊑𝕩) ∾ " " ∾ (1⊑𝕩) ∾ " (" ∾ (4⊑𝕩) ∾ ")" ∾ (@+10)
  }¨ duplicate_plans

  out ↩ out ∾ "  stale plan rows                 : " ∾ (•Fmt ≠ summary.stale_plans) ∾ (@+10)
  {
    out ↩ out ∾ "    - " ∾ (0⊑𝕩) ∾ " " ∾ (1⊑𝕩) ∾ " (" ∾ (2⊑𝕩) ∾ ")" ∾ (@+10)
  }¨ summary.stale_plans

  out ↩ out ∾ (@+10)
  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
