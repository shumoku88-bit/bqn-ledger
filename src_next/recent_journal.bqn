# recent_journal.bqn
# Compact last-N actual source journal rows for src_next.

fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# Declare field names at the top-level scope for dot-notation access to projection namespaces
source_file ← 0
source_row  ← 0
side        ← 0
delta       ← 0
account_key ← 0
source_id   ← 0
date        ← 0
memo        ← 0
from        ← 0
to          ← 0
amount      ← 0

# BuildRecentRows extracts the last N actual journal entries as structured namespaces
# from the context posting rows.
# Returns: array of namespaces with ⟨date, memo, from, to, amount⟩
BuildRecentRows ← {𝕊 ctx‿n:
  # Filter only actual journal rows
  jrows ← ({ "journal.tsv" ≡ 𝕩.source_file }¨ ctx.posting_rows) / ctx.posting_rows
  
  (0 = ≠ jrows) ◶ ⟨
    { 𝕊 ⋄
      # Get unique source_row indices, sorted ascending
      row_ids ← {𝕩.source_row}¨ jrows
      uniq_rows ← ∧ ((row_ids ⊐ row_ids) = ↕ ≠ row_ids) / row_ids
      
      # Get last N rows
      start ← 0 ⌈ (≠ uniq_rows) - n
      recent_row_ids ← start ↓ uniq_rows
      
      # Map each row_id back to ⟨date, memo, from, to, amount⟩
      ExtractEntry ← {𝕊 rid:
        # Find debit and credit posting rows for this row_id
        matches ← ({rid ≡ 𝕩.source_row}¨ jrows) / jrows
        
        debit_row  ← ⊑ ({"debit" ≡ 𝕩.side}¨ matches) / matches
        credit_row ← ⊑ ({"credit" ≡ 𝕩.side}¨ matches) / matches
        
        {
          date ⇐ debit_row.date
          memo ⇐ debit_row.source_id
          from ⇐ credit_row.account_key
          to ⇐ debit_row.account_key
          amount ⇐ debit_row.delta
        }
      }
      
      # Return entries, newest first (reverse order)
      ⌽ ExtractEntry¨ recent_row_ids
    },
    { 𝕊 ⋄ ⟨⟩ }
  ⟩ @
}

# Format: show last N journal entries from context.
# Args: ⟨ctx, n⟩
Format ← {𝕊 ctx‿n:
  recent ← BuildRecentRows ⟨ctx, n⟩
  out ← "--- SrcNext Recent Journal ---" ∾ (@+10)
  {
    FormatRow ← {
      r ← 𝕩
      "src_next_recent_journal: " ∾ r.date ∾ " " ∾ r.memo ∾ " " ∾ r.from ∾ " -> " ∾ r.to ∾ " " ∾ (•Fmt r.amount) ∾ (@+10)
    }
    out ↩ out ∾ ∾ FormatRow¨ recent
  }⍟(0 < ≠ recent) @
  {𝕊: out ↩ out ∾ "src_next_recent_journal: (none)" ∾ (@+10)}⍟(0 = ≠ recent) @
  out
}

# FormatHuman: render recent journal as human-readable text.
# Args: ⟨ctx, n⟩
FormatHuman ← {𝕊 ctx‿n:
  recent ← BuildRecentRows ⟨ctx, n⟩

  out ← fmt.Section (L "recent.section_title") ∾ (@+10)
  out ↩ out ∾ "(newest first, last " ∾ (•Fmt n) ∾ ")" ∾ (@+10)

  {𝕊:
    TrimMemo ← { (fmt.VWidth 𝕩) ≤ 20 ? 𝕩 ; (fmt.PadV ⟨18, 𝕩⟩) ∾ ".." }
    rows ← {𝕊 r:
      ⟨r.date, r.from, r.to, TrimMemo r.memo, fmt.HumanNumber r.amount⟩
    }¨ recent
    headers ← ⟨L "recent.date_header", L "recent.from_header", L "recent.to_header", L "recent.memo_header", L "recent.amount_header"⟩
    out ↩ out ∾ fmt.RenderTable ⟨headers, rows, ⟨0, 0, 0, 0, 1⟩⟩
  }⍟(0 < ≠ recent) @
  {𝕊: out ↩ out ∾ "  (none)" ∾ (@+10)}⍟(0 = ≠ recent) @
  out ↩ out ∾ (@+10)
  out
}

{ Format ⇐ Format, FormatHuman ⇐ FormatHuman }
