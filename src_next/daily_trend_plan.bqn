# daily_trend_plan.bqn
# Checked Daily Trend plan evidence and row-local fixed reserve.
#
# Numeric ownership:
#   admitted plan.tsv Posting IR joined by stable source_row
# Evidence ownership:
#   source date and plan-ID completion identity

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
overlap ← •Import "plan_journal_overlap.bqn"

MakeDiagnostic ← {𝕊 source_row‿status‿date‿message:
  {
    source_file ⇐ "plan.tsv",
    source_row ⇐ source_row,
    status ⇐ status,
    date ⇐ date,
    message ⇐ message
  }
}

BuildEvidenceFromLines ← {𝕊 plan_lines‿journal_lines:
  plans ← {𝕊 i:
    line ← i ⊑ plan_lines
    flds ← loader.SplitTsvKeepEmpty line
    pid ← ""
    {𝕊: pid ↩ overlap.PlanId line}⍟(5 ≤ ≠ flds) @
    {
      source_row ⇐ i,
      line ⇐ line,
      flds ⇐ flds,
      date ⇐ proj.FieldOrEmpty ⟨flds, 0⟩,
      plan_id ⇐ pid,
      required_ok ⇐ 5 ≤ ≠ flds
    }
  }¨ ↕ ≠ plan_lines

  journals ← {𝕊 i:
    line ← i ⊑ journal_lines
    flds ← loader.SplitTsvKeepEmpty line
    pid ← ""
    {𝕊: pid ↩ overlap.PlanId line}⍟(5 ≤ ≠ flds) @
    {
      source_row ⇐ i,
      date ⇐ proj.FieldOrEmpty ⟨flds, 0⟩,
      plan_id ⇐ pid
    }
  }¨ ↕ ≠ journal_lines

  { plans ⇐ plans, journals ⇐ journals }
}

BuildSourceEvidence ← {𝕊 base:
  plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  journal_lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  BuildEvidenceFromLines ⟨plan_lines, journal_lines⟩
}

RowsForPlanSource ← {𝕊 rows‿source_row:
  mask ← ({𝕩.source_file ≡ "plan.tsv"}¨ rows) ∧ ({𝕩.source_row = source_row}¨ rows)
  mask / rows
}

BuildFromEvidence ← {𝕊 ctx‿trend_dates‿evidence:
  result ← {
    state ⇐ "error",
    reason ⇐ "invalid_trend_coordinate",
    diagnostics ⇐ ⟨⟩,
    reserves ⇐ ⟨⟩
  }

  dates_ok ← (0 < ≠ trend_dates) ∧ ∧´ 1 ∾ proj.IsValidDateText¨ trend_dates
  cycle_ok ← proj.IsValidDateText ctx.cy.start
  cycle_ok ↩ cycle_ok ∧ proj.IsValidDateText ctx.cy.end_exclusive

  {𝕊:
    trend_dns ← proj.DaysFromEpoch¨ trend_dates
    end_dn ← proj.DaysFromEpoch ctx.cy.end_exclusive
    diagnostics ← ⟨⟩

    {𝕊 ev:
      date_ok ← proj.IsValidDateText ev.date
      {𝕊:
        diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "invalid_date", ev.date, "invalid plan date: " ∾ ev.date⟩⟩
      }⍟(¬ date_ok) @

      {𝕊:
        p_dn ← proj.DaysFromEpoch ev.date
        applicable_rows ← (trend_dns ≤ p_dn) ∧ (p_dn < end_dn)
        applicable ← ∨´ 0 ∾ applicable_rows

        {𝕊:
          {𝕊:
            diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "missing_required_fields", ev.date, "plan source evidence requires the first five TSV fields"⟩⟩
          }⍟(¬ ev.required_ok) @

          joined ← RowsForPlanSource ⟨ctx.posting_rows, ev.source_row⟩
          join_ok ← 2 = ≠ joined
          {𝕊:
            diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "structural_join", ev.date, "plan source row does not join to exactly two Posting IR rows"⟩⟩
          }⍟(¬ join_ok) @

          {𝕊:
            rejected ← ({𝕩.status ≢ "ok"}¨ joined) / joined
            {𝕊:
              bad ← ⊑ rejected
              diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, bad.status, ev.date, bad.message⟩⟩
            }⍟(0 < ≠ rejected) @

            sides_ok ← (1 = +´ "debit"⊸≡¨ {𝕩.side}¨ joined) ∧ (1 = +´ "credit"⊸≡¨ {𝕩.side}¨ joined)
            dates_match ← ∧´ ev.date⊸≡¨ {𝕩.date}¨ joined
            layers_ok ← ∧´ proj.layer_plan = {𝕩.layer_index}¨ joined
            structure_ok ← sides_ok ∧ dates_match ∧ layers_ok
            {𝕊:
              diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "structural_join", ev.date, "joined Posting IR pair has inconsistent side, date, or layer evidence"⟩⟩
            }⍟((0 = ≠ rejected) ∧ ¬ structure_ok) @

            {𝕊:
              matching_journals ← (ev.plan_id⊸≡¨ {𝕩.plan_id}¨ evidence.journals) / evidence.journals
              invalid_journals ← (¬ proj.IsValidDateText¨ {𝕩.date}¨ matching_journals) / matching_journals
              {𝕊:
                badj ← ⊑ invalid_journals
                diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "invalid_completion_date", badj.date, "matching completion evidence has invalid date"⟩⟩
              }⍟(0 < ≠ invalid_journals) @
            }⍟((0 = ≠ rejected) ∧ structure_ok) @
          }⍟join_ok @
        }⍟applicable @
      }⍟date_ok @
    }¨ evidence.plans

    result ↩ {
      state ⇐ "error",
      reason ⇐ "rejected_plan_evidence",
      diagnostics ⇐ diagnostics,
      reserves ⇐ ⟨⟩
    }
    {𝕊:
      classes ← ctx.resolved.spend_classes ∾ ⟨""⟩
      min_dn ← ⌊´ trend_dns
      active_plans ← ({𝕊 ev: p ← proj.DaysFromEpoch ev.date ⋄ (p ≥ min_dn) ∧ (p < end_dn)}¨ evidence.plans) / evidence.plans
      ReserveAt ← {𝕊 d_dn:
        values ← {𝕊 ev:
          p_dn ← proj.DaysFromEpoch ev.date
          joined ← RowsForPlanSource ⟨ctx.posting_rows, ev.source_row⟩
          debit ← ⊑ ("debit"⊸≡¨ {𝕩.side}¨ joined) / joined
          matching ← (ev.plan_id⊸≡¨ {𝕩.plan_id}¨ evidence.journals) / evidence.journals
          completed ← ∨´ 0 ∾ {𝕊 j: (proj.DaysFromEpoch j.date) ≤ d_dn}¨ matching
          is_fixed ← (debit.account_key_index ⊑ classes) ≡ "fixed"
          open ← (d_dn ≤ p_dn) ∧ (p_dn < end_dn) ∧ ¬ completed
          (open ∧ is_fixed) × debit.delta
        }¨ active_plans
        cube.Sum0 values
      }
      result ↩ {
        state ⇐ "ok",
        reason ⇐ "daily_trend_plan_active",
        diagnostics ⇐ ⟨⟩,
        reserves ⇐ ReserveAt¨ trend_dns
      }
    }⍟(0 = ≠ diagnostics) @
  }⍟(dates_ok ∧ cycle_ok) @

  result
}

BuildAt ← {𝕊 ctx‿trend_dates:
  evidence ← BuildSourceEvidence ctx.base
  BuildFromEvidence ⟨ctx, trend_dates, evidence⟩
}

{
  BuildAt ⇐ BuildAt,
  BuildEvidenceFromLinesForTest ⇐ BuildEvidenceFromLines,
  BuildFromEvidenceForTest ⇐ BuildFromEvidence
}
