#!/usr/bin/env bqn
# Validate and render an append-only accounts.tsv addition.
# Args: <baseDir> <name> <role> <type-or-empty>
# Success protocol: OK\tAPPEND\taccounts.tsv, followed by the complete row.

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
config ← •Import "../src_next/config.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: account_add_cmd.bqn <baseDir> <name> <role> <type-or-empty>"}⍟(4 ≠ ≠args) @

baseDir ← 0⊑args
name ← 1⊑args
role ← 2⊑args
type ← 3⊑args
targetFile ← sys.DefaultAccountsFile @
lines ← loader.ReadLinesOptional (baseDir ∾ "/" ∾ targetFile)
IsDataLine ← { (0 < ≠𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }
dataLines ← (IsDataLine¨ lines) / lines
fields ← loader.SplitTsvKeepEmpty¨ dataLines
accounts ← {⊑𝕩}¨ (0 < ≠¨ fields) / fields

check ← validate.ValidateAccountAdd {
  name ⇐ name ⋄ role ⇐ role ⋄ type ⇐ type ⋄ accounts ⇐ accounts
}
{𝕊 ⋄ Fail (1⊑check)}⍟(¬0⊑check) @

row ← render.RenderAccountRow { name ⇐ name ⋄ role ⇐ role ⋄ type ⇐ type }
•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ targetFile
•Out row
