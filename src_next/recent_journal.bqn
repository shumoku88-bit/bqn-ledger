# recent_journal.bqn
# Compact last-N actual source journal rows for src_next.

loader ← •Import "loader.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

ParseLine ← {𝕊 line:
  flds ← Pad5 loader.SplitTsvKeepEmpty line
  date ← 0⊑flds ⋄ memo ← 1⊑flds ⋄ fromAcc ← 2⊑flds
  toAcc ← 3⊑flds ⋄ amount ← 4⊑flds
  {date⇐date, memo⇐memo, from⇐fromAcc, to⇐toAcc, amount⇐amount}
}

FormatLine ← {𝕊 line:
  flds ← Pad5 loader.SplitTsvKeepEmpty line
  date ← 0⊑flds ⋄ memo ← 1⊑flds
  fromAcc ← 2⊑flds ⋄ toAcc ← 3⊑flds ⋄ amount ← 4⊑flds
  "src_next_recent_journal: " ∾ date ∾ " " ∾ memo ∾ " " ∾ fromAcc ∾ " -> " ∾ toAcc ∾ " " ∾ amount ∾ (@+10)
}

# Format: show last N journal entries from context.
# Args: ⟨ctx, n⟩
Format ← {𝕊 ctx‿n:
  lines ← loader.ReadLinesOptional (ctx.base ∾ "/journal.tsv")
  c ← ≠ lines
  start ← 0⌈(c - n)
  recent ← ⌽ (start ↓ lines)
  out ← "--- SrcNext Recent Journal ---" ∾ (@+10)
  { out ↩ out ∾ ∾ (FormatLine¨ recent) }⍟(0 < ≠ recent) @
  {𝕊: out ↩ out ∾ "src_next_recent_journal: (none)" ∾ (@+10)}⍟(0 = ≠ recent) @
  out
}

# FormatHuman: render recent journal as human-readable text.
# Args: ⟨ctx, n⟩
FormatHuman ← {𝕊 ctx‿n:
  lines ← loader.ReadLinesOptional (ctx.base ∾ "/journal.tsv")
  c ← ≠ lines
  start ← 0⌈(c - n)
  recent ← (ParseLine¨ ⌽ (start ↓ lines))

  out ← fmt.Section (L "recent.section_title") ∾ (@+10)
  out ↩ out ∾ "(newest first, last " ∾ (•Fmt n) ∾ ")" ∾ (@+10)

  {𝕊:
    dates ← {𝕩.date}¨ recent
    froms ← {𝕩.from}¨ recent
    tos ← {𝕩.to}¨ recent
    memos ← {𝕩.memo}¨ recent

    date_w ← ⌈´ (fmt.VWidth¨ dates) ∾ ⟨4⟩
    from_w ← ⌈´ (fmt.VWidth¨ froms) ∾ ⟨4⟩
    to_w ← ⌈´ (fmt.VWidth¨ tos) ∾ ⟨2⟩
    memo_w ← ⌈´ (fmt.VWidth¨ memos) ∾ ⟨4⟩

    PadCol ← {w‿s: fmt.PadV ⟨w, s⟩}

    out ↩ out ∾ "Date" ∾ ((date_w - 4) ⥊ " ") ∾ " | "
    out ↩ out ∾ "From" ∾ ((from_w - 4) ⥊ " ") ∾ " -> "
    out ↩ out ∾ "To" ∾ ((to_w - 2) ⥊ " ") ∾ " | "
    out ↩ out ∾ "Memo" ∾ ((0⌈memo_w - 4) ⥊ " ") ∾ " |       Amount" ∾ (@+10)

    {
      r ← 𝕩
      d ← PadCol ⟨date_w, r.date⟩
      f ← PadCol ⟨from_w, r.from⟩
      t ← PadCol ⟨to_w, r.to⟩
      m ← PadCol ⟨memo_w, r.memo⟩
      out ↩ out ∾ d ∾ " | " ∾ f ∾ " -> " ∾ t ∾ " | " ∾ m ∾ " | " ∾ (fmt.FmtAmt (•BQN r.amount)) ∾ (@+10)
    }¨ recent
  }⍟(0 < ≠ recent) @
  {𝕊: out ↩ out ∾ "  (none)" ∾ (@+10)}⍟(0 = ≠ recent) @
  out ↩ out ∾ (@+10)
  out
}

{ Format ⇐ Format, FormatHuman ⇐ FormatHuman }
