# balances.bqn
# Compact nonzero actual account balances for src_next.

tbds ← •Import "tbds.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
json ← •Import "json.bqn"
loader ← •Import "loader.bqn"
ak ← •Import "account_key.bqn"
cycle ← •Import "cycle.bqn"
ctx_mod ← •Import "context.bqn"
currency_selection ← •Import "currency_selection.bqn"
currency_setup ← •Import "currency_setup.bqn"
L ← labels.Text

# Filter helpers
Filter ← {𝕊 entries‿r‿t: (({((2⊑𝕩) ≡ r) ∧ ((3⊑𝕩) ≡ t)}¨ entries) / entries) }
FilterRole ← {𝕊 entries‿r: (({(2⊑𝕩) ≡ r}¨ entries) / entries) }
SumAmount ← { 0 = ≠𝕩 ? 0 ; +´ {1⊑𝕩}¨ 𝕩 }

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

# PresentationPolicy keeps checked arithmetic scale distinct from human display
# scale. ILS is fixed at two decimals and rejects broader source precision.
PresentationPolicy ← {𝕊 selectedCurrency‿calculationScale:
  presentationScale ← (selectedCurrency ≡ "ILS") ⊑ ⟨calculationScale, 2⟩
  tooPrecise ← (selectedCurrency ≡ "ILS") ∧ (calculationScale > presentationScale)
  {
    state ⇐ tooPrecise ⊑ "ok"‿"error",
    calculation_scale ⇐ calculationScale,
    presentation_scale ⇐ presentationScale,
    message ⇐ tooPrecise ⊑ ⟨"", "ILS source precision exceeds 2 fractional digits: calculation scale " ∾ (•Fmt calculationScale)⟩
  }
}

# BuildSelected: balances-only M3 orchestration over one checked currency projection.
# DEFAULT_CURRENCY selects the view only; source currency evidence remains owned by
# the existing row/account validation seams.
BuildSelected ← {𝕊 base‿explicitCurrency:
  defaultResult ← currency_setup.ResolveDefault loader.ReadLinesOptional (base ∾ "/config.tsv")
  selection ← currency_setup.ResolveSelection ⟨defaultResult, explicitCurrency⟩
  result ← {
    state ⇐ "error", message ⇐ selection.message,
    selected_currency ⇐ "", provenance ⇐ "",
    calculation_scale ⇐ ⟨⟩, presentation_scale ⇐ ⟨⟩, entries ⇐ ⟨⟩
  }

  {𝕊:
    accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
    accountAudit ← currency_setup.AuditFile ⟨"accounts.tsv", "accounts", accountLines, selection.currency⟩
    {𝕊:
      bad ← ⊑ ({𝕩.state ≢ "ok"}¨ accountAudit.rows) / accountAudit.rows
      result ↩ {
        state ⇐ "error", message ⇐ bad.message,
        selected_currency ⇐ selection.currency, provenance ⇐ selection.provenance,
        calculation_scale ⇐ ⟨⟩, presentation_scale ⇐ ⟨⟩, entries ⇐ ⟨⟩
      }
    }⍟(accountAudit.state ≢ "ok") @

    {𝕊:
      resolved ← ak.Resolve accountLines
      cy ← cycle.ReadCycle base
      snapshot ← ctx_mod.LoadPostingSourceSnapshot base
      selected ← currency_selection.Build ⟨snapshot, resolved, cy.start, selection.currency⟩

      {𝕊:
        diagnostic ← ⊑ selected.diagnostics
        result ↩ {
          state ⇐ "error", message ⇐ diagnostic.message,
          selected_currency ⇐ selection.currency, provenance ⇐ selection.provenance,
          calculation_scale ⇐ ⟨⟩, presentation_scale ⇐ ⟨⟩, entries ⇐ ⟨⟩
        }
      }⍟(selected.state ≢ "ok") @

      {𝕊:
        calculationScale ← selected.arithmetic_currency_proof.amount_scale
        policy ← PresentationPolicy ⟨selection.currency, calculationScale⟩

        {𝕊:
          result ↩ {
            state ⇐ "error", message ⇐ policy.message,
            selected_currency ⇐ selection.currency, provenance ⇐ selection.provenance,
            calculation_scale ⇐ calculationScale,
            presentation_scale ⇐ policy.presentation_scale,
            entries ⇐ ⟨⟩
          }
        }⍟(policy.state ≢ "ok") @

        {𝕊:
          view ← ctx_mod.BuildPeriodView ⟨selected.posting_rows, resolved, cy⟩
          selectedContext ← { resolved ⇐ resolved, tbds ⇐ view.tbds }
          balanceEntries ← Build selectedContext
          selectedEntries ← ({((2⊑𝕩) ≡ "asset") ∨ ((2⊑𝕩) ≡ "liability")}¨ balanceEntries) / balanceEntries
          result ↩ {
            state ⇐ "ok", message ⇐ "",
            selected_currency ⇐ selection.currency,
            provenance ⇐ selection.provenance,
            calculation_scale ⇐ calculationScale,
            presentation_scale ⇐ policy.presentation_scale,
            entries ⇐ selectedEntries
          }
        }⍟(policy.state ≡ "ok") @
      }⍟(selected.state ≡ "ok") @
    }⍟(accountAudit.state ≡ "ok") @
  }⍟(selection.state ≡ "ok") @

  result
}

# Exact coefficient formatter. Scaling appends decimal zeroes as text, which is
# equivalent to multiplying by 10^(presentation-calculation) without overflow,
# rounding, or reinterpreting the checked coefficient.
FormatCoefficient ← {𝕊 coefficient‿calculationScale‿presentationScale‿currency:
  negative ← coefficient < 0
  scaleDelta ← presentationScale - calculationScale
  digits ← (•Fmt | coefficient) ∾ scaleDelta ⥊ '0'
  padded ← ((0 ⌈ (presentationScale + 1) - ≠digits) ⥊ '0') ∾ digits
  body ← padded
  {𝕊:
    split ← (≠padded) - presentationScale
    body ↩ (split ↑ padded) ∾ "." ∾ (split ↓ padded)
  }⍟(0 < presentationScale) @
  symbol ← (currency ≡ "ILS") ⊑ ⟨"", "₪"⟩
  (negative ⊑ ⟨"", "-"⟩) ∾ symbol ∾ body
}

ProvenanceLabel ← {𝕊 provenance:
  label ← "unknown provenance"
  {𝕊: label ↩ "ledger default"}⍟(provenance ≡ "ledger_default") @
  {𝕊: label ↩ "explicit selection"}⍟(provenance ≡ "explicit_selection") @
  label
}

# RenderHuman is shared by the legacy JPY-compatible renderer and M3 selected
# renderer. view_line is empty for the legacy path.
RenderHuman ← {𝕊 render:
  entries ← render.entries
  viewLine ← render.view_line
  liquid ← Filter ⟨entries, "asset", "liquid"⟩
  savings ← Filter ⟨entries, "asset", "savings"⟩
  investment ← Filter ⟨entries, "asset", "invest"⟩
  liabilities ← FilterRole ⟨entries, "liability"⟩
  envelopes ← FilterRole ⟨entries, "budget"⟩

  liquid_assets_total ← SumAmount liquid
  savings_total ← SumAmount savings
  investment_total ← SumAmount investment
  assets_total ← liquid_assets_total + savings_total + investment_total
  liabilities_total ← SumAmount liabilities
  net_worth ← assets_total + liabilities_total

  # Amount formatter: right-align preformatted exact text.
  FmtAmt2 ← {
    s ← render.FormatAmount 𝕩
    ((0 ⌈ 14 - ≠s) ⥊ ' ') ∾ s
  }

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

  out ← (L "balances.section_title") ∾ (@+10)
  {𝕊: out ↩ out ∾ viewLine ∾ (@+10)}⍟(0 < ≠viewLine) @
  out ↩ out ∾ (@+10)
  
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

# FormatHuman: preserve the existing integer-yen-compatible human output.
FormatHuman ← {𝕊 entries:
  LegacyAmount ← {𝕊 amount:
    s ← •Fmt amount
    { 𝕩 ≡ '¯' ? '-' ; 𝕩 }¨ s
  }
  RenderHuman { entries ⇐ entries, FormatAmount ⇐ LegacyAmount, view_line ⇐ "" }
}

# FormatSelectedHuman: selected currency/provenance/scale are explicit carrier
# fields and are never inferred from account_key text.
FormatSelectedHuman ← {𝕊 selected:
  Amount ← {𝕊 amount:
    FormatCoefficient ⟨amount, selected.calculation_scale, selected.presentation_scale, selected.selected_currency⟩
  }
  viewLine ← "Currency view: " ∾ selected.selected_currency ∾ " (" ∾ (ProvenanceLabel selected.provenance) ∾ ")"
  RenderHuman { entries ⇐ selected.entries, FormatAmount ⇐ Amount, view_line ⇐ viewLine }
}

# FormatJson: render balance entries as structured JSON.
FormatJson ← {𝕊 ctx:
  entries ← Build ctx

  BuildAccountObj ← {
    r ← 𝕩
    ⟨
      ⟨"account_key", 0⊑r⟩,
      ⟨"amount", 1⊑r⟩,
      ⟨"role", 2⊑r⟩,
      ⟨"type", 3⊑r⟩
    ⟩
  }

  accounts ← BuildAccountObj¨ entries
  accounts ↩ {𝕊: (0 = ≠ accounts) ? 0 ⥊ 0 ; accounts } @

  liquid ← Filter ⟨entries, "asset", "liquid"⟩
  savings ← Filter ⟨entries, "asset", "savings"⟩
  investment ← Filter ⟨entries, "asset", "invest"⟩
  liabilities ← FilterRole ⟨entries, "liability"⟩

  liquid_assets_total ← SumAmount liquid
  savings_total ← SumAmount savings
  investment_total ← SumAmount investment
  assets_total ← liquid_assets_total + savings_total + investment_total
  liabilities_total ← SumAmount liabilities
  net_worth ← assets_total + liabilities_total

  totals ← ⟨
    ⟨"liquid_assets_total", liquid_assets_total⟩,
    ⟨"savings_total", savings_total⟩,
    ⟨"investment_total", investment_total⟩,
    ⟨"assets_total", assets_total⟩,
    ⟨"liabilities_total", liabilities_total⟩,
    ⟨"net_worth", net_worth⟩
  ⟩

  root ← ⟨
    ⟨"accounts", accounts⟩,
    ⟨"totals", totals⟩
  ⟩

  json.Serialize root
}

{
  Build ⇐ Build,
  BuildSelected ⇐ BuildSelected,
  Format ⇐ Format,
  PresentationPolicy ⇐ PresentationPolicy,
  FormatCoefficient ⇐ FormatCoefficient,
  ProvenanceLabel ⇐ ProvenanceLabel,
  FormatHuman ⇐ FormatHuman,
  FormatSelectedHuman ⇐ FormatSelectedHuman,
  FormatJson ⇐ FormatJson
}
