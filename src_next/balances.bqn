# balances.bqn
# Compact nonzero actual account balances for src_next.

tbds ← •Import "tbds.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# Build: extract nonzero actual closing balances from context.
# Args: ctx (context namespace with ctx.tbds)
# Returns: 1D array of ⟨account_key, amount⟩ pairs for nonzero accounts.
Build ← {𝕊 ctx:
  resolved ← ctx.resolved
  nz ← tbds.NonzeroActualBalances ctx.tbds
  
  # helper to lookup role & type
  GetInfo ← {
    key ← 𝕩.account_key
    amount ← 𝕩.closing
    idx ← ⊑ (key ⊸ ≡¨ resolved.account_keys) ⊐ 1
    
    # default metadata
    role ← { (idx < resolved.count) ? (idx ⊑ resolved.roles) ; "" }
    type ← { (idx < resolved.count) ? (idx ⊑ resolved.types) ; "" }
    account ← { (idx < resolved.count) ? (idx ⊑ resolved.accounts) ; key }
    
    role2 ← { (0 < ≠ role) ? role ; "unknown" }
    
    ⟨key, amount, role2, type⟩
  }
  
  GetInfo¨ nz
}

# Format: render balance entries as compact machine-readable text.
Format ← {𝕊 entries:
  out ← "--- SrcNext Balances ---" ∾ (@+10)
  {
    out ↩ out ∾ "src_next_balance: " ∾ (0⊑𝕩) ∾ " " ∾ (•Fmt (1⊑𝕩)) ∾ (@+10)
  }¨ entries
  {𝕊: out ↩ out ∾ "src_next_balance: (none) 0" ∾ (@+10)}⍟(0 = ≠ entries) @
  out
}

# FormatHuman: render balance entries as human-readable text.
FormatHuman ← {𝕊 entries:
  # Filter helpers
  Filter ← {𝕊 r‿t: (({((2⊑𝕩) ≡ r) ∧ ((3⊑𝕩) ≡ t)}¨ entries) / entries) }
  FilterRole ← {𝕊 r: (({(2⊑𝕩) ≡ r}¨ entries) / entries) }
  SumAmount ← { 0 = ≠𝕩 ? 0 ; +´ {1⊑𝕩}¨ 𝕩 }

  liquid ← Filter ⟨"asset", "liquid"⟩
  savings ← Filter ⟨"asset", "savings"⟩
  investment ← Filter ⟨"asset", "invest"⟩
  liabilities ← FilterRole "liability"
  envelopes ← FilterRole "budget"

  liquid_assets_total ← SumAmount liquid
  savings_total ← SumAmount savings
  investment_total ← SumAmount investment
  assets_total ← liquid_assets_total + savings_total + investment_total
  liabilities_total ← SumAmount liabilities
  net_worth ← assets_total + liabilities_total

  # Amount formatter: convert ¯ to -
  FmtAmt2 ← { s ← fmt.PadL ⟨14, 𝕩⟩ ⋄ { 𝕩 ≡ '¯' ? '-' ; 𝕩 }¨ s }

  FormatTableGroup ← {
    (0 = ≠𝕩) ? "" ;
    hdr ← "account_key                       |        balance" ∾ (@+10)
    div ← "----------------------------------+---------------" ∾ (@+10)
    rows ← {
      key ← 0⊑𝕩 ⋄ amt ← 1⊑𝕩
      padded_key ← fmt.PadV ⟨34, key⟩
      formatted_amt ← FmtAmt2 amt
      padded_key ∾ "|" ∾ " " ∾ formatted_amt ∾ (@+10)
    }¨ 𝕩
    hdr ∾ div ∾ ∾ rows
  }

  out ← (L "balances.section_title") ∾ (@+10) ∾ (@+10)
  
  tbl_liq ← FormatTableGroup liquid
  out ↩ out ∾ (0 < ≠tbl_liq) ◶ ⟨{""}, {"[Assets / Liquid]" ∾ (@+10) ∾ tbl_liq ∾ (@+10)}⟩ @
  
  tbl_sav ← FormatTableGroup savings
  out ↩ out ∾ (0 < ≠tbl_sav) ◶ ⟨{""}, {"[Assets / Savings]" ∾ (@+10) ∾ tbl_sav ∾ (@+10)}⟩ @
  
  tbl_inv ← FormatTableGroup investment
  out ↩ out ∾ (0 < ≠tbl_inv) ◶ ⟨{""}, {"[Assets / Investment]" ∾ (@+10) ∾ tbl_inv ∾ (@+10)}⟩ @

  tbl_lia ← FormatTableGroup liabilities
  out ↩ out ∾ (0 < ≠tbl_lia) ◶ ⟨{""}, {"[Liabilities]" ∾ (@+10) ∾ tbl_lia ∾ (@+10)}⟩ @

  tbl_env ← FormatTableGroup envelopes
  out ↩ out ∾ (0 < ≠tbl_env) ◶ ⟨{""}, {"[Budget / Envelopes]" ∾ (@+10) ∾ tbl_env ∾ (@+10)}⟩ @

  FormatTotalRow ← {𝕊 name‿val:
    padded_name ← fmt.PadV ⟨34, name⟩
    formatted_val ← FmtAmt2 val
    padded_name ∾ "|" ∾ " " ∾ formatted_val ∾ (@+10)
  }
  
  tot ← "[Totals]" ∾ (@+10)
  tot ↩ tot ∾ "name                              |        balance" ∾ (@+10)
  tot ↩ tot ∾ "----------------------------------+---------------" ∾ (@+10)
  tot ↩ tot ∾ FormatTotalRow ⟨"liquid_assets_total", liquid_assets_total⟩
  tot ↩ tot ∾ FormatTotalRow ⟨"savings_total", savings_total⟩
  tot ↩ tot ∾ FormatTotalRow ⟨"investment_total", investment_total⟩
  tot ↩ tot ∾ FormatTotalRow ⟨"assets_total", assets_total⟩
  tot ↩ tot ∾ FormatTotalRow ⟨"liabilities_total", liabilities_total⟩
  tot ↩ tot ∾ FormatTotalRow ⟨"net_worth", net_worth⟩
  
  out ↩ out ∾ tot ∾ (@+10)
  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
