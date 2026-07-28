# Retained Recent Journal List result and human/compact renderers.

amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
tab ← @+9

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_recent_journal",code⇐codeText,message⇐messageText}
}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,date⇐empty,description⇐empty,currency⇐empty,coefficient⇐empty,scale⇐empty,
    credit_accounts⇐empty,debit_accounts⇐empty,transaction_reference⇐empty,
    debit_contributors⇐empty,credit_contributors⇐empty
  }
}
EmptyResult ← {𝕊 diagnosticsValue: {state⇐"error",limit⇐0,rows⇐EmptyRows @,diagnostics⇐diagnosticsValue}}

Build ← {𝕊 recentTransactions:
  result ← EmptyResult ⟨Diagnostic ⟨"recent_transactions_not_ok","Recent Transaction evidence must be ok"⟩⟩
  {𝕊:
    sourceRows ← recentTransactions.rows
    result↩{
      state⇐"ok",limit⇐recentTransactions.limit,
      rows⇐{
        count⇐sourceRows.count,index⇐sourceRows.index,date⇐sourceRows.date,description⇐sourceRows.description,
        currency⇐sourceRows.currency,coefficient⇐sourceRows.coefficient,scale⇐sourceRows.scale,
        credit_accounts⇐sourceRows.credit_accounts,debit_accounts⇐sourceRows.debit_accounts,
        transaction_reference⇐sourceRows.transaction_reference,
        debit_contributors⇐sourceRows.debit_contributors,credit_contributors⇐sourceRows.credit_contributors
      },diagnostics⇐empty
    }
  }⍟(recentTransactions.state≡"ok") @
  result
}

Join ← {𝕊 values:
  out ← ""
  {𝕊 i: out∾↩((i>0)/",")∾i⊑values}¨↕≠values
  out
}
AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
TrimMemo ← {𝕊 value:
  result ← value
  {𝕊: result↩(18↑value)∾".."}⍟((text.VWidth value)>20) @
  result
}

FormatHuman ← {𝕊 result:
  rows ← {𝕊 index:
    ⟨
      index⊑result.rows.date,Join (index⊑result.rows.credit_accounts),Join (index⊑result.rows.debit_accounts),
      TrimMemo (index⊑result.rows.description),
      AmountText ⟨index⊑result.rows.coefficient,index⊑result.rows.scale⟩,
      index⊑result.rows.currency
    ⟩
  }¨result.rows.index
  out ← "== Recent Journal =="∾(@+10)
  out ∾↩ "(newest first, last "∾(•Fmt result.limit)∾")"∾(@+10)
  {𝕊: out∾↩text.RenderTable ⟨⟨"Date","From","To","Memo","Amount","Currency"⟩,rows,⟨4⟩⟩}⍟(0<result.rows.count) @
  {𝕊: out∾↩"  (none)"∾(@+10)}⍟(0=result.rows.count) @
  out∾(@+10)
}

FormatCompact ← {𝕊 result:
  out ← "--- Ledger Recent Journal ---"∾(@+10)
  {𝕊 index:
    out∾↩"ledger_recent_journal: "∾(index⊑result.rows.date)∾tab
    out∾↩(index⊑result.rows.currency)∾tab
    out∾↩(AmountText ⟨index⊑result.rows.coefficient,index⊑result.rows.scale⟩)∾tab
    out∾↩(Join (index⊑result.rows.credit_accounts))∾tab∾(Join (index⊑result.rows.debit_accounts))∾tab
    out∾↩(index⊑result.rows.description)∾(@+10)
  }¨result.rows.index
  {𝕊: out∾↩"ledger_recent_journal: (none)"∾(@+10)}⍟(0=result.rows.count) @
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact}
