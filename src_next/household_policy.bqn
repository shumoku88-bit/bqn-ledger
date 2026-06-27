# household_policy.bqn
# Read-only diagnostic household policy summary for src_next.
#
# Boundary:
#   - consumes account metadata already exposed by account_key.bqn
#   - consumes valid projection rows already accepted by cube.bqn
#   - reports policy-shape diagnostics only
#
# Non-goals:
#   - does not implement food remaining
#   - does not implement daily remaining
#   - does not change production engine behavior
#   - does not infer missing household metadata

conf ← •Import "config.bqn"

layer_actual ← 0
layer_plan ← 1

Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }
StartsWith ← { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 }
NonEmpty ← { 0 < ≠ 𝕩 }
IsMember ← { list ← 𝕨 ⋄ label ← 𝕩 ⋄ (⊑ list ⊐ ⟨ label ⟩) < ≠ list }
GroupLabelMatch ← { label ← 𝕨 ⋄ (0 < ≠ label) ∧ label ≡ 𝕩 }
KnownSpendClass ← { (𝕩 ≡ "variable") ∨ (𝕩 ≡ "fixed") }
HasPolicyMetadata ← {𝕊 cfg‿resolved:
  is_none ← "none" ≡ cfg.PolicyBudgetStyle @
  meta_count ← (Sum0 (NonEmpty¨resolved.budgets)) + (Sum0 (NonEmpty¨resolved.budget_groups)) + (Sum0 (NonEmpty¨resolved.spend_classes))
  has_meta ← ⊑ 0 < meta_count
  has_meta × ¬ is_none
}

BuildSummary ← {𝕊 base‿resolved‿valid_rows:
  cfg ← conf.LoadConfig base
  life_groups ← cfg.HouseholdGroupLifeLabels @
  reserve_groups ← cfg.HouseholdGroupReserveLabels @
  order_groups ← cfg.HouseholdGroupOrderLabels @
  known_groups ← order_groups ∾ life_groups ∾ reserve_groups
  daily_label ← 0 ⊑ (life_groups ∾ ⟨ "" ⟩)
  flex_label ← 1 ⊑ (life_groups ∾ ⟨ "" ⟩)
  reserve_label ← 0 ⊑ (reserve_groups ∾ ⟨ "" ⟩)

  accounts ← resolved.accounts
  roles ← resolved.roles
  budgets ← resolved.budgets
  groups ← resolved.budget_groups
  spend_classes ← resolved.spend_classes

  role_expense ← "expense"⊸≡¨ roles
  role_missing ← ""⊸≡¨ roles
  prefix_fallback ← role_missing ∧ ({ "expenses:" StartsWith 𝕩 }¨ accounts)
  expense_accounts ← role_expense ∨ prefix_fallback

  budget_present ← NonEmpty¨budgets
  group_present ← NonEmpty¨groups
  spend_present ← NonEmpty¨spend_classes

  group_daily ← daily_label⊸GroupLabelMatch¨ groups
  group_flex ← flex_label⊸GroupLabelMatch¨ groups
  group_reserve ← reserve_label⊸GroupLabelMatch¨ groups
  group_missing ← ""⊸≡¨ groups
  group_known ← known_groups⊸IsMember¨ groups
  group_other ← group_present ∧ ¬ group_known

  spend_variable ← "variable"⊸≡¨ spend_classes
  spend_fixed ← "fixed"⊸≡¨ spend_classes
  spend_missing ← ""⊸≡¨ spend_classes
  spend_known ← KnownSpendClass¨spend_classes
  spend_other ← spend_present ∧ ¬ spend_known

  row_ak ← {𝕩.account_key_index}¨ valid_rows
  row_layer ← {𝕩.layer_index}¨ valid_rows
  row_kind ← {𝕩.kind}¨ valid_rows
  row_side ← {𝕩.side}¨ valid_rows
  row_delta ← {𝕩.delta}¨ valid_rows
  row_groups ← {𝕩⊑groups}¨ row_ak

  ExpenseDebitTotal ← {𝕊 layer‿group:
    mask ← (row_layer = layer) ∧ ("expense"⊸≡¨ row_kind) ∧ ("debit"⊸≡¨ row_side) ∧ (group⊸GroupLabelMatch¨ row_groups)
    Sum0 (mask / row_delta)
  }
  ExpenseDebitMissingTotal ← {𝕊 layer:
    mask ← (row_layer = layer) ∧ ("expense"⊸≡¨ row_kind) ∧ ("debit"⊸≡¨ row_side) ∧ (""⊸≡¨ row_groups)
    Sum0 (mask / row_delta)
  }
  ExpenseDebitOtherTotal ← {𝕊 layer:
    row_group_present ← NonEmpty¨row_groups
    row_group_known ← known_groups⊸IsMember¨ row_groups
    mask ← (row_layer = layer) ∧ ("expense"⊸≡¨ row_kind) ∧ ("debit"⊸≡¨ row_side) ∧ row_group_present ∧ ¬ row_group_known
    Sum0 (mask / row_delta)
  }

  {
    has_policy_metadata ⇐ HasPolicyMetadata ⟨cfg, resolved⟩,
    expense_account_count ⇐ Sum0 expense_accounts,
    prefix_fallback_expense_account_count ⇐ Sum0 prefix_fallback,
    expense_account_with_budget_count ⇐ Sum0 (expense_accounts ∧ budget_present),
    expense_budget_group_daily_count ⇐ Sum0 (expense_accounts ∧ group_daily),
    expense_budget_group_flex_count ⇐ Sum0 (expense_accounts ∧ group_flex),
    expense_budget_group_reserve_count ⇐ Sum0 (expense_accounts ∧ group_reserve),
    expense_budget_group_missing_count ⇐ Sum0 (expense_accounts ∧ group_missing),
    expense_budget_group_other_count ⇐ Sum0 (expense_accounts ∧ group_other),
    expense_spend_class_variable_count ⇐ Sum0 (expense_accounts ∧ spend_variable),
    expense_spend_class_fixed_count ⇐ Sum0 (expense_accounts ∧ spend_fixed),
    expense_spend_class_missing_count ⇐ Sum0 (expense_accounts ∧ spend_missing),
    expense_spend_class_other_count ⇐ Sum0 (expense_accounts ∧ spend_other),
    actual_budget_group_daily_total ⇐ ExpenseDebitTotal ⟨layer_actual, daily_label⟩,
    actual_budget_group_flex_total ⇐ ExpenseDebitTotal ⟨layer_actual, flex_label⟩,
    actual_budget_group_reserve_total ⇐ ExpenseDebitTotal ⟨layer_actual, reserve_label⟩,
    actual_budget_group_missing_total ⇐ ExpenseDebitMissingTotal layer_actual,
    actual_budget_group_other_total ⇐ ExpenseDebitOtherTotal layer_actual,
    plan_budget_group_daily_total ⇐ ExpenseDebitTotal ⟨layer_plan, daily_label⟩,
    plan_budget_group_flex_total ⇐ ExpenseDebitTotal ⟨layer_plan, flex_label⟩,
    plan_budget_group_reserve_total ⇐ ExpenseDebitTotal ⟨layer_plan, reserve_label⟩,
    plan_budget_group_missing_total ⇐ ExpenseDebitMissingTotal layer_plan,
    plan_budget_group_other_total ⇐ ExpenseDebitOtherTotal layer_plan
  }
}

FormatSummary ← {𝕊 s:
  out ← ""
  {𝕊:
    out ↩ out ∾ "--- SrcNext Household Policy Diagnostic ---" ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_accounts: " ∾ (•Fmt s.expense_account_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_accounts_prefix_fallback: " ∾ (•Fmt s.prefix_fallback_expense_account_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_accounts_with_budget: " ∾ (•Fmt s.expense_account_with_budget_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_budget_group_daily: " ∾ (•Fmt s.expense_budget_group_daily_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_budget_group_flex: " ∾ (•Fmt s.expense_budget_group_flex_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_budget_group_reserve: " ∾ (•Fmt s.expense_budget_group_reserve_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_budget_group_missing: " ∾ (•Fmt s.expense_budget_group_missing_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_budget_group_other: " ∾ (•Fmt s.expense_budget_group_other_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_spend_class_variable: " ∾ (•Fmt s.expense_spend_class_variable_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_spend_class_fixed: " ∾ (•Fmt s.expense_spend_class_fixed_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_spend_class_missing: " ∾ (•Fmt s.expense_spend_class_missing_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_expense_spend_class_other: " ∾ (•Fmt s.expense_spend_class_other_count) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_actual_budget_group_daily_total: " ∾ (•Fmt s.actual_budget_group_daily_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_actual_budget_group_flex_total: " ∾ (•Fmt s.actual_budget_group_flex_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_actual_budget_group_reserve_total: " ∾ (•Fmt s.actual_budget_group_reserve_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_actual_budget_group_missing_total: " ∾ (•Fmt s.actual_budget_group_missing_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_actual_budget_group_other_total: " ∾ (•Fmt s.actual_budget_group_other_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_plan_budget_group_daily_total: " ∾ (•Fmt s.plan_budget_group_daily_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_plan_budget_group_flex_total: " ∾ (•Fmt s.plan_budget_group_flex_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_plan_budget_group_reserve_total: " ∾ (•Fmt s.plan_budget_group_reserve_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_plan_budget_group_missing_total: " ∾ (•Fmt s.plan_budget_group_missing_total) ∾ (@+10)
    out ↩ out ∾ "src_next_household_policy_plan_budget_group_other_total: " ∾ (•Fmt s.plan_budget_group_other_total) ∾ (@+10)
  }⍟s.has_policy_metadata @
  out
}

{ BuildSummary ⇐ BuildSummary,
  FormatSummary ⇐ FormatSummary,
  HasPolicyMetadata ⇐ HasPolicyMetadata,
  Sum0 ⇐ Sum0
}
