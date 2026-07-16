# loader.bqn
# Read-only repository file loader.
#
# Design: minimal, inspectable, no writes to canonical data.
# Pure text splitting is owned by util.bqn and re-exported here to preserve the
# existing loader API used by source readers.
#
# Contract (DATA_CONTRACT.md):
#   - reads canonical TSV files
#   - skips comment lines (# / \) and empty lines
#   - splits by TAB
#   - does not rewrite canonical files

util ← •Import "util.bqn"

Split ← util.Split
SplitKeepEmpty ← util.SplitKeepEmpty

# ResolvePath: resolve relative path against working directory (•wdpath) if not absolute.
ResolvePath ← {
  path ← 𝕩
  is_abs ← (0 < ≠ path) ∧ (("/" ≡ 1 ↑ path) ∨ ("~" ≡ 1 ↑ path))
  is_abs ◶ ⟨ { 𝕊 ⋄ •wdpath ∾ "/" ∾ path }, { 𝕊 ⋄ path } ⟩ @
}

# ReadRaw: read file content as a string.
# Uses native •FChars resolved against working directory (•wdpath) for relative paths.
ReadRaw ← {
  •FChars ResolvePath 𝕩
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
# Strict: if file is present but unreadable, it fails (throws exception).
# Args: 𝕩 is file path (String)
# Returns: 1D Array of Strings (empty if file missing)
ReadLinesOptional ← {
  full_path ← ResolvePath 𝕩
  (•file.Exists full_path) ? ReadLines full_path ; ⟨⟩
}

# SplitTsv: split a line by TAB into fields.
# Args: 𝕩 is line String
# Returns: 1D Array of Strings (fields)
SplitTsv ← { (@+9) Split 𝕩 }

# SplitTsvKeepEmpty: split a line by TAB, preserving empty fields.
# Use this for journal-like source display rows so empty memo fields do not shift columns.
SplitTsvKeepEmpty ← { (@+9) SplitKeepEmpty 𝕩 }

{
  ReadRaw ⇐ ReadRaw,
  ReadLines ⇐ ReadLines,
  ReadLinesOptional ⇐ ReadLinesOptional,
  SplitTsv ⇐ SplitTsv,
  SplitTsvKeepEmpty ⇐ SplitTsvKeepEmpty,
  Split ⇐ Split,
  SplitKeepEmpty ⇐ SplitKeepEmpty
}
