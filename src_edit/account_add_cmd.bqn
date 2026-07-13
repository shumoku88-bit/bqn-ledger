#!/usr/bin/env bqn
# Validate and render an append-only accounts.tsv addition.
# Args: <baseDir> <name> <role> <type-or-empty> <currency-or-empty>
# Success protocol: OK\tAPPEND\taccounts.tsv, followed by the complete row.

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
config ← •Import "../src_next/config.bqn"
setup ← •Import "../src_next/currency_setup.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: account_add_cmd.bqn <baseDir> <name> <role> <type-or-empty> <currency-or-empty>"}⍟(5 ≠ ≠args) @

baseDir ← 0⊑args
name ← 1⊑args
role ← 2⊑args
type ← 3⊑args
explicitCurrency ← 4⊑args
targetFile ← sys.DefaultAccountsFile @
lines ← loader.ReadLinesOptional (baseDir ∾ "/" ∾ targetFile)
IsDataLine ← { (0 < ≠𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }
dataLines ← (IsDataLine¨ lines) / lines
fields ← loader.SplitTsvKeepEmpty¨ dataLines
accounts ← {⊑𝕩}¨ (0 < ≠¨ fields) / fields

configLines ← loader.ReadLinesOptional (baseDir ∾ "/config.tsv")
defaultResult ← setup.ResolveDefault configLines
selection ← setup.ResolveSelection ⟨defaultResult, explicitCurrency⟩
{𝕊 ⋄ Fail selection.message}⍟(selection.state ≢ "ok") @
currency ← selection.currency

check ← validate.ValidateAccountAdd {
  name ⇐ name ⋄ role ⇐ role ⋄ type ⇐ type ⋄ currency ⇐ currency ⋄ accounts ⇐ accounts
}
{𝕊 ⋄ Fail (1⊑check)}⍟(¬0⊑check) @

row ← render.RenderAccountRow { name ⇐ name ⋄ role ⇐ role ⋄ type ⇐ type ⋄ currency ⇐ currency }
•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ targetFile
•Out row
