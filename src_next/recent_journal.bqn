# recent_journal.bqn
# Compact last-N actual source journal rows for src_next.

fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
actual_source ← •Import "actual_source.bqn"
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
  Join ← {𝕊 xs: out←"" ⋄ {out∾↩𝕩∾","}¨xs ⋄ (0<≠out) ? ¯1↓out ; ""}
  txs ← actual_source.Transactions ctx
  start ← 0⌈(≠txs)-n
  selected ← start↓txs
  Make ← {𝕊 tx:
    debits ← ({𝕩.delta>0}¨tx.postings)/tx.postings
    credits ← ({𝕩.delta<0}¨tx.postings)/tx.postings
    {date⇐tx.date,memo⇐tx.description,from⇐Join {𝕩.account_key}¨credits,to⇐Join {𝕩.account_key}¨debits,amount⇐+´0∾{𝕩.delta}¨debits}
  }
  ⌽Make¨selected
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
