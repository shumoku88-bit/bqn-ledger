# daily_flow.bqn
# Daily Flow breakdown for src_next.
# Shows daily breakdown of income, major envelope expenses, others, and net.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text
overlap ← •Import "plan_journal_overlap.bqn"
unav ← •Import "unavailable.bqn"
env_comp ← •Import "envelope_computation.bqn"

IsMember ← { list ← 𝕨 ⋄ item ← 𝕩 ⋄ (⊑ list ⊐ ⟨item⟩) < ≠ list }

Unbox ← {
  val ← 𝕩
  (0 = ≠ ≢ val) ◶ ⟨ {val}, {>val} ⟩ @
}

TrimBudgetPrefix ← {
  val ← 𝕩
  (7 ≤ ≠ val) ◶ ⟨
    {val},
    { ("budget:" ≡ 7 ↑ val) ◶ ⟨ {val}, {7 ↓ val} ⟩ @ }
  ⟩ @
}

LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available ← (cy.start ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    end_dn ← start_dn + cy.day_count
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d: dn ← proj.DaysFromEpoch d ⋄ (dn ≥ start_dn) ∧ (dn < end_dn) }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(available ∧ (0 < ≠ lines)) @
  out
}

Build ← {𝕊 ctx:
  c3d ← ctx.cube.cube
  resolved ← ctx.resolved
  cy ← ctx.cy
  base ← ctx.base
  day_count ← cy.day_count
  ak_count ← resolved.count

  roles ← Unbox¨ resolved.roles
  accounts ← Unbox¨ resolved.accounts
  budgets ← Unbox¨ resolved.budgets
  kinds ← Unbox¨ resolved.kinds

  # 1. Identify envelopes and their matching expense accounts using explicit metadata
  kind_envelope_mask ← "envelope"⊸≡¨ kinds
  budget_indices ← kind_envelope_mask / ↕ ak_count
  
  # For each envelope, find matching expense account indices using direct budget matching
  env_expense_aks ← {𝕊 idx:
    name ← idx ⊑ accounts
    label ← TrimBudgetPrefix name
    match_mask ← { label ≡ TrimBudgetPrefix 𝕩 }¨ budgets
    

    match_indices ← match_mask / ↕ ak_count
    match_indices
  }¨ budget_indices

  # Flat list of all envelope expense account indices
  all_env_expense_ak ← ∾ env_expense_aks

  # Identify expense and income accounts using explicit roles (no prefix fallback)
  expenses_ak ← ("expense"⊸≡¨ roles) / ↕ ak_count
  other_expense_ak ← (¬ { all_env_expense_ak IsMember 𝕩 }¨ expenses_ak) / expenses_ak
  inc_ak ← ("income"⊸≡¨ roles) / ↕ ak_count

  # Layer 0 = actual
  actual_slice ← {𝕊 day: {(day‿𝕩‿0) ⊑ c3d}¨ ↕ ak_count}¨ ↕ day_count

  # Collect trend dates (same as daily_trend)
  valid_rows ← ctx.cube.valid_rows
  j_projs ← (0 = {𝕩.layer_index}¨ valid_rows) / valid_rows
  j_dates ← {𝕩.date}¨ j_projs

  as_of ← LatestActualDateInCycle ⟨base, cy⟩
  trend_dates_all ← j_dates ∾ ⟨as_of⟩
  dns ← proj.DaysFromEpoch¨ trend_dates_all
  ord ← ⍋ dns
  sorted_dates ← ord ⊏ trend_dates_all
  sorted_dns ← ord ⊏ dns
  keep ← (sorted_dns ⊐ sorted_dns) = ↕ ≠ sorted_dns
  trend_dates_uniq ← keep / sorted_dates
  trend_dns_uniq ← keep / sorted_dns
  
  cycle_start_dn ← proj.DaysFromEpoch cy.start
  cycle_end_excl_dn ← proj.DaysFromEpoch cy.end_exclusive
  valid_mask ← (trend_dns_uniq ≥ cycle_start_dn) ∧ (trend_dns_uniq < cycle_end_excl_dn)
  trend_dates ← valid_mask / trend_dates_uniq
  trend_dns ← valid_mask / trend_dns_uniq
  obs_count ← ≠ trend_dates

  # 2. Compute daily breakdowns
  trend_rows ← {𝕊 dn:
    d ← dn - cycle_start_dn
    d_safe ← 0 ⌈ d
    day_upd ← d_safe ⊑ actual_slice

    # Income (credit is negative, so negate to make it positive)
    income_val ← - cube.Sum0 { 𝕩 ⊑ day_upd }¨ inc_ak

    # Envelope expenses
    env_vals ← {𝕊 aks:
      cube.Sum0 { 𝕩 ⊑ day_upd }¨ aks
    }¨ env_expense_aks

    # Other expenses
    other_val ← cube.Sum0 { 𝕩 ⊑ day_upd }¨ other_expense_ak

    # Net = income - expenses
    total_expense ← (cube.Sum0 env_vals) + other_val
    net_val ← income_val - total_expense

    idx_in_dates ← ⊑ (trend_dns = dn) / ↕ obs_count
    date_str ← idx_in_dates ⊏ trend_dates

    ⟨date_str, income_val, env_vals, other_val, net_val⟩
  }¨ trend_dns


  env_labels ← {
    name ← 𝕩 ⊑ accounts
    TrimBudgetPrefix name
  }¨ budget_indices

  {
    trend_rows ⇐ trend_rows,
    env_labels ⇐ env_labels,
    as_of ⇐ as_of,
    cycle_start ⇐ cy.start,
    cycle_end_exclusive ⇐ cy.end_exclusive
  }
}

Format ← {𝕊 vm:
  out ← "--- SrcNext Daily Flow ---" ∾ (@+10)
  # Flat output of rows for diagnostics
  {
    r ← 𝕩
    # date_str income env_vals... other net
    env_str ← ∾ { " " ∾ •Fmt 𝕩 }¨ 2⊑r
    out ↩ out ∾ "src_next_daily_flow: " ∾ (0⊑r) ∾ " " ∾ (•Fmt (1⊑r)) ∾ env_str ∾ " " ∾ (•Fmt (3⊑r)) ∾ " " ∾ (•Fmt (4⊑r)) ∾ (@+10)
  }¨ vm.trend_rows
  out
}

FormatHuman ← {𝕊 vm:
  rows ← vm.trend_rows
  days_left ← 0 ⌈ (proj.DaysFromEpoch vm.cycle_end_exclusive) - proj.DaysFromEpoch vm.as_of

  out ← "== Daily Flow ==" ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ "cycle: " ∾ vm.cycle_start ∾ " 〜 " ∾ vm.cycle_end_exclusive ∾ " (as of " ∾ vm.as_of ∾ "; " ∾ (•Fmt days_left) ∾ " days left)" ∾ (@+10) ∾ (@+10)

  AlignR ← {𝕊 w‿x:
    val ← Unbox x
    is_str ← (0 = ≠ val) ◶ ⟨ { 2 = •Type ⊑ val }, {1} ⟩ @
    s ← is_str ◶ ⟨ {•Fmt val}, {val} ⟩ @
    ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
  }

  headers ← ⟨"date"⟩ ∾ ⟨"income"⟩ ∾ vm.env_labels ∾ ⟨"other"⟩ ∾ ⟨"net"⟩
  
  # Format header row
  date_col ← ⊑headers
  num_cols ← 1 ↓ headers
  padded_nums ← { AlignR ⟨10, 𝕩⟩ }¨ num_cols
  header_line ← date_col ∾ ∾ { " | " ∾ 𝕩 }¨ padded_nums
  
  # Build separator matching column widths
  # 10 chars for date, 10 chars for each num col
  sep ← "----------"
  num_seps ← (¯1 + ≠ headers) ⥊ ⟨"----------"⟩
  separator_line ← sep ∾ ∾ { "-+-" ∾ 𝕩 }¨ num_seps

  out ↩ out ∾ header_line ∾ (@+10) ∾ separator_line ∾ (@+10)

  FmtNum ← {
    val ← >𝕩
    # negate expense values to show as negative numbers (if non-zero)
    (val = 0) ◶ ⟨ {AlignR ⟨10, -val⟩}, {"         0"} ⟩ @
  }
  
  FmtIncome ← {
    val ← >𝕩
    (val = 0) ◶ ⟨ {AlignR ⟨10, val⟩}, {"         0"} ⟩ @
  }

  FmtNet ← {
    val ← >𝕩
    (val = 0) ◶ ⟨ {AlignR ⟨10, val⟩}, {"         0"} ⟩ @
  }

  FmtRow ← {𝕊 i:
    r ← i ⊑ rows
    date_str ← 0⊑r
    inc ← 1⊑r
    envs ← 2⊑r
    oth ← 3⊑r
    net ← 4⊑r

    # Columns: date | income | env1 | env2 | ... | other | net
    date_part ← > date_str
    inc_part ← > FmtIncome inc
    envs_part ← ∾ { " | " ∾ > FmtNum 𝕩 }¨ envs
    oth_part ← > FmtNum oth
    net_part ← > FmtNet net

    date_part ∾ " | " ∾ inc_part ∾ envs_part ∾ " | " ∾ oth_part ∾ " | " ∾ net_part ∾ ⟨@+10⟩
  }

  out ↩ out ∾ ∾ FmtRow¨ ↕ ≠ rows
  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
