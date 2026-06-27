# household_metadata.bqn
# Household metadata readiness diagnostics for src_next Stage 4a.
#
# Boundary:
#   - consumes account metadata already exposed by account_key.bqn
#   - counts missing/observed household metadata for expense accounts
#   - reports policy-label lists as raw strings, never interpreting them
#
# Non-goals:
#   - does not implement food remaining
#   - does not implement daily remaining
#   - does not implement envelope balances
#   - does not hard-code household labels (daily/flex/reserve/etc.)
#   - does not convert missing metadata to default categories
#   - does not require config.tsv
#   - does not consume valid_rows (computation-free diagnostics)

StartsWith ← { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 }
Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }
NonEmpty ← { 0 < ≠ 𝕩 }

# Build: produce household metadata readiness diagnostics namespace.
# Args: ctx (context namespace with ctx.resolved)
# Returns: namespace with counts, value lists, missing account lists
Build ← {𝕊 ctx:
  resolved ← ctx.resolved
  accounts ← resolved.accounts
  roles ← resolved.roles
  budgets ← resolved.budgets
  groups ← resolved.budget_groups
  spend_classes ← resolved.spend_classes

  # Expense account classification: role=expense explicit + expenses: prefix fallback
  role_expense ← "expense"⊸≡¨ roles
  role_missing ← ""⊸≡¨ roles
  prefix_fallback ← role_missing ∧ ({ "expenses:" StartsWith 𝕩 }¨ accounts)
  prefix_fallback_income ← role_missing ∧ ({ "income:" StartsWith 𝕩 }¨ accounts)
  prefix_fallback_asset ← role_missing ∧ ({ "assets:" StartsWith 𝕩 }¨ accounts)
  prefix_fallback_liability ← role_missing ∧ ({ "liabilities:" StartsWith 𝕩 }¨ accounts)
  prefix_fallback_budget ← role_missing ∧ ({ "budget:" StartsWith 𝕩 }¨ accounts)

  expense_mask ← role_expense ∨ prefix_fallback
  expense_indices ← expense_mask / ↕ ≠ expense_mask

  # Metadata presence for expense accounts only
  exp_budgets ← expense_indices ⊏ budgets
  exp_groups ← expense_indices ⊏ groups
  exp_spend ← expense_indices ⊏ spend_classes
  exp_accounts ← expense_indices ⊏ accounts

  budget_present ← NonEmpty¨ exp_budgets
  group_present ← NonEmpty¨ exp_groups
  spend_present ← NonEmpty¨ exp_spend

  # Counts
  expense_total ← Sum0 expense_mask
  missing_budget_count ← Sum0 (¬ budget_present)
  missing_budget_group_count ← Sum0 (¬ group_present)
  missing_spend_class_count ← Sum0 (¬ spend_present)
  prefix_fallback_expense_count ← Sum0 prefix_fallback
  prefix_fallback_income_count ← Sum0 prefix_fallback_income
  prefix_fallback_asset_count ← Sum0 prefix_fallback_asset
  prefix_fallback_liability_count ← Sum0 prefix_fallback_liability
  prefix_fallback_budget_count ← Sum0 prefix_fallback_budget
  prefix_fallback_total_count ← prefix_fallback_expense_count + prefix_fallback_income_count + prefix_fallback_asset_count + prefix_fallback_liability_count + prefix_fallback_budget_count

  # Missing account keys
  missing_budget_indices ← (¬ budget_present) / ↕ ≠ exp_accounts
  missing_group_indices ← (¬ group_present) / ↕ ≠ exp_accounts
  missing_spend_indices ← (¬ spend_present) / ↕ ≠ exp_accounts
  missing_budget_accounts ← missing_budget_indices ⊏ exp_accounts
  missing_budget_group_accounts ← missing_group_indices ⊏ exp_accounts
  missing_spend_class_accounts ← missing_spend_indices ⊏ exp_accounts

  # Deduplicate helper: mark first occurrences and filter
  Dedup ← { (0 = ≠𝕩) ? ⟨⟩ ; ((𝕩 ⊐ 𝕩) = ↕ ≠𝕩) / 𝕩 }

  # Observed values (deduplicated, sorted)
  observed_budgets ← ∧ Dedup (budget_present / exp_budgets)
  observed_groups ← ∧ Dedup (group_present / exp_groups)
  observed_spend ← ∧ Dedup (spend_present / exp_spend)

  # Join values as comma-separated string for output
  Join ← {𝕊 xs:
    o ← ""
    { o ↩ o ∾ 𝕩 ∾ "," }¨ xs
    (0 < ≠ o) ? ¯1 ↓ o ; ""
  }
  budget_values ← Join observed_budgets
  budget_group_values ← Join observed_groups
  spend_class_values ← Join observed_spend

  # Join missing account keys as comma-separated
  missing_budget_accounts_str ← Join missing_budget_accounts
  missing_budget_group_accounts_str ← Join missing_budget_group_accounts
  missing_spend_class_accounts_str ← Join missing_spend_class_accounts

  has_any ← 0 < expense_total

  {
    has_any ⇐ has_any,
    expense_accounts_total ⇐ expense_total,
    missing_budget_count ⇐ missing_budget_count,
    missing_budget_group_count ⇐ missing_budget_group_count,
    missing_spend_class_count ⇐ missing_spend_class_count,
    prefix_fallback_expense_count ⇐ prefix_fallback_expense_count,
    prefix_fallback_income_count ⇐ prefix_fallback_income_count,
    prefix_fallback_asset_count ⇐ prefix_fallback_asset_count,
    prefix_fallback_liability_count ⇐ prefix_fallback_liability_count,
    prefix_fallback_budget_count ⇐ prefix_fallback_budget_count,
    prefix_fallback_total_count ⇐ prefix_fallback_total_count,
    budget_values ⇐ budget_values,
    budget_group_values ⇐ budget_group_values,
    spend_class_values ⇐ spend_class_values,
    missing_budget_accounts ⇐ missing_budget_accounts_str,
    missing_budget_group_accounts ⇐ missing_budget_group_accounts_str,
    missing_spend_class_accounts ⇐ missing_spend_class_accounts_str
  }
}

# Format: render diagnostics namespace as text.
Format ← {𝕊 diag:
  {𝕊:
    out ← "--- SrcNext Household Metadata ---" ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_expense_accounts_total: " ∾ (•Fmt diag.expense_accounts_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_missing_budget_count: " ∾ (•Fmt diag.missing_budget_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_missing_budget_group_count: " ∾ (•Fmt diag.missing_budget_group_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_missing_spend_class_count: " ∾ (•Fmt diag.missing_spend_class_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_prefix_fallback_total_count: " ∾ (•Fmt diag.prefix_fallback_total_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_prefix_fallback_expense_count: " ∾ (•Fmt diag.prefix_fallback_expense_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_budget_values: " ∾ diag.budget_values ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_budget_group_values: " ∾ diag.budget_group_values ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_spend_class_values: " ∾ diag.spend_class_values ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_missing_budget_accounts: " ∾ diag.missing_budget_accounts ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_missing_budget_group_accounts: " ∾ diag.missing_budget_group_accounts ∾ (@+10)
    out ↩ out ∾ "src_next_household_metadata_missing_spend_class_accounts: " ∾ diag.missing_spend_class_accounts ∾ (@+10)
    out
  }⍟diag.has_any @
}

{ Build ⇐ Build, Format ⇐ Format, Sum0 ⇐ Sum0 }
