# actual_snapshot.bqn
# as_of actual balance snapshot for src_next.
#
# This view is intentionally separate from TBDS/cycle movement. It reads actual
# journal rows up to an observation date and returns account balances suitable
# for Snapshot / Outlook household observation fields.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

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

BuildAt ← {𝕊 ctx‿as_of:
  resolved ← ctx.resolved
  lines ← loader.ReadLinesOptional (ctx.base ∾ "/journal.tsv")
  accounts ← resolved.accounts
  roles ← resolved.roles
  types ← resolved.types
  count ← resolved.count
  as_ok ← proj.IsValidDateText as_of
  as_dn ← 0
  {𝕊: as_dn ↩ proj.DaysFromEpoch as_of}⍟as_ok @

  RowPairs ← {𝕊 line:
    flds ← Pad5 loader.SplitTsvKeepEmpty line
    date ← 0⊑flds
    fromAcc ← 2⊑flds
    toAcc ← 3⊑flds
    amtText ← 4⊑flds
    result ← ⟨⟩
    dateOk ← proj.IsValidDateText date
    amountOk ← proj.IsIntegerText amtText
    {𝕊:
      dn ← proj.DaysFromEpoch date
      fromIdx ← ⊑ accounts ⊐ ⟨fromAcc⟩
      toIdx ← ⊑ accounts ⊐ ⟨toAcc⟩
      known ← (fromIdx < count) ∧ (toIdx < count)
      amt ← •BQN amtText
      {𝕊: result ↩ ⟨⟨fromIdx, ¯1 × amt⟩, ⟨toIdx, amt⟩⟩ }⍟(known ∧ (dn ≤ as_dn)) @
    }⍟(as_ok ∧ dateOk ∧ amountOk) @
    result
  }

  pairs ← ∾ RowPairs¨ lines
  pair_idx ← {0⊑𝕩}¨ pairs
  pair_amt ← {1⊑𝕩}¨ pairs
  amounts ← { cube.Sum0 ((pair_idx = 𝕩) / pair_amt) }¨ ↕ count

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
  liq_breakdown ← { ⟨ 𝕩 ⊑ liq_keys, 𝕩 ⊑ liq_amounts ⟩ } ¨ liq_sorted

  nz_indices ← (amounts ≠ 0) / ↕ count
  entries ← { ⟨𝕩 ⊑ resolved.account_keys, 𝕩 ⊑ amounts⟩ }¨ nz_indices

  {
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
}

Build ← {𝕊 ctx:
  BuildAt ⟨ctx, LatestActualDateInCycle ⟨ctx.base, ctx.cy⟩⟩
}

{ Build ⇐ Build, BuildAt ⇐ BuildAt, LatestActualDateInCycle ⇐ LatestActualDateInCycle }
