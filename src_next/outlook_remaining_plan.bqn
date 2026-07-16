# outlook_remaining_plan.bqn
# Checked remaining-plan monetary projection for Outlook Slice B.
#
# Numeric ownership:
#   admitted plan.tsv Posting IR joined by source_row
# Evidence ownership:
#   plan source metadata and plan_rows plan-ID completion identity

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
plan_rows ← •Import "plan_rows.bqn"

IsMember ← { list ← 𝕨 ⋄ item ← 𝕩 ⋄ (⊑ list ⊐ ⟨item⟩) < ≠ list }

MakeDiagnostic ← {𝕊 source_row‿status‿date‿message:
  {
    source_file ⇐ "plan.tsv",
    source_row ⇐ source_row,
    status ⇐ status,
    date ⇐ date,
    message ⇐ message
  }
}

BuildEvidenceFromLines ← {𝕊 plan_lines‿journal_lines‿cy:
  JournalInCycle ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    d ← proj.FieldOrEmpty ⟨flds, 0⟩
    ok ← proj.IsValidDateText d
    r ← 0
    {𝕊:
      dn ← proj.DaysFromEpoch d
      r ↩ (dn ≥ proj.DaysFromEpoch cy.start) ∧ (dn < proj.DaysFromEpoch cy.end_exclusive)
    }⍟ok @
    r
  }
  journal_cycle_lines ← (JournalInCycle¨ journal_lines) / journal_lines
  journal_plan_ids ← plan_rows.PlanId¨ journal_cycle_lines

  {𝕊 i:
    line ← i ⊑ plan_lines
    flds ← loader.SplitTsvKeepEmpty line
    pid ← plan_rows.PlanId line
    completed ← ∨´ 0 ∾ (pid⊸≡¨ journal_plan_ids)
    {
      source_row ⇐ i,
      line ⇐ line,
      flds ⇐ flds,
      date ⇐ proj.FieldOrEmpty ⟨flds, 0⟩,
      plan_id ⇐ pid,
      completed ⇐ completed
    }
  }¨ ↕ ≠ plan_lines
}

BuildSourceEvidence ← {𝕊 base‿cy:
  plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  journal_lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  BuildEvidenceFromLines ⟨plan_lines, journal_lines, cy⟩
}

AnchorInfo ← {𝕊 flds:
  metas ← 5 ↓ flds
  pref ← "anchor="
  plen ← ≠ pref
  hits ← ({𝕊 meta: (plen ≤ ≠ meta) ∧ pref ≡ plen ↑ meta}¨ metas) / metas
  state ← "none"
  status ← ""
  value ← ""
  message ← ""

  {𝕊:
    value ↩ plen ↓ ⊑ hits
    state ↩ "ok"
    {𝕊:
      state ↩ "error"
      status ↩ "empty_anchor"
      message ↩ "anchor metadata requires one nonempty income account"
    }⍟(0 = ≠ value) @
  }⍟(1 = ≠ hits) @

  {𝕊:
    state ↩ "error"
    status ↩ "duplicate_anchor"
    message ↩ "duplicate anchor metadata"
  }⍟(1 < ≠ hits) @

  { state ⇐ state, status ⇐ status, value ⇐ value, message ⇐ message }
}

ActiveIncomeAccounts ← {𝕊 ctx‿as_of:
  rows ← ctx.posting_rows
  cy ← ctx.cy
  start_dn ← proj.DaysFromEpoch cy.start
  end_dn ← proj.DaysFromEpoch cy.end_exclusive
  as_dn ← proj.DaysFromEpoch as_of
  roles ← ctx.resolved.roles
  roles_with_sentinel ← roles ∾ ⟨""⟩
  accounts ← ctx.resolved.accounts

  IsActive ← {𝕊 row:
    valid_date ← proj.IsValidDateText row.date
    active ← 0
    {𝕊:
      dn ← proj.DaysFromEpoch row.date
      idx ← row.account_key_index
      role ← idx ⊑ roles_with_sentinel
      active ↩ (row.source_file ≡ "journal.tsv") ∧
        (row.layer_index = proj.layer_actual) ∧
        (row.status ≡ "ok") ∧
        (row.side ≡ "credit") ∧
        (role ≡ "income") ∧
        (dn ≥ start_dn) ∧ (dn ≤ as_dn) ∧ (dn < end_dn)
    }⍟valid_date @
    active
  }

  active_rows ← (IsActive¨ rows) / rows
  {𝕩.account_key_index ⊑ accounts}¨ active_rows
}

AnchorValidity ← {𝕊 resolved‿anchor:
  accounts ← resolved.accounts
  roles ← resolved.roles
  matches ← anchor⊸≡¨ accounts
  idxs ← matches / ↕ ≠ accounts
  state ← "error"
  status ← "unknown_anchor"
  message ← "anchor account is unknown or not unique: " ∾ anchor
  idx ← ¯1

  {𝕊:
    idx ↩ ⊑ idxs
    state ↩ "ok"
    status ↩ ""
    message ↩ ""
    {𝕊:
      state ↩ "error"
      status ↩ "non_income_anchor"
      message ↩ "anchor account does not have role=income: " ∾ anchor
    }⍟((idx ⊑ roles) ≢ "income") @
  }⍟(1 = ≠ idxs) @

  { state ⇐ state, status ⇐ status, message ⇐ message, account_index ⇐ idx }
}

RowsForPlanSource ← {𝕊 rows‿source_row:
  mask ← ({𝕩.source_file ≡ "plan.tsv"}¨ rows) ∧ ({𝕩.source_row = source_row}¨ rows)
  mask / rows
}

PlanLiquidDelta ← {𝕊 resolved‿rows:
  types ← resolved.types
  types_with_sentinel ← types ∾ ⟨""⟩
  deltas ← {𝕩.delta}¨ rows
  liquid_mask ← {𝕊 row: (row.account_key_index ⊑ types_with_sentinel) ≡ "liquid" }¨ rows
  cube.Sum0 (liquid_mask / deltas)
}

BuildFromEvidence ← {𝕊 ctx‿as_of‿evidence:
  result ← {
    state ⇐ "error",
    reason ⇐ "invalid_observation",
    diagnostics ⇐ ⟨⟩,
    future_planned_liquid_net ⇐ "unavailable",
    planned_future_income ⇐ "unavailable",
    fixed_reserve ⇐ "unavailable"
  }

  {𝕊:
    cy ← ctx.cy
    as_dn ← proj.DaysFromEpoch as_of
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    active_incomes ← ActiveIncomeAccounts ⟨ctx, as_of⟩
    diagnostics ← ⟨⟩
    deltas ← ⟨⟩

    {𝕊 ev:
      d ← ev.date
      date_ok ← proj.IsValidDateText d

      {𝕊:
        diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "invalid_date", d, "invalid date: " ∾ d⟩⟩
      }⍟(¬ date_ok) @

      {𝕊:
        dn ← proj.DaysFromEpoch d
        in_horizon ← (dn ≥ as_dn) ∧ (dn < end_dn)
        applicable ← in_horizon ∧ (¬ ev.completed)

        {𝕊:
          joined ← RowsForPlanSource ⟨ctx.posting_rows, ev.source_row⟩
          join_ok ← 2 = ≠ joined

          {𝕊:
            diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "structural_join", d, "plan source row does not join to exactly two posting rows"⟩⟩
          }⍟(¬ join_ok) @

          {𝕊:
            rejected ← ({𝕩.status ≢ "ok"}¨ joined) / joined
            {𝕊:
              bad ← ⊑ rejected
              diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, bad.status, d, bad.message⟩⟩
            }⍟(0 < ≠ rejected) @

            {𝕊:
              anchor ← AnchorInfo ev.flds
              {𝕊:
                diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, anchor.status, d, anchor.message⟩⟩
              }⍟(anchor.state ≡ "error") @

              {𝕊:
                anchor_ok ← 1
                anchor_active ← 1
                {𝕊:
                  validity ← AnchorValidity ⟨ctx.resolved, anchor.value⟩
                  anchor_ok ↩ validity.state ≡ "ok"
                  anchor_active ↩ active_incomes IsMember anchor.value
                  {𝕊:
                    diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, validity.status, d, validity.message⟩⟩
                  }⍟(¬ anchor_ok) @
                }⍟(anchor.state ≡ "ok") @

                {𝕊:
                  delta ← PlanLiquidDelta ⟨ctx.resolved, joined⟩
                  include ← delta ≤ 0
                  {𝕊: include ↩ (anchor.state ≡ "none") ∨ anchor_active}⍟(delta > 0) @
                  {𝕊: deltas ↩ deltas ∾ ⟨delta⟩}⍟include @
                }⍟anchor_ok @
              }⍟(anchor.state ≢ "error") @
            }⍟(0 = ≠ rejected) @
          }⍟join_ok @
        }⍟applicable @
      }⍟date_ok @
    }¨ evidence

    result ↩ {
      state ⇐ "error",
      reason ⇐ "rejected_plan_evidence",
      diagnostics ⇐ diagnostics,
      future_planned_liquid_net ⇐ "unavailable",
      planned_future_income ⇐ "unavailable",
      fixed_reserve ⇐ "unavailable"
    }

    {𝕊:
      net ← cube.Sum0 deltas
      inflows ← cube.Sum0 (0⌈deltas)
      expenses ← cube.Sum0 (0⌊deltas)
      result ↩ {
        state ⇐ "ok",
        reason ⇐ "remaining_plan_active",
        diagnostics ⇐ ⟨⟩,
        future_planned_liquid_net ⇐ net,
        planned_future_income ⇐ inflows,
        fixed_reserve ⇐ ¯1 × expenses
      }
    }⍟(0 = ≠ diagnostics) @
  }⍟(proj.IsValidDateText as_of) @

  result
}

BuildAt ← {𝕊 ctx‿as_of:
  evidence ← BuildSourceEvidence ⟨ctx.base, ctx.cy⟩
  BuildFromEvidence ⟨ctx, as_of, evidence⟩
}

{
  BuildAt ⇐ BuildAt,
  BuildEvidenceFromLinesForTest ⇐ BuildEvidenceFromLines,
  BuildFromEvidenceForTest ⇐ BuildFromEvidence
}
