# actual_snapshot.bqn
# Explicit-O actual balance snapshot for src_next.
#
# Numeric ownership:
#   checked ledger-wide Posting IR -> local [O,O+1) actual-layer TBDS closing
# Evidence ownership:
#   checked posting source identity for rejected-row applicability/diagnostics
#
# The resulting balance is ledger-cumulative through inclusive O. It is not
# cycle-bounded movement: pre-cycle history remains opening balance evidence.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
date ← •Import "date.bqn"
cube ← •Import "cube.bqn"
tbds ← •Import "tbds.bqn"

LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d: dn ← proj.DaysFromEpoch d ⋄ (dn ≥ start_dn) ∧ (dn < end_dn) }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(available ∧ (0 < ≠ lines)) @
  out
}

EmptyErrorVm ← {𝕊 as_of‿reason‿diagnostics:
  {
    state ⇐ "error",
    reason ⇐ reason,
    diagnostics ⇐ diagnostics,
    as_of ⇐ as_of,
    amounts ⇐ ⟨⟩,
    entries ⇐ ⟨⟩,
    liq_total ⇐ "unavailable",
    sav_total ⇐ "unavailable",
    inv_total ⇐ "unavailable",
    assets_total ⇐ "unavailable",
    liabilities_total ⇐ "unavailable",
    net_worth ⇐ "unavailable",
    liq_breakdown ⇐ ⟨⟩
  }
}

IsJournalActual ← {𝕊 row:
  (row.source_file ≡ "journal.tsv") ∧ (row.layer_index = cube.layer_actual)
}

RejectedDiagnostics ← {𝕊 rows‿as_dn:
  rejected ← ((IsJournalActual¨ rows) ∧ ({𝕩.status ≢ "ok"}¨ rows)) / rows
  Applies ← {𝕊 row:
    valid_date ← proj.IsValidDateText row.date
    applies ← ¬ valid_date
    {𝕊: applies ↩ (proj.DaysFromEpoch row.date) ≤ as_dn}⍟valid_date @
    applies
  }
  applicable ← (Applies¨ rejected) / rejected
  ids ← {𝕩.source_file ∾ ":" ∾ (•Fmt 𝕩.source_row)}¨ applicable
  unique ← ((ids ⊐ ids) = ↕ ≠ ids) / applicable
  {𝕊 row:
    {
      source_file ⇐ row.source_file,
      source_row ⇐ row.source_row,
      status ⇐ row.status,
      date ⇐ row.date,
      message ⇐ row.message
    }
  }¨ unique
}

BuildAt ← {𝕊 ctx‿as_of:
  vm ← EmptyErrorVm ⟨as_of, "invalid_observation", ⟨⟩⟩
  as_ok ← proj.IsValidDateText as_of

  {𝕊:
    resolved ← ctx.resolved
    rows ← ctx.posting_rows
    as_dn ← proj.DaysFromEpoch as_of
    diagnostics ← RejectedDiagnostics ⟨rows, as_dn⟩
    vm ↩ EmptyErrorVm ⟨as_of, "rejected_actual_evidence", diagnostics⟩

    {𝕊:
      actual_rows ← (IsJournalActual¨ rows) / rows
      local_end ← date.AddDays ⟨as_of, 1⟩
      local_cy ← {
        mode ⇐ "actual_snapshot_local",
        start ⇐ as_of,
        end_exclusive ⇐ local_end,
        day_count ⇐ 1
      }
      local_tbds ← tbds.Build ⟨actual_rows, ctx.cube, resolved, local_cy⟩
      actual_tbds ← tbds.RowsForLayer ⟨cube.layer_actual, local_tbds⟩
      amounts ← {𝕩.closing}¨ actual_tbds

      roles ← resolved.roles
      types ← resolved.types
      count ← resolved.count
      assets_mask ← "asset"⊸≡¨ roles
      liabilities_mask ← "liability"⊸≡¨ roles
      liq_mask ← assets_mask ∧ ("liquid"⊸≡¨ types)
      sav_mask ← assets_mask ∧ ("savings"⊸≡¨ types)
      inv_mask ← assets_mask ∧ ("invest"⊸≡¨ types)

      liq_total ← cube.Sum0 (liq_mask / amounts)
      sav_total ← cube.Sum0 (sav_mask / amounts)
      inv_total ← cube.Sum0 (inv_mask / amounts)
      assets_total ← liq_total + sav_total + inv_total
      liabilities_total ← cube.Sum0 (liabilities_mask / amounts)
      net_worth ← assets_total + liabilities_total

      liq_indices ← (liq_mask ∧ (amounts ≠ 0)) / ↕ count
      liq_keys ← liq_indices ⊏ resolved.account_keys
      liq_amounts ← liq_indices ⊏ amounts
      liq_sorted ← ⌽⍋liq_amounts
      liq_breakdown ← {⟨𝕩 ⊑ liq_keys, 𝕩 ⊑ liq_amounts⟩}¨ liq_sorted

      nz_indices ← (amounts ≠ 0) / ↕ count
      entries ← {⟨𝕩 ⊑ resolved.account_keys, 𝕩 ⊑ amounts⟩}¨ nz_indices

      vm ↩ {
        state ⇐ "ok",
        reason ⇐ "snapshot_active",
        diagnostics ⇐ ⟨⟩,
        as_of ⇐ as_of,
        amounts ⇐ amounts,
        entries ⇐ entries,
        liq_total ⇐ liq_total,
        sav_total ⇐ sav_total,
        inv_total ⇐ inv_total,
        assets_total ⇐ assets_total,
        liabilities_total ⇐ liabilities_total,
        net_worth ⇐ net_worth,
        liq_breakdown ⇐ liq_breakdown
      }
    }⍟(0 = ≠ diagnostics) @
  }⍟as_ok @

  vm
}

Build ← {𝕊 ctx:
  BuildAt ⟨ctx, LatestActualDateInCycle ⟨ctx.base, ctx.cy⟩⟩
}

{ Build ⇐ Build, BuildAt ⇐ BuildAt, LatestActualDateInCycle ⇐ LatestActualDateInCycle }
