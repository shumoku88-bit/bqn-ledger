# envelope_computation.bqn
# Modernized envelope computation.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
conf ← •Import "config.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text
unav ← •Import "unavailable.bqn"
json ← •Import "json.bqn"

layer_actual ← 0

Sum0 ← cube.Sum0
NonEmpty ← { 0 < ≠ 𝕩 }
Contains ← { needle ← 𝕨 ⋄ 0 < +´ (needle ⍷ 𝕩) }
IsMember ← { list ← 𝕨 ⋄ item ← 𝕩 ⋄ (⊑ list ⊐ ⟨item⟩) < ≠ list }

# ── Policy target structure ──────────────────────────
NoPolicyTarget ← {𝕊:
  {
    has_policy ⇐ 0,
    target_id ⇐ "unavailable/no_policy",
    label ⇐ "unavailable/no_policy",
    selector_key ⇐ "",
    selector_value ⇐ ""
  }
}

FixtureFoodLikeTarget ← {𝕊:
  {
    has_policy ⇐ 1,
    target_id ⇐ "fixture_food_like",
    label ⇐ (L "envelope.fixture_food_like_label"),
    selector_key ⇐ "budget",
    selector_value ⇐ (L "envelope.fixture_food_like_selector_value")
  }
}

PolicyForBase ← {𝕊 base:
  ("src-next-envelope-computation" Contains base) ◶ ⟨NoPolicyTarget, FixtureFoodLikeTarget⟩ @
}

# ── Target selection ────────────────────────────────────────
ExpenseAccountMask ← {𝕊 resolved:
  role_expense ← "expense"⊸≡¨ resolved.roles
  role_missing ← ""⊸≡¨ resolved.roles
  prefix_fallback ← role_missing ∧ ({ "expenses:" unav.StartsWith 𝕩 }¨ resolved.accounts)
  role_expense ∨ prefix_fallback
}

SelectedExpenseIndices ← {𝕊 tgt‿resolved:
  can_select ← tgt.has_policy ∧ (tgt.selector_key ≡ "budget")
  {𝕊:
    expense_mask ← ExpenseAccountMask resolved
    budget_match ← tgt.selector_value⊸≡¨ resolved.budgets
    (expense_mask ∧ budget_match) / ↕ ≠ resolved.accounts
  }⍟can_select ⟨⟩
}

BudgetAccountMask ← {𝕊 resolved:
  role_budget ← "budget"⊸≡¨ resolved.roles
  role_missing ← ""⊸≡¨ resolved.roles
  prefix_fallback ← role_missing ∧ ({ "budget:" unav.StartsWith 𝕩 }¨ resolved.accounts)
  role_budget ∨ prefix_fallback
}

BudgetLabel ← {𝕊 account:
  ("budget:" unav.StartsWith account) ⊑ account‿(7 ↓ account)
}

known_envelope_roles ← ⟨"dynamic","execution","unassigned"⟩

EnvelopeRoleForIndex ← {𝕊 resolved‿idx:
  explicit ← idx ⊑ resolved.envelope_roles
  kind ← idx ⊑ resolved.kinds
  is_known ← known_envelope_roles IsMember explicit
  role ← "unknown"
  {𝕊: role ↩ explicit}⍟is_known @
  {𝕊: role ↩ "dynamic"}⍟((0 = ≠ explicit) ∧ (kind ≡ "envelope")) @
  {𝕊: role ↩ "unassigned"}⍟((0 = ≠ explicit) ∧ (kind ≡ "unassigned")) @
  role
}

IsActiveEnvelopeRole ← { (𝕩 ≡ "dynamic") ∨ (𝕩 ≡ "execution") }

ExecutionStatus ← {𝕊 allocated‿remaining‿actual_spent:
  status ← "HELD"
  {𝕊: status ↩ "DONE"}⍟((allocated > 0) ∧ (remaining = 0) ∧ (actual_spent ≥ 0)) @
  {𝕊: status ↩ "DRAWN"}⍟(remaining < 0) @
  status
}

UnassignedBudgetAccountIndices ← {𝕊 resolved:
  budget_mask ← BudgetAccountMask resolved
  kind_unassigned_mask ← "unassigned"⊸≡¨ resolved.kinds
  (budget_mask ∧ kind_unassigned_mask) / ↕ resolved.count
}

UnassignedStatus ← {𝕊 cnt‿remaining:
  status ← "OK"
  {𝕊: status ↩ "OVER_ALLOCATED"}⍟(remaining < 0) @
  {𝕊: status ↩ "error/ambiguous_unassigned_account"}⍟(cnt > 1) @
  {𝕊: status ↩ "unavailable/no_unassigned_account"}⍟(cnt = 0) @
  status
}

CalcUnassignedRemaining ← {𝕊 resolved‿valid_rows:
  unassigned_indices ← UnassignedBudgetAccountIndices resolved
  row_layer ← {𝕩.layer_index}¨ valid_rows
  row_ak ← {𝕩.account_key_index}¨ valid_rows
  row_delta ← {𝕩.delta}¨ valid_rows
  mask ← (row_layer = 2) ∧ (unassigned_indices⊸IsMember¨ row_ak)
  remaining ← Sum0 (mask / row_delta)
  cnt ← ≠ unassigned_indices
  SourceFor ← {𝕊 idx:
    idx_mask ← (row_layer = 2) ∧ (row_ak = idx)
    { name ⇐ idx ⊑ resolved.accounts, amount ⇐ Sum0 (idx_mask / row_delta) }
  }
  sources ← SourceFor¨ unassigned_indices
  {
    account_count ⇐ cnt,
    remaining ⇐ remaining,
    status ⇐ UnassignedStatus ⟨cnt, remaining⟩,
    sources ⇐ sources
  }
}

TargetBudgetAccountIndices ← {𝕊 tgt‿resolved:
  can_select ← tgt.has_policy ∧ (tgt.selector_key ≡ "budget")
  {𝕊:
    budget_mask ← BudgetAccountMask resolved
    labels ← BudgetLabel¨ resolved.accounts
    label_match ← tgt.selector_value⊸≡¨ labels
    (budget_mask ∧ label_match) / ↕ ≠ resolved.accounts
  }⍟can_select ⟨⟩
}

# ── allocated calculation ───────────────────────────────────
Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

InCycle ← {𝕊 cy‿date:
  day ← proj.ResolveDayFromCycle ⟨date, cy.start⟩
  (day ≥ 0) ∧ (day < cy.day_count)
}

CalcAllocated ← {𝕊 tgt‿resolved‿cy‿alloc_lines:
  target_budget_indices ← TargetBudgetAccountIndices ⟨tgt, resolved⟩
  target_budget_accounts ← target_budget_indices ⊏ resolved.accounts

  RowAmountIfTarget ← {𝕊 line:
    f ← Pad5 loader.SplitTsvKeepEmpty line
    date ← 0⊑f
    to_acc ← 3⊑f
    amt ← •BQN 4⊑f
    is_target ← target_budget_accounts IsMember to_acc
    ((InCycle ⟨cy, date⟩) ∧ is_target) ⊑ 0‿amt
  }

  amounts ← RowAmountIfTarget¨ alloc_lines
  {
    amount ⇐ Sum0 amounts,
    row_count ⇐ Sum0 (0⊸≠¨ amounts),
    target_budget_account_count ⇐ ≠ target_budget_indices,
    has_allocation ⇐ 0 < Sum0 (0⊸≠¨ amounts)
  }
}

# ── actual_spent calculation ────────────────────────────────
CalcActualSpent ← {𝕊 selected_indices‿valid_rows:
  row_ak ← {𝕩.account_key_index}¨ valid_rows
  row_layer ← {𝕩.layer_index}¨ valid_rows
  row_kind ← {𝕩.kind}¨ valid_rows
  row_side ← {𝕩.side}¨ valid_rows
  row_delta ← {𝕩.delta}¨ valid_rows

  selected_mask ← selected_indices⊸IsMember¨ row_ak
  mask ← (row_layer = layer_actual) ∧ ("expense"⊸≡¨ row_kind) ∧ ("debit"⊸≡¨ row_side) ∧ selected_mask
  Sum0 (mask / row_delta)
}

CalcRemaining ← {𝕊 allocated‿actual_spent: allocated - actual_spent }

DecideStatus ← {𝕊 tgt‿selected_indices‿allocated:
  computed ← tgt.has_policy ∧ (0 < ≠ selected_indices) ∧ allocated.has_allocation
  computed ⊑ "unavailable/no_policy"‿"computed"
}

# ── Latest Actual Date ───────────────────────────────────────
LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available_cycle ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← "unavailable/no_data"
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d:
      dn ← proj.DaysFromEpoch d
      (dn ≥ start_dn) ∧ (dn < end_dn)
    }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ in_dates }⍟(0 < ≠ in_dates) @
  }⍟(available_cycle ∧ (0 < ≠ lines)) @
  out ↩ (¬ available_cycle) ⊑ out‿"unavailable/no_cycle"
  out
}

# ── Execution planned coverage diagnostic ────────────────────
PlanId ← {𝕊 line:
  flds ← loader.SplitTsvKeepEmpty line
  meta ← 5 ↓ flds
  IsPlanId ← {"plan_id=" ≡ 8↑𝕩}
  cand ← IsPlanId¨ meta
  has ← ∨´cand
  id ← ∾ 5↑flds
  id ↩ ({𝕊: 8 ↓ (⊑(cand/↕≠meta)) ⊑ meta}⍟has) id
  id
}

CleanName ← {
  ( "expenses:" unav.StartsWith 𝕩 ) ? 9 ↓ 𝕩 ;
  ( "income:" unav.StartsWith 𝕩 ) ? 7 ↓ 𝕩 ;
  ( "liabilities:" unav.StartsWith 𝕩 ) ? 12 ↓ 𝕩 ;
  𝕩
}

BuildExecutionPlannedCoverage ← {𝕊 base‿cy‿envelopes‿cfg:
  env_label ← cfg.ExecutionPlannedPaymentsEnvelope @
  cycleAvail ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  disabled ← (0 = ≠ env_label) ∨ (¬ cycleAvail)

  status ← "disabled"
  env_remaining ← @
  planned_total ← @
  delta ← @
  rows_out ← ⟨⟩

  {𝕊:
    labels ← {𝕩.label}¨ envelopes
    env_idx ← labels ⊐ ⟨env_label⟩
    has_env ← env_idx < ≠ envelopes

    {𝕊:
      env ← env_idx ⊑ envelopes
      env_remaining ↩ env.remaining

      plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
      plan_mask ← { InCycle ⟨cy, ⊑ Pad5 loader.SplitTsvKeepEmpty 𝕩⟩ }¨ plan_lines
      plan_rows ← plan_mask / plan_lines

      journal_lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
      journal_mask ← { InCycle ⟨cy, ⊑ Pad5 loader.SplitTsvKeepEmpty 𝕩⟩ }¨ journal_lines
      journal_rows ← journal_mask / journal_lines
      journal_ids ← PlanId¨ journal_rows

      ParsePlanRow ← {𝕊 line:
        f ← Pad5 loader.SplitTsvKeepEmpty line
        from ← 2⊑f ⋄ to ← 3⊑f
        is_inc ← "income:" unav.StartsWith from
        cat ← CleanName (is_inc ⊑ to‿from)
        { date ⇐ 0⊑f, memo ⇐ 1⊑f, category ⇐ cat, amount ⇐ •BQN 4⊑f, plan_id ⇐ PlanId line }
      }
      parsed ← ParsePlanRow¨ plan_rows
      plan_ids ← {𝕩.plan_id}¨ parsed
      open_mask ← { ¬ ∨´ 𝕩⊸≡¨ journal_ids }¨ plan_ids
      rows_out ↩ open_mask / parsed
      rows_out ↩ (⍋ {𝕩.date}¨ rows_out) ⊏ rows_out
      planned_total ↩ Sum0 ({𝕩.amount}¨ rows_out)
      delta ↩ env_remaining - planned_total
      status ↩ (delta = 0) ⊑ "MISMATCH"‿"OK"
    }⍟has_env @

    {𝕊: status ↩ "unavailable/missing_execution_envelope"}⍟(¬ has_env) @
  }⍟(¬ disabled) @

  {
    envelope_label ⇐ env_label,
    envelope_remaining ⇐ env_remaining,
    planned_open_total ⇐ planned_total,
    delta ⇐ delta,
    status ⇐ status,
    rows ⇐ rows_out
  }
}

# ── Multi-envelope calculation ───────────────────────────────
BuildEnvelopes ← {𝕊 base‿resolved‿cy‿valid_rows:
  cfg ← conf.LoadConfig base
  life_groups ← cfg.HouseholdGroupLifeLabels @
  reserve_groups ← cfg.HouseholdGroupReserveLabels @

  as_of ← LatestActualDateInCycle ⟨base, cy⟩
  has_as_of ← ¬ unav.IsUnavailable as_of

  budget_mask ← BudgetAccountMask resolved
  kind_envelope_mask ← "envelope"⊸≡¨ resolved.kinds
  budget_indices ← (budget_mask ∧ kind_envelope_mask) / ↕ resolved.count

  cycleAvail ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  total_days ← 1
  days_left ← 0
  elapsed ← 0
  {𝕊:
    total_days ↩ 1 ⌈ (proj.DaysFromEpoch cy.end_exclusive) - proj.DaysFromEpoch cy.start
    days_left ↩ has_as_of ◶ ⟨
      {𝕊: total_days},
      {𝕊: 0 ⌈ (proj.DaysFromEpoch cy.end_exclusive) - proj.DaysFromEpoch as_of}
    ⟩ @
    elapsed ↩ has_as_of ◶ ⟨
      {𝕊: 0},
      {𝕊: 0 ⌈ 1 + (proj.DaysFromEpoch as_of) - proj.DaysFromEpoch cy.start}
    ⟩ @
  }⍟cycleAvail @

  row_layer ← {𝕩.layer_index}¨ valid_rows
  row_ak ← {𝕩.account_key_index}¨ valid_rows
  row_side ← {𝕩.side}¨ valid_rows
  row_delta ← {𝕩.delta}¨ valid_rows
  row_date ← {𝕩.date}¨ valid_rows

  CalcOne ← {𝕊 idx:
    name ← idx ⊑ resolved.accounts
    label ← BudgetLabel name
    group ← idx ⊑ resolved.budget_groups
    envelope_role ← EnvelopeRoleForIndex ⟨resolved, idx⟩

    # allocated: layer = 2 (layer_budget), ak = idx (sum all, debit+credit)
    alloc_mask ← (row_layer = 2) ∧ (row_ak = idx)
    allocated ← Sum0 (alloc_mask / row_delta)

    # spent: layer = 0 (layer_actual), debit to any account whose budget= matches
    budget_match_mask ← label⊸≡¨ resolved.budgets
    budget_match_indices ← budget_match_mask / ↕ resolved.count
    spent_mask ← (row_layer = 0) ∧ (budget_match_indices⊸IsMember¨ row_ak) ∧ ("debit"⊸≡¨ row_side)
    spent ← Sum0 (spent_mask / row_delta)

    # drawn: layer = 0 (layer_actual), credit to any account whose budget= matches
    drawn_mask ← (row_layer = 0) ∧ (budget_match_indices⊸IsMember¨ row_ak) ∧ ("credit"⊸≡¨ row_side)
    drawn ← - Sum0 (drawn_mask / row_delta)

    remaining ← allocated - (spent - drawn)
    avg_spend ← @
    {𝕊: avg_spend ↩ (elapsed > 0) ⊑ 0‿(⌊ spent ÷ elapsed) }⍟(cycleAvail ∧ has_as_of) @
    target_daily ← ⌊ allocated ÷ total_days

    # future_planned_spent (layer = 1, debit, date > as_of)
    plan_mask ← (row_layer = 1) ∧ (budget_match_indices⊸IsMember¨ row_ak) ∧ ("debit"⊸≡¨ row_side)
    {𝕊:
      is_valid_date ← (proj.IsValidDateText as_of) ∧ (∧ proj.IsValidDateText¨ row_date)
      {𝕊:
        as_of_dn ← proj.DaysFromEpoch as_of
        date_dns ← proj.DaysFromEpoch¨ row_date
        plan_mask ↩ plan_mask ∧ (date_dns > as_of_dn)
      }⍟is_valid_date @
    }⍟(has_as_of ∧ (as_of ≢ "unavailable")) @
    future_planned_spent ← Sum0 (plan_mask / row_delta)

    b ← 0 ⌈ remaining - future_planned_spent
    days_until_empty ← @
    {𝕊:
      is_valid ← (avg_spend ≢ @) ∧ (avg_spend > 0)
      {𝕊: days_until_empty ↩ 0 ⌈ ⌊ b ÷ avg_spend }⍟is_valid @
    }⍟(cycleAvail ∧ has_as_of) @

    is_execution ← envelope_role ≡ "execution"
    status ← "unknown_role"
    {𝕊:
      is_computed ← (¬is_execution) ∧ (avg_spend ≢ @)
      {𝕊:
        status ↩ (avg_spend ≥ ⌊1.5×target_daily) ⊑ ( (avg_spend > target_daily) ⊑ "SAFE"‿"WARN" )‿"SHORT"
      }⍟is_computed @
      {𝕊:
        status ↩ ExecutionStatus ⟨allocated, remaining, spent - drawn⟩
      }⍟is_execution @
    }⍟cycleAvail @
    {𝕊: status ↩ "unknown_role"}⍟(envelope_role ≡ "unknown") @

    {
      account_index ⇐ idx,
      account_name ⇐ name,
      label ⇐ label,
      group ⇐ group,
      envelope_role ⇐ envelope_role,
      allocated ⇐ allocated,
      actual_spent ⇐ spent - drawn,
      remaining ⇐ remaining,
      avg_spend ⇐ avg_spend,
      status ⇐ status,
      days_until_empty ⇐ days_until_empty
    }
  }

  CalcOne¨ budget_indices
}

# ── backing invariant calculation ───────────────────────────
ActualClosingVecFromTbds ← {𝕊 resolved‿tbds_rows:
  actual_rows ← (cube.layer_actual = {𝕩.layer_index}¨ tbds_rows) / tbds_rows
  ak_indices ← {𝕩.account_key_index}¨ actual_rows
  closings ← {𝕩.closing}¨ actual_rows
  { Sum0 ((ak_indices = 𝕩) / closings) }¨ ↕ resolved.count
}

CalcEnvelopeBacking ← {𝕊 resolved‿tbds_rows‿valid_rows‿envelopes‿unassigned:
  closing_vec ← ActualClosingVecFromTbds ⟨resolved, tbds_rows⟩
  liquid_mask ← ("asset"⊸≡¨ resolved.roles) ∧ ("liquid"⊸≡¨ resolved.types)
  funding_indices ← liquid_mask / ↕ resolved.count
  funding_base ← Sum0 (liquid_mask / closing_vec)
  active_envelope_mask ← IsActiveEnvelopeRole¨ ({𝕩.envelope_role}¨ envelopes)
  active_envelopes ← active_envelope_mask / envelopes
  allocated_total ← Sum0 ({𝕩.remaining}¨ active_envelopes)
  cash_backed_unassigned ← funding_base - allocated_total
  ledger_cash_delta ← cash_backed_unassigned - unassigned.remaining
  funding_sources ← { { name ⇐ 𝕩 ⊑ resolved.accounts, amount ⇐ 𝕩 ⊑ closing_vec } }¨ funding_indices
  active_sources ← { { name ⇐ 𝕩.label, amount ⇐ 𝕩.remaining } }¨ active_envelopes
  ledger_sources ← unassigned.sources

  row_layer ← {𝕩.layer_index}¨ valid_rows
  row_ak ← {𝕩.account_key_index}¨ valid_rows
  active_indices ← {𝕩.account_index}¨ active_envelopes
  unassigned_indices ← UnassignedBudgetAccountIndices resolved
  BudgetMovement ← {𝕊 row:
    {
      date ⇐ row.date,
      source_row ⇐ row.source_row,
      source_id ⇐ row.source_id,
      account ⇐ row.account_key_index ⊑ resolved.accounts,
      side ⇐ row.side,
      delta ⇐ row.delta
    }
  }
  active_movements ← BudgetMovement¨ ((row_layer = 2) ∧ (active_indices⊸IsMember¨ row_ak)) / valid_rows
  ledger_movements ← BudgetMovement¨ ((row_layer = 2) ∧ (unassigned_indices⊸IsMember¨ row_ak)) / valid_rows

  status ← "OK"
  {𝕊: status ↩ "MISMATCH"}⍟(ledger_cash_delta ≠ 0) @
  {𝕊: status ↩ "OVER_ALLOCATED"}⍟(cash_backed_unassigned < 0) @
  {𝕊: status ↩ unassigned.status}⍟((unav.IsUnavailable unassigned.status) ∨ ("error/" unav.StartsWith unassigned.status)) @

  {
    funding_base ⇐ funding_base,
    allocated_total ⇐ allocated_total,
    cash_backed_unassigned ⇐ cash_backed_unassigned,
    ledger_cash_delta ⇐ ledger_cash_delta,
    status ⇐ status,
    funding_sources ⇐ funding_sources,
    active_sources ⇐ active_sources,
    ledger_sources ⇐ ledger_sources,
    active_movements ⇐ active_movements,
    ledger_movements ⇐ ledger_movements
  }
}

# BuildFromInputs: pure-ish builder used by tests and Build.
# Args: ⟨target, resolved, cy, valid_rows, alloc_lines⟩
BuildFromInputs ← {𝕊 tgt‿resolved‿cy‿valid_rows‿alloc_lines:
  selected_indices ← SelectedExpenseIndices ⟨tgt, resolved⟩
  allocated ← CalcAllocated ⟨tgt, resolved, cy, alloc_lines⟩
  actual_spent ← CalcActualSpent ⟨selected_indices, valid_rows⟩
  remaining ← CalcRemaining ⟨allocated.amount, actual_spent⟩
  status ← DecideStatus ⟨tgt, selected_indices, allocated⟩
  selector ← tgt.has_policy ⊑ "unavailable/no_policy"‿(tgt.selector_key ∾ "=" ∾ tgt.selector_value)
  target_id_out ← tgt.target_id
  label_out ← tgt.label
  allocated_amount ← allocated.amount
  allocation_row_count ← allocated.row_count
  target_budget_account_count ← allocated.target_budget_account_count
  selected_expense_account_count ← ≠ selected_indices

  {
    target_id ⇐ target_id_out,
    label ⇐ label_out,
    selector ⇐ selector,
    allocated ⇐ allocated_amount,
    actual_spent ⇐ actual_spent,
    remaining ⇐ remaining,
    status ⇐ status,
    selected_expense_account_count ⇐ selected_expense_account_count,
    allocation_row_count ⇐ allocation_row_count,
    target_budget_account_count ⇐ target_budget_account_count,
    envelopes ⇐ ⟨⟩,
    unassigned_remaining ⇐ 0,
    unassigned_status ⇐ "unavailable/not_computed",
    unassigned_account_count ⇐ 0,
    funding_base ⇐ 0,
    allocated_total ⇐ 0,
    cash_backed_unassigned ⇐ 0,
    ledger_cash_delta ⇐ 0,
    backing_status ⇐ "unavailable/not_computed",
    funding_sources ⇐ ⟨⟩,
    active_sources ⇐ ⟨⟩,
    ledger_sources ⇐ ⟨⟩,
    active_movements ⇐ ⟨⟩,
    ledger_movements ⇐ ⟨⟩,
    execution_planned ⇐ { envelope_label ⇐ "", envelope_remaining ⇐ 0, planned_open_total ⇐ 0, delta ⇐ 0, status ⇐ "disabled", rows ⇐ ⟨⟩ },
    has_policy ⇐ tgt.has_policy
  }
}

# Build: compute envelope balances from context.
# Args: ctx (context namespace)
BuildCtx ← {𝕊 ctx:
  Build ⟨ctx.base, ctx.resolved, ctx.cy, ctx.cube.valid_rows, ctx.tbds⟩
}

Build ← {𝕊 base‿resolved‿cy‿valid_rows‿tbds_rows:
  cfg ← conf.LoadConfig base
  is_none ← "none" ≡ cfg.PolicyBudgetStyle @

  is_none ◶ ⟨
    { 𝕊 ⋄
      tgt ← PolicyForBase base

      envelopes ← BuildEnvelopes ⟨base, resolved, cy, valid_rows⟩

      matching_idx ← ({𝕩.label}¨ envelopes) ⊐ ⟨tgt.label⟩
      has_match ← matching_idx < ≠ envelopes

      allocated_val ← 0
      spent_val ← 0
      remaining_val ← 0
      status_val ← "unavailable/no_policy"

      {𝕊:
        env_match ← matching_idx ⊑ envelopes
        allocated_val ↩ env_match.allocated
        spent_val ↩ env_match.actual_spent
        remaining_val ↩ env_match.remaining
        status_val ↩ tgt.has_policy ⊑ "unavailable/no_policy"‿"computed"
      }⍟has_match @

      {𝕊:
        alloc_lines ← loader.ReadLinesOptional (base ∾ "/budget_alloc.tsv")
        selected_indices ← SelectedExpenseIndices ⟨tgt, resolved⟩
        allocated ← CalcAllocated ⟨tgt, resolved, cy, alloc_lines⟩
        actual_spent ← CalcActualSpent ⟨selected_indices, valid_rows⟩
        remaining ← CalcRemaining ⟨allocated.amount, actual_spent⟩

        allocated_val ↩ allocated.amount
        spent_val ↩ actual_spent
        remaining_val ↩ remaining
        status_val ↩ DecideStatus ⟨tgt, selected_indices, allocated⟩
      }⍟((¬has_match) ∧ tgt.has_policy) @

      selector ← tgt.has_policy ⊑ "unavailable/no_policy"‿(tgt.selector_key ∾ "=" ∾ tgt.selector_value)

      # Compute compatibility fields for existing test assertions
      selected_indices_tgt ← SelectedExpenseIndices ⟨tgt, resolved⟩
      selected_expense_account_count ← ≠ selected_indices_tgt

      alloc_lines_tgt ← loader.ReadLinesOptional (base ∾ "/budget_alloc.tsv")
      allocated_info_tgt ← CalcAllocated ⟨tgt, resolved, cy, alloc_lines_tgt⟩
      allocation_row_count ← allocated_info_tgt.row_count
      target_budget_account_count ← allocated_info_tgt.target_budget_account_count

      unassigned ← CalcUnassignedRemaining ⟨resolved, valid_rows⟩
      backing ← CalcEnvelopeBacking ⟨resolved, tbds_rows, valid_rows, envelopes, unassigned⟩
      execution_planned ← BuildExecutionPlannedCoverage ⟨base, cy, envelopes, cfg⟩

      {
        target_id ⇐ tgt.target_id,
        label ⇐ tgt.label,
        selector ⇐ selector,
        allocated ⇐ allocated_val,
        actual_spent ⇐ spent_val,
        remaining ⇐ remaining_val,
        status ⇐ status_val,
        envelopes ⇐ envelopes,
        order_groups ⇐ cfg.HouseholdGroupOrderLabels @,
        has_policy ⇐ tgt.has_policy,
        selected_expense_account_count ⇐ selected_expense_account_count,
        allocation_row_count ⇐ allocation_row_count,
        target_budget_account_count ⇐ target_budget_account_count,
        unassigned_remaining ⇐ unassigned.remaining,
        unassigned_status ⇐ unassigned.status,
        unassigned_account_count ⇐ unassigned.account_count,
        funding_base ⇐ backing.funding_base,
        allocated_total ⇐ backing.allocated_total,
        cash_backed_unassigned ⇐ backing.cash_backed_unassigned,
        ledger_cash_delta ⇐ backing.ledger_cash_delta,
        backing_status ⇐ backing.status,
        funding_sources ⇐ backing.funding_sources,
        active_sources ⇐ backing.active_sources,
        ledger_sources ⇐ backing.ledger_sources,
        active_movements ⇐ backing.active_movements,
        ledger_movements ⇐ backing.ledger_movements,
        execution_planned ⇐ execution_planned
      }
    },
    { 𝕊 ⋄
      {
        target_id ⇐ "disabled",
        label ⇐ "disabled",
        selector ⇐ "disabled",
        allocated ⇐ @,
        actual_spent ⇐ @,
        remaining ⇐ @,
        status ⇐ "disabled",
        envelopes ⇐ ⟨⟩,
        order_groups ⇐ ⟨⟩,
        has_policy ⇐ 0,
        selected_expense_account_count ⇐ 0,
        allocation_row_count ⇐ 0,
        target_budget_account_count ⇐ 0,
        unassigned_remaining ⇐ @,
        unassigned_status ⇐ "disabled",
        unassigned_account_count ⇐ 0,
        funding_base ⇐ @,
        allocated_total ⇐ @,
        cash_backed_unassigned ⇐ @,
        ledger_cash_delta ⇐ @,
        backing_status ⇐ "disabled",
        funding_sources ⇐ ⟨⟩,
        active_sources ⇐ ⟨⟩,
        ledger_sources ⇐ ⟨⟩,
        active_movements ⇐ ⟨⟩,
        ledger_movements ⇐ ⟨⟩,
        execution_planned ⇐ { envelope_label ⇐ @, envelope_remaining ⇐ @, planned_open_total ⇐ @, delta ⇐ @, status ⇐ "disabled", rows ⇐ ⟨⟩ }
      }
    }
  ⟩ @
}

# ── rendering / compact fields ──────────────────────────────
FmtAmount ← {𝕊 status‿amount:
  (unav.IsUnavailable status) ⊑ (•Fmt amount)‿status
}

Format ← {𝕊 s:
  out ← "--- SrcNext Envelope Computation ---" ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_target_id: " ∾ s.target_id ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_label: " ∾ s.label ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_selector: " ∾ s.selector ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_allocated: " ∾ (FmtAmount ⟨s.status, s.allocated⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_actual_spent: " ∾ (FmtAmount ⟨s.status, s.actual_spent⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_remaining: " ∾ (FmtAmount ⟨s.status, s.remaining⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_status: " ∾ s.status ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_unassigned_remaining: " ∾ (FmtAmount ⟨s.unassigned_status, s.unassigned_remaining⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_unassigned_status: " ∾ s.unassigned_status ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_unassigned_account_count: " ∾ (•Fmt s.unassigned_account_count) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_funding_base: " ∾ (FmtAmount ⟨s.backing_status, s.funding_base⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_allocated_total: " ∾ (FmtAmount ⟨s.backing_status, s.allocated_total⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_cash_backed_unassigned: " ∾ (FmtAmount ⟨s.backing_status, s.cash_backed_unassigned⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_ledger_cash_delta: " ∾ (FmtAmount ⟨s.backing_status, s.ledger_cash_delta⟩) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_backing_status: " ∾ s.backing_status ∾ (@+10)
  ep ← s.execution_planned
  out ↩ out ∾ "src_next_envelope_execution_planned_envelope: " ∾ ep.envelope_label ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_execution_planned_remaining: " ∾ (•Fmt ep.envelope_remaining) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_execution_planned_open_total: " ∾ (•Fmt ep.planned_open_total) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_execution_planned_delta: " ∾ (•Fmt ep.delta) ∾ (@+10)
  out ↩ out ∾ "src_next_envelope_execution_planned_status: " ∾ ep.status ∾ (@+10)
  {𝕊 r: out ↩ out ∾ "src_next_envelope_execution_planned_row: " ∾ r.date ∾ (@+9) ∾ r.category ∾ (@+9) ∾ r.memo ∾ (@+9) ∾ (•Fmt r.amount) ∾ (@+9) ∾ r.plan_id ∾ (@+10)}¨ ep.rows
  {𝕊 src: out ↩ out ∾ "src_next_envelope_funding_base_source: " ∾ src.name ∾ (@+9) ∾ (•Fmt src.amount) ∾ (@+10)}¨ s.funding_sources
  {𝕊 src: out ↩ out ∾ "src_next_envelope_active_remaining_source: " ∾ src.name ∾ (@+9) ∾ (•Fmt src.amount) ∾ (@+10)}¨ s.active_sources
  {𝕊 src: out ↩ out ∾ "src_next_envelope_ledger_unassigned_source: " ∾ src.name ∾ (@+9) ∾ (•Fmt src.amount) ∾ (@+10)}¨ s.ledger_sources
  MovementLine ← {𝕊 prefix‿m:
    out ↩ out ∾ prefix ∾ ": " ∾ m.date ∾ (@+9) ∾ (•Fmt m.source_row) ∾ (@+9) ∾ m.account ∾ (@+9) ∾ m.side ∾ (@+9) ∾ (•Fmt m.delta) ∾ (@+9) ∾ m.source_id ∾ (@+10)
  }
  {𝕊 m: MovementLine ⟨"src_next_envelope_active_movement", m⟩}¨ s.active_movements
  {𝕊 m: MovementLine ⟨"src_next_envelope_ledger_unassigned_movement", m⟩}¨ s.ledger_movements
  out
}

FormatHuman ← {𝕊 s:
  out ← ""
  {𝕊:
    out ↩ (L "report.envelope_section_title") ∾ (@+10) ∾ (@+10)

    order ← s.order_groups
    GetPri ← { (≠ order) ⌊ ⊑ (order ⊐ ⟨𝕩⟩) ∾ ⟨≠order⟩ }
    groups ← {𝕩.group}¨ s.envelopes
    sort_indices ← ⍋ GetPri¨ groups
    sorted_envs ← sort_indices ⊏ s.envelopes

    StatusCell ← {𝕊 st:
      raw_st ← fmt.PadV ⟨12, st⟩
      (⟨"HELD","SAFE","SAVED","DONE","WARN","SHORT","DRAWN","unknown_role"⟩ ⊐ ⟨st⟩) ⊑ ⟨fmt.Muted raw_st, fmt.Ok raw_st, fmt.Ok raw_st, fmt.Ok raw_st, fmt.Warn raw_st, fmt.Bad raw_st, fmt.Bad raw_st, fmt.Warn raw_st⟩
    }

    RenderDynamicRow ← {𝕊 e:
      pct ← (e.allocated ≠ 0) × ⌊ 0.5 + 100 × e.actual_spent ÷ (1 ⌈ e.allocated)
      row ← (" " ∾ fmt.PadV ⟨8, e.group⟩) ∾ "|" ∾ (" " ∾ fmt.PadV ⟨15, e.label⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨9, e.allocated⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨6, e.actual_spent⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨5, e.remaining⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨4, pct⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨8, e.avg_spend⟩) ∾ "|" ∾ StatusCell e.status
      out ↩ out ∾ row ∾ (@+10)
    }

    RenderExecutionRow ← {𝕊 e:
      executed ← e.actual_spent
      row ← (" " ∾ fmt.PadV ⟨8, e.group⟩) ∾ "|" ∾ (" " ∾ fmt.PadV ⟨15, e.label⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨9, e.allocated⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨8, executed⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨9, e.remaining⟩) ∾ "|" ∾ StatusCell e.status
      out ↩ out ∾ row ∾ (@+10)
    }

    RenderUnknownRow ← {𝕊 e:
      row ← (" " ∾ fmt.PadV ⟨8, e.group⟩) ∾ "|" ∾ (" " ∾ fmt.PadV ⟨15, e.label⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨9, e.allocated⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨6, e.actual_spent⟩) ∾ "|" ∾ (" " ∾ fmt.PadL ⟨5, e.remaining⟩) ∾ "|" ∾ StatusCell e.status
      out ↩ out ∾ row ∾ (@+10)
    }

    dynamic_envs ← (("dynamic"⊸≡¨ {𝕩.envelope_role}¨ sorted_envs) / sorted_envs)
    execution_envs ← (("execution"⊸≡¨ {𝕩.envelope_role}¨ sorted_envs) / sorted_envs)
    unknown_envs ← (("unknown"⊸≡¨ {𝕩.envelope_role}¨ sorted_envs) / sorted_envs)

    out ↩ out ∾ "[Dynamic envelopes]" ∾ (@+10)
    out ↩ out ∾ " group   | account        | allocated| spent |  bal |   % | avg/day | health" ∾ (@+10)
    out ↩ out ∾ "---------+----------------+----------+-------+------+-----+---------+-------------" ∾ (@+10)
    {𝕊: out ↩ out ∾ "  (none)" ∾ (@+10)}⍟(0 = ≠ dynamic_envs) @
    RenderDynamicRow¨ dynamic_envs
    out ↩ out ∾ "---------+----------------+----------+-------+------+-----+---------+-------------" ∾ (@+10) ∾ (@+10)

    out ↩ out ∾ "[Execution envelopes]" ∾ (@+10)
    out ↩ out ∾ " group   | account        | held     | executed| remaining| status" ∾ (@+10)
    out ↩ out ∾ "---------+----------------+----------+---------+----------+-------------" ∾ (@+10)
    {𝕊: out ↩ out ∾ "  (none)" ∾ (@+10)}⍟(0 = ≠ execution_envs) @
    RenderExecutionRow¨ execution_envs
    out ↩ out ∾ "---------+----------------+----------+---------+----------+-------------" ∾ (@+10) ∾ (@+10)

    {𝕊:
      out ↩ out ∾ "[Unknown role envelopes]" ∾ (@+10)
      out ↩ out ∾ " group   | account        | allocated| spent |  bal | status" ∾ (@+10)
      out ↩ out ∾ "---------+----------------+----------+-------+------+-------------" ∾ (@+10)
      RenderUnknownRow¨ unknown_envs
      out ↩ out ∾ "---------+----------------+----------+-------+------+-------------" ∾ (@+10) ∾ (@+10)
      out ↩ out ∾ "NOTE: unknown envelope_role は active envelope total に含めず、pace / execution advice もしません。" ∾ (@+10) ∾ (@+10)
    }⍟(0 < ≠ unknown_envs) @

    out ↩ out ∾ "[Unassigned]" ∾ (@+10)
    unassigned_text ← "未割当(予算台帳): " ∾ (FmtAmount ⟨s.unassigned_status, s.unassigned_remaining⟩) ∾ " (" ∾ s.unassigned_status ∾ ")"
    out ↩ out ∾ ((s.unassigned_status ≡ "OVER_ALLOCATED") ⊑ unassigned_text‿(fmt.Bad unassigned_text)) ∾ (@+10)
    {𝕊:
      out ↩ out ∾ (fmt.Bad "WARNING: 未割当がマイナスです。封筒合計が予算原資を超えている可能性があります。") ∾ (@+10)
    }⍟(s.unassigned_status ≡ "OVER_ALLOCATED") @
    out ↩ out ∾ (@+10)

    ep ← s.execution_planned
    {𝕊:
      out ↩ out ∾ "[Execution planned coverage]" ∾ (@+10)
      out ↩ out ∾ "  envelope:                 " ∾ ep.envelope_label ∾ (@+10)
      out ↩ out ∾ "  envelope remaining:       " ∾ (•Fmt ep.envelope_remaining) ∾ (@+10)
      out ↩ out ∾ "  unfinished planned total: " ∾ (•Fmt ep.planned_open_total) ∾ (@+10)
      delta_text ← "  envelope - planned:       " ∾ (•Fmt ep.delta)
      status_text ← "  status: " ∾ ep.status
      out ↩ out ∾ ((ep.status ≡ "MISMATCH") ⊑ delta_text‿(fmt.Warn delta_text)) ∾ (@+10)
      out ↩ out ∾ ((ep.status ≡ "MISMATCH") ⊑ status_text‿(fmt.Warn status_text)) ∾ (@+10)
      {𝕊:
        out ↩ out ∾ "  NOTE: readonly診断。固定費予定封筒と未了予定支払いが一致していません。自動補正しません。" ∾ (@+10)
      }⍟(ep.status ≡ "MISMATCH") @
      out ↩ out ∾ "  planned rows:" ∾ (@+10)
      {𝕊: out ↩ out ∾ "    (none)" ∾ (@+10)}⍟(0 = ≠ ep.rows) @
      {𝕊 r:
        out ↩ out ∾ "    " ∾ r.date ∾ " " ∾ (fmt.PadV ⟨12, r.category⟩) ∾ " " ∾ (fmt.PadV ⟨20, r.memo⟩) ∾ " " ∾ (fmt.PadL ⟨8, r.amount⟩) ∾ (@+10)
      }¨ ep.rows
      out ↩ out ∾ (@+10)
    }⍟(ep.status ≢ "disabled") @

    out ↩ out ∾ "[Backing check]" ∾ (@+10)
    out ↩ out ∾ "  封筒対象資金(暫定:type=liquid): " ∾ (FmtAmount ⟨s.backing_status, s.funding_base⟩) ∾ (@+10)
    out ↩ out ∾ "  active封筒残高合計:              " ∾ (FmtAmount ⟨s.backing_status, s.allocated_total⟩) ∾ (@+10)
    out ↩ out ∾ "  現金裏付け未割当:                " ∾ (FmtAmount ⟨s.backing_status, s.cash_backed_unassigned⟩) ∾ (@+10)
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Budget ledger]" ∾ (@+10)
    out ↩ out ∾ "  予算台帳未割当:                   " ∾ (FmtAmount ⟨s.unassigned_status, s.unassigned_remaining⟩) ∾ (@+10)
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Delta]" ∾ (@+10)
    delta_text ← "  現金裏付け未割当 - 予算台帳未割当: " ∾ (FmtAmount ⟨s.backing_status, s.ledger_cash_delta⟩)
    status_text ← "  status: " ∾ s.backing_status
    out ↩ out ∾ ((s.backing_status ≡ "OVER_ALLOCATED") ⊑ delta_text‿(fmt.Bad delta_text)) ∾ (@+10)
    out ↩ out ∾ ((s.backing_status ≡ "OVER_ALLOCATED") ⊑ status_text‿(fmt.Bad status_text)) ∾ (@+10)
    {𝕊:
      out ↩ out ∾ "  NOTE: readonly診断。現金裏付け未割当と予算台帳未割当が一致していません。自動補正しません。" ∾ (@+10)
    }⍟(s.backing_status ≡ "MISMATCH") @
    {𝕊:
      out ↩ out ∾ (fmt.Bad "  WARNING: 封筒残高合計が封筒対象資金を超えています。") ∾ (@+10)
    }⍟(s.backing_status ≡ "OVER_ALLOCATED") @
    out ↩ out ∾ (@+10)

    RenderSources ← {𝕊 title‿sources:
      out ↩ out ∾ title ∾ (@+10)
      {𝕊:
        out ↩ out ∾ "  (none)" ∾ (@+10)
      }⍟(0 = ≠ sources) @
      {𝕊 src:
        out ↩ out ∾ "  " ∾ (fmt.PadV ⟨28, src.name⟩) ∾ " " ∾ (fmt.PadL ⟨10, src.amount⟩) ∾ (@+10)
      }¨ sources
    }

    out ↩ out ∾ "[Backing provenance]" ∾ (@+10)
    RenderSources ⟨"  funding_base sources:", s.funding_sources⟩
    RenderSources ⟨"  active envelope remaining:", s.active_sources⟩
    RenderSources ⟨"  ledger unassigned source:", s.ledger_sources⟩
    out ↩ out ∾ (@+10)

    RenderMovements ← {𝕊 title‿movements:
      out ↩ out ∾ title ∾ (@+10)
      {𝕊:
        out ↩ out ∾ "  (none)" ∾ (@+10)
      }⍟(0 = ≠ movements) @
      {𝕊 m:
        out ↩ out ∾ "  " ∾ m.date ∾ " #" ∾ (•Fmt m.source_row) ∾ " " ∾ (fmt.PadV ⟨18, m.account⟩) ∾ " " ∾ (fmt.PadV ⟨6, m.side⟩) ∾ " " ∾ (fmt.PadL ⟨8, m.delta⟩) ∾ " " ∾ m.source_id ∾ (@+10)
      }¨ movements
    }

    out ↩ out ∾ "[Budget movement provenance]" ∾ (@+10)
    RenderMovements ⟨"  ledger unassigned movements:", s.ledger_movements⟩
    RenderMovements ⟨"  active envelope movements:", s.active_movements⟩
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Health]" ∾ (@+10)
    out ↩ out ∾ (fmt.Ok "SAFE") ∾ (L "env.safe") ∾ (@+10)
    out ↩ out ∾ (fmt.Warn "WARN") ∾ (L "env.warn") ∾ (@+10)
    out ↩ out ∾ (fmt.Bad "SHORT") ∾ (L "env.short") ∾ (@+10)
    out ↩ out ∾ (L "env.held") ∾ (@+10)
    out ↩ out ∾ (L "env.done") ∾ (@+10)
    out ↩ out ∾ (L "env.saved") ∾ (@+10)
    out ↩ out ∾ (fmt.Bad "DRAWN") ∾ (L "env.drawn") ∾ (@+10)
    out ↩ out ∾ (@+10)
  }⍟(0 < ≠ s.envelopes) @
  out
}

# FormatJson: render Envelopes as structured JSON.
FormatJson ← {𝕊 ctx:
  vm ← BuildCtx ctx

  # Helper to convert namespace to kv-pairs for Serialize
  # envelopes array of namespaces to kv-pairs
  ToEnvJson ← {𝕊 e:
    ⟨
      ⟨"account_index", e.account_index⟩,
      ⟨"account_name", e.account_name⟩,
      ⟨"label", e.label⟩,
      ⟨"group", e.group⟩,
      ⟨"envelope_role", e.envelope_role⟩,
      ⟨"allocated", e.allocated⟩,
      ⟨"actual_spent", e.actual_spent⟩,
      ⟨"remaining", e.remaining⟩,
      ⟨"avg_spend", e.avg_spend⟩,
      ⟨"days_until_empty", e.days_until_empty⟩,
      ⟨"status", e.status⟩
    ⟩
  }
  envelopes_json ← ToEnvJson¨ vm.envelopes

  unassigned_json ← ⟨
    ⟨"account_count", vm.unassigned_account_count⟩,
    ⟨"remaining", vm.unassigned_remaining⟩,
    ⟨"status", vm.unassigned_status⟩
  ⟩

  backing_json ← ⟨
    ⟨"funding_base", vm.funding_base⟩,
    ⟨"active_remaining_total", vm.allocated_total⟩,
    ⟨"cash_backed_unassigned", vm.cash_backed_unassigned⟩,
    ⟨"ledger_cash_delta", vm.ledger_cash_delta⟩,
    ⟨"status", vm.backing_status⟩
  ⟩

  # Handle execution_planned rows list and scalar fields
  ep ← vm.execution_planned
  ep_label ← { (ep.status ≡ "disabled") ? @ ; (0 = ≠ ep.envelope_label) ? @ ; ep.envelope_label }
  ep_remaining ← { (ep.status ≡ "disabled") ? @ ; ep.envelope_remaining }
  ep_planned_total ← { (ep.status ≡ "disabled") ? @ ; ep.planned_open_total }
  ep_delta ← { (ep.status ≡ "disabled") ? @ ; ep.delta }
  
  ToRowJson ← {𝕊 r:
    ⟨
      ⟨"date", r.date⟩,
      ⟨"memo", r.memo⟩,
      ⟨"category", r.category⟩,
      ⟨"amount", r.amount⟩,
      ⟨"plan_id", r.plan_id⟩
    ⟩
  }
  ep_rows_json ← ToRowJson¨ ep.rows

  execution_planned_json ← ⟨
    ⟨"envelope_label", ep_label⟩,
    ⟨"envelope_remaining", ep_remaining⟩,
    ⟨"planned_open_total", ep_planned_total⟩,
    ⟨"delta", ep_delta⟩,
    ⟨"status", ep.status⟩,
    ⟨"rows", ep_rows_json⟩
  ⟩

  root ← ⟨
    ⟨"target_id", vm.target_id⟩,
    ⟨"label", vm.label⟩,
    ⟨"selector", vm.selector⟩,
    ⟨"status", vm.status⟩,
    ⟨"has_policy", vm.has_policy⟩,
    ⟨"allocated", vm.allocated⟩,
    ⟨"actual_spent", vm.actual_spent⟩,
    ⟨"remaining", vm.remaining⟩,
    ⟨"envelopes", envelopes_json⟩,
    ⟨"unassigned", unassigned_json⟩,
    ⟨"backing", backing_json⟩,
    ⟨"execution_planned", execution_planned_json⟩
  ⟩

  json.Serialize root
}

{
  Build ⇐ BuildCtx,
  BuildFromTuple ⇐ Build,
  BuildFromInputs ⇐ BuildFromInputs,
  PolicyForBase ⇐ PolicyForBase,
  NoPolicyTarget ⇐ NoPolicyTarget,
  FixtureFoodLikeTarget ⇐ FixtureFoodLikeTarget,
  SelectedExpenseIndices ⇐ SelectedExpenseIndices,
  TargetBudgetAccountIndices ⇐ TargetBudgetAccountIndices,
  CalcAllocated ⇐ CalcAllocated,
  CalcActualSpent ⇐ CalcActualSpent,
  CalcRemaining ⇐ CalcRemaining,
  DecideStatus ⇐ DecideStatus,
  UnassignedBudgetAccountIndices ⇐ UnassignedBudgetAccountIndices,
  CalcUnassignedRemaining ⇐ CalcUnassignedRemaining,
  ActualClosingVecFromTbds ⇐ ActualClosingVecFromTbds,
  CalcEnvelopeBacking ⇐ CalcEnvelopeBacking,
  Format ⇐ Format,
  FormatHuman ⇐ FormatHuman,
  FormatJson ⇐ FormatJson,
  EnvelopeRoleForIndex ⇐ EnvelopeRoleForIndex,
  IsActiveEnvelopeRole ⇐ IsActiveEnvelopeRole,
  ExecutionStatus ⇐ ExecutionStatus
}
