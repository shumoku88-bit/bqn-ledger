# Retained source-ordered open Issues List and human-only renderer.

amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
lf ← @+10
TrimRight ← {𝕊 line:(1+⌈´¯1∾(line≠' ')/↕≠line)↑line}
TrimTable ← {𝕊 table:
  lines ← {(lf≠𝕩)/𝕩}¨(+`lf=table)⊔table
  1↓∾lf⊸∾¨TrimRight¨lines
}

EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,issue_id⇐empty,status⇐empty,date⇐empty,due⇐empty,due_ordinal⇐empty,
    category⇐empty,title⇐empty,amount_present⇐empty,coefficient⇐empty,scale⇐empty,currency⇐empty,details⇐empty,
    source_row⇐empty,source_ref⇐empty
  }
}
EmptyResult ← {𝕊 diagnostics:
  {state⇐"error",selection⇐"open",issues⇐EmptyRows @,diagnostics⇐diagnostics}
}

Build ← {𝕊 admission:
  result ← EmptyResult admission.diagnostics
  {𝕊:
    source ← admission.issues
    selected ← ("open"⊸≡¨source.status)/source.index
    result↩{
      state⇐"ok",selection⇐"open",
      issues⇐{
        count⇐≠selected,index⇐↕≠selected,
        issue_id⇐selected⊏source.issue_id,status⇐selected⊏source.status,date⇐selected⊏source.date,
        due⇐selected⊏source.due,due_ordinal⇐selected⊏source.due_ordinal,
        category⇐selected⊏source.category,title⇐selected⊏source.title,
        amount_present⇐selected⊏source.amount_present,coefficient⇐selected⊏source.coefficient,
        scale⇐selected⊏source.scale,currency⇐selected⊏source.currency,details⇐selected⊏source.details,
        source_row⇐selected⊏source.source_row,source_ref⇐selected⊏source.source_ref
      },diagnostics⇐empty
    }
  }⍟(admission.state≡"ok") @
  result
}

FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  rows ← {𝕊 i:
    date ← i⊑result.issues.date ⋄ {𝕊:date↩"—"}⍟(0=≠date) @
    amountText ← "—"
    {𝕊:
      amountText↩(text.FormatAmount ⟨i⊑result.issues.coefficient,i⊑result.issues.scale,style⟩)∾" "∾i⊑result.issues.currency
    }⍟(i⊑result.issues.amount_present) @
    ⟨date,i⊑result.issues.due,i⊑result.issues.category,i⊑result.issues.title,amountText,i⊑result.issues.details⟩
  }¨result.issues.index
  headingText ← ∾{𝕩∾lf}¨⟨"== Issues ==","Selection: open (source order)",""⟩
  tableText ← TrimTable text.RenderTable ⟨⟨"Date","Due","Category","Title","Amount","Details"⟩,rows,⟨4⟩⟩
  bodyText ← (0<≠rows)⊑⟨"  (none)"∾lf,tableText⟩
  ∾⟨headingText,bodyText,lf⟩
}

{Build⇐Build,FormatHuman⇐FormatHuman}
