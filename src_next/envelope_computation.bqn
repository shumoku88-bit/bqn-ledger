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
  {
    account_count ⇐ cnt,
    remaining ⇐ remaining,
    status ⇐ UnassignedStatus ⟨cnt, remaining⟩
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

  total_days ← 1 ⌈ (proj.DaysFromEpoch cy.end_exclusive) - proj.DaysFromEpoch cy.start
  days_left ← has_as_of ◶ ⟨
    {𝕊: total_days},
    {𝕊: 0 ⌈ (proj.DaysFromEpoch cy.end_exclusive) - proj.DaysFromEpoch as_of}
  ⟩ @
  elapsed ← has_as_of ◶ ⟨
    {𝕊: 0},
    {𝕊: 0 ⌈ 1 + (proj.DaysFromEpoch as_of) - proj.DaysFromEpoch cy.start}
  ⟩ @

  row_layer ← {𝕩.layer_index}¨ valid_rows
  row_ak ← {𝕩.account_key_index}¨ valid_rows
  row_side ← {𝕩.side}¨ valid_rows
  row_delta ← {𝕩.delta}¨ valid_rows
  row_date ← {𝕩.date}¨ valid_rows

  CalcOne ← {𝕊 idx:
    name ← idx ⊑ resolved.accounts
    label ← BudgetLabel name
    group ← idx ⊑ resolved.budget_groups

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
    avg_spend ← (elapsed > 0) ⊑ 0‿(⌊ spent ÷ elapsed)
    target_daily ← ⌊ allocated ÷ total_days

    # future_planned_spent (layer = 1, debit, date > as_of)
    plan_mask ← (row_layer = 1) ∧ (budget_match_indices⊸IsMember¨ row_ak) ∧ ("debit"⊸≡¨ row_side)
    {𝕊:
      as_of_dn ← proj.DaysFromEpoch as_of
      date_dns ← proj.DaysFromEpoch¨ row_date
      plan_mask ↩ plan_mask ∧ (date_dns > as_of_dn)
    }⍟has_as_of @
    future_planned_spent ← Sum0 (plan_mask / row_delta)

    b ← 0 ⌈ remaining - future_planned_spent
    days_until_empty ← ((avg_spend = 0) × 999) + (avg_spend > 0) × (0 ⌈ ⌊ b ÷ avg_spend + avg_spend = 0)

    is_reserve ← reserve_groups IsMember group
    status ← is_reserve ◶ ⟨
      {𝕊:
        (avg_spend ≥ ⌊1.5×target_daily) ⊑ ( (avg_spend > target_daily) ⊑ "SAFE"‿"WARN" )‿"SHORT"
      },
      {𝕊:
        (drawn > 0) ⊑ ( (days_left = 0) ⊑ "HELD"‿"DONE" )‿"DRAWN"
      }
    ⟩ @

    {
      account_index ⇐ idx,
      account_name ⇐ name,
      label ⇐ label,
      group ⇐ group,
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

CalcEnvelopeBacking ← {𝕊 resolved‿tbds_rows‿envelopes‿unassigned:
  closing_vec ← ActualClosingVecFromTbds ⟨resolved, tbds_rows⟩
  liquid_mask ← ("asset"⊸≡¨ resolved.roles) ∧ ("liquid"⊸≡¨ resolved.types)
  funding_base ← Sum0 (liquid_mask / closing_vec)
  allocated_total ← Sum0 ({𝕩.remaining}¨ envelopes)
  cash_backed_unassigned ← funding_base - allocated_total
  ledger_cash_delta ← cash_backed_unassigned - unassigned.remaining

  status ← "OK"
  {𝕊: status ↩ "MISMATCH"}⍟(ledger_cash_delta ≠ 0) @
  {𝕊: status ↩ "OVER_ALLOCATED"}⍟(cash_backed_unassigned < 0) @
  {𝕊: status ↩ unassigned.status}⍟((unav.IsUnavailable unassigned.status) ∨ ("error/" unav.StartsWith unassigned.status)) @

  {
    funding_base ⇐ funding_base,
    allocated_total ⇐ allocated_total,
    cash_backed_unassigned ⇐ cash_backed_unassigned,
    ledger_cash_delta ⇐ ledger_cash_delta,
    status ⇐ status
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
      backing ← CalcEnvelopeBacking ⟨resolved, tbds_rows, envelopes, unassigned⟩

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
        backing_status ⇐ backing.status
      }
    },
    { 𝕊 ⋄
      {
        target_id ⇐ "disabled",
        label ⇐ "disabled",
        selector ⇐ "disabled",
        allocated ⇐ 0,
        actual_spent ⇐ 0,
        remaining ⇐ 0,
        status ⇐ "disabled",
        envelopes ⇐ ⟨⟩,
        order_groups ⇐ ⟨⟩,
        has_policy ⇐ 0,
        selected_expense_account_count ⇐ 0,
        allocation_row_count ⇐ 0,
        target_budget_account_count ⇐ 0,
        unassigned_remaining ⇐ 0,
        unassigned_status ⇐ "disabled",
        unassigned_account_count ⇐ 0,
        funding_base ⇐ 0,
        allocated_total ⇐ 0,
        cash_backed_unassigned ⇐ 0,
        ledger_cash_delta ⇐ 0,
        backing_status ⇐ "disabled"
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

    out ↩ out ∾ " group   | account        | allocated| spent |  bal |   % | avg/day | health" ∾ (@+10)
    out ↩ out ∾ "---------+----------------+----------+-------+------+-----+---------+--------" ∾ (@+10)

    RenderRow ← {
      pct ← (𝕩.allocated ≠ 0) × ⌊ 0.5 + 100 × 𝕩.actual_spent ÷ (1 ⌈ 𝕩.allocated)
      
      grp_cell ← " " ∾ fmt.PadV ⟨8, 𝕩.group⟩
      name_cell ← " " ∾ fmt.PadV ⟨15, 𝕩.label⟩
      alloc_cell ← " " ∾ fmt.PadL ⟨9, 𝕩.allocated⟩
      spent_cell ← " " ∾ fmt.PadL ⟨6, 𝕩.actual_spent⟩
      bal_cell ← " " ∾ fmt.PadL ⟨5, 𝕩.remaining⟩
      pct_cell ← " " ∾ fmt.PadL ⟨4, pct⟩
      avg_cell ← " " ∾ fmt.PadL ⟨8, 𝕩.avg_spend⟩
      raw_st ← fmt.PadV ⟨7, 𝕩.status⟩
      st_cell ← (⟨"HELD","SAFE","SAVED","DONE","WARN","SHORT","DRAWN"⟩ ⊐ ⟨𝕩.status⟩) ⊑ ⟨fmt.Muted raw_st, fmt.Ok raw_st, fmt.Ok raw_st, fmt.Ok raw_st, fmt.Warn raw_st, fmt.Bad raw_st, fmt.Bad raw_st⟩

      out ↩ out ∾ grp_cell ∾ "|" ∾ name_cell ∾ "|" ∾ alloc_cell ∾ "|" ∾ spent_cell ∾ "|" ∾ bal_cell ∾ "|" ∾ pct_cell ∾ "|" ∾ avg_cell ∾ "|" ∾ st_cell ∾ (@+10)
    }

    RenderRow¨ sorted_envs
    out ↩ out ∾ "---------+----------------+----------+-------+------+-----+---------+--------" ∾ (@+10)
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Budget pool]" ∾ (@+10)
    unassigned_text ← "未割当(予算台帳): " ∾ (FmtAmount ⟨s.unassigned_status, s.unassigned_remaining⟩) ∾ " (" ∾ s.unassigned_status ∾ ")"
    out ↩ out ∾ ((s.unassigned_status ≡ "OVER_ALLOCATED") ⊑ unassigned_text‿(fmt.Bad unassigned_text)) ∾ (@+10)
    {𝕊:
      out ↩ out ∾ (fmt.Bad "WARNING: 未割当がマイナスです。封筒合計が予算原資を超えている可能性があります。") ∾ (@+10)
    }⍟(s.unassigned_status ≡ "OVER_ALLOCATED") @
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Backing check]" ∾ (@+10)
    out ↩ out ∾ "  封筒対象資金(暫定:type=liquid): " ∾ (FmtAmount ⟨s.backing_status, s.funding_base⟩) ∾ (@+10)
    out ↩ out ∾ "  active封筒残高合計:              " ∾ (FmtAmount ⟨s.backing_status, s.allocated_total⟩) ∾ (@+10)
    out ↩ out ∾ "  cash-backed未割当:               " ∾ (FmtAmount ⟨s.backing_status, s.cash_backed_unassigned⟩) ∾ (@+10)
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Budget ledger]" ∾ (@+10)
    out ↩ out ∾ "  予算台帳未割当:                   " ∾ (FmtAmount ⟨s.unassigned_status, s.unassigned_remaining⟩) ∾ (@+10)
    out ↩ out ∾ (@+10)

    out ↩ out ∾ "[Delta]" ∾ (@+10)
    delta_text ← "  cash-backed - ledger:              " ∾ (FmtAmount ⟨s.backing_status, s.ledger_cash_delta⟩)
    status_text ← "  status: " ∾ s.backing_status
    out ↩ out ∾ ((s.backing_status ≡ "OK") ⊑ (fmt.Bad delta_text)‿delta_text) ∾ (@+10)
    out ↩ out ∾ ((s.backing_status ≡ "OK") ⊑ (fmt.Bad status_text)‿status_text) ∾ (@+10)
    {𝕊:
      out ↩ out ∾ (fmt.Warn "  NOTE: readonly診断。cash-backed未割当と予算台帳未割当が一致していません。自動補正しません。") ∾ (@+10)
    }⍟(s.backing_status ≡ "MISMATCH") @
    {𝕊:
      out ↩ out ∾ (fmt.Bad "  WARNING: 封筒残高合計が封筒対象資金を超えています。") ∾ (@+10)
    }⍟(s.backing_status ≡ "OVER_ALLOCATED") @
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
  FormatHuman ⇐ FormatHuman
}
