# loader.bqn
# Read-only TSV file loader for the cycle-ledger prototype.
#
# Design: minimal, inspectable, no side effects on canonical data.
#
# Contract (DATA_CONTRACT.md):
#   - reads canonical TSV files
#   - skips comment lines (#) and empty lines
#   - splits by TAB
#   - does not rewrite canonical files

# ReadRaw: read file content as a string.
# Uses native •FChars resolved against working directory (•wdpath) for relative paths.
ReadRaw ← {
  path ← 𝕩
  is_abs ← (0 < ≠ path) ∧ (("/" ≡ 1 ↑ path) ∨ ("~" ≡ 1 ↑ path))
  full_path ← is_abs ◶ ⟨ { 𝕊 ⋄ •wdpath ∾ "/" ∾ path }, { 𝕊 ⋄ path } ⟩ @
  •FChars full_path
}

# ReadLines: read file, split by newline, skip comments and empties.
# Args: 𝕩 is file path (String)
# Returns: 1D Array of Strings (non-comment, non-empty lines)
ReadLines ← {
  raw ← ReadRaw 𝕩
  stripped ← ((@+13) ≠ raw) / raw
  lines ← (@+10) Split stripped
  IsData ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }
  keep ← IsData ¨ lines
  keep / lines
}

# ReadLinesOptional: like ReadLines but returns empty list if file does not exist.
# Uses native try-catch block (⎊) instead of shell test -f.
# Args: 𝕩 is file path (String)
# Returns: 1D Array of Strings (empty if file missing or unreadable)
ReadLinesOptional ← {
  ( ReadLines ⎊ { ⟨⟩ } ) 𝕩
}

# SplitTsv: split a line by TAB into fields.
# Args: 𝕩 is line String
# Returns: 1D Array of Strings (fields)
SplitTsv ← { (@+9) Split 𝕩 }

# SplitTsvKeepEmpty: split a line by TAB, preserving empty fields.
# Use this for journal-like source display rows so empty memo fields do not shift columns.
SplitTsvKeepEmpty ← { (@+9) SplitKeepEmpty 𝕩 }

# Split: split 𝕩 by separator 𝕨, dropping empty parts.
Split ← {
  sep ← 𝕨
  mask ← sep = 𝕩
  groups ← (+` mask) ⊔ 𝕩
  parts ← { (sep ≠ 𝕩) / 𝕩 } ¨ groups
  (0 < ≠¨ parts) / parts
}

# SplitKeepEmpty: split 𝕩 by separator, preserving empty fields between/around separators.
SplitKeepEmpty ← {
  sep ← 𝕨
  mask ← sep = 𝕩
  groups ← (+` mask) ⊔ 𝕩
  { (sep ≠ 𝕩) / 𝕩 } ¨ groups
}

{ ReadRaw ⇐ ReadRaw, ReadLines ⇐ ReadLines, ReadLinesOptional ⇐ ReadLinesOptional, SplitTsv ⇐ SplitTsv, SplitTsvKeepEmpty ⇐ SplitTsvKeepEmpty, Split ⇐ Split, SplitKeepEmpty ⇐ SplitKeepEmpty }
