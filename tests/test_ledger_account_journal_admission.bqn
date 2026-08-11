#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
accounts ← •Import "../src/ledger/account_journal_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾ lines ∾¨ lf }
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics }
Codes ← {𝕊 diagnostics: {𝕩.code}¨diagnostics }

proof ← accounts.Admit loader.ReadRaw "fixtures/canonical-household-v1/accounts.journal"
"ok" lib.AssertEq proof.state
0 lib.AssertEq ≠proof.diagnostics
6 lib.AssertEq proof.accounts.count
⟨"Assets:Bank","Equity:Opening","Income:Salary","Expenses:Groceries","Budget:Unassigned","Budget:Daily"⟩ lib.AssertEq proof.accounts.key
⟨"Asset","Equity","Income","Expense","Budget","Budget"⟩ lib.AssertEq proof.accounts.type
⟨"asset","equity","income","expense","budget","budget"⟩ lib.AssertEq proof.accounts.role
⟨"JPY","JPY","JPY","JPY","JPY","JPY"⟩ lib.AssertEq proof.accounts.currency
⟨1,5,9,13,17,21⟩ lib.AssertEq proof.accounts.source_row

optionalCommodity ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset"
⟩
"ok" lib.AssertEq optionalCommodity.state
"" lib.AssertEq ⊑optionalCommodity.accounts.default_commodity
"Asset" lib.AssertEq ⊑optionalCommodity.accounts.type
"asset" lib.AssertEq ⊑optionalCommodity.accounts.role

roleSynonym ← accounts.Admit Raw ⟨
  "; synthetic declaration source",
  "account Expenses:Food",
  "  ; ROLE: expense"
⟩
"ok" lib.AssertEq roleSynonym.state
"Expense" lib.AssertEq ⊑roleSynonym.accounts.type
"expense" lib.AssertEq ⊑roleSynonym.accounts.role

# A top-level comment does not terminate the active Account block.
commentBridge ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "; explanatory comment",
  "  type: Asset"
⟩
"ok" lib.AssertEq commentBridge.state
⟨"Assets:Cash"⟩ lib.AssertEq commentBridge.accounts.key
⟨1⟩ lib.AssertEq commentBridge.accounts.source_row

# A new Account directive closes the preceding block without requiring a blank line.
adjacentAccounts ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "account Expenses:Food",
  "  role: Expense"
⟩
"ok" lib.AssertEq adjacentAccounts.state
⟨"Assets:Cash","Expenses:Food"⟩ lib.AssertEq adjacentAccounts.accounts.key
⟨1,3⟩ lib.AssertEq adjacentAccounts.accounts.source_row

# A blank closes the block; later indented metadata is outside any Account.
blankTerminates ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "",
  "  type: Asset"
⟩
"error" lib.AssertEq blankTerminates.state
⟨"account_type_missing","account_indented_line_unexpected"⟩ lib.AssertEq Codes blankTerminates.diagnostics
0 lib.AssertEq blankTerminates.accounts.count

# An unsupported top-level block finalizes the prior Account before its own diagnostic.
unsupportedFinalizes ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "include shared.journal"
⟩
"error" lib.AssertEq unsupportedFinalizes.state
⟨"account_type_missing","account_block_unsupported"⟩ lib.AssertEq Codes unsupportedFinalizes.diagnostics

unsupportedBlock ← accounts.Admit Raw ⟨"include shared-accounts.journal"⟩
"error" lib.AssertEq unsupportedBlock.state
lib.Assert HasCode ⟨"account_block_unsupported",unsupportedBlock.diagnostics⟩
0 lib.AssertEq unsupportedBlock.accounts.count

unknownMetadata ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "  liquidity: liquid"
⟩
"error" lib.AssertEq unknownMetadata.state
lib.Assert HasCode ⟨"account_metadata_unsupported",unknownMetadata.diagnostics⟩

missingType ← accounts.Admit Raw ⟨"account Assets:Cash"⟩
"error" lib.AssertEq missingType.state
lib.Assert HasCode ⟨"account_type_missing",missingType.diagnostics⟩

duplicateType ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "  role: Asset"
⟩
"error" lib.AssertEq duplicateType.state
lib.Assert HasCode ⟨"account_type_duplicate",duplicateType.diagnostics⟩

invalidType ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Treasure"
⟩
"error" lib.AssertEq invalidType.state
lib.Assert HasCode ⟨"account_type_invalid",invalidType.diagnostics⟩

invalidCommodity ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "  commodity: bad currency"
⟩
"error" lib.AssertEq invalidCommodity.state
lib.Assert HasCode ⟨"account_commodity_invalid",invalidCommodity.diagnostics⟩

duplicateCommodity ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "  commodity: JPY",
  "  commodity: JPY"
⟩
"error" lib.AssertEq duplicateCommodity.state
lib.Assert HasCode ⟨"account_commodity_duplicate",duplicateCommodity.diagnostics⟩

duplicateAccount ← accounts.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "",
  "account Assets:Cash",
  "  type: Asset"
⟩
"error" lib.AssertEq duplicateAccount.state
lib.Assert HasCode ⟨"account_key_duplicate",duplicateAccount.diagnostics⟩
0 lib.AssertEq duplicateAccount.accounts.count

transactionBlock ← accounts.Admit Raw ⟨
  "2026-08-02 * Lunch",
  "  Assets:Cash  -800 JPY"
⟩
"error" lib.AssertEq transactionBlock.state
lib.Assert HasCode ⟨"account_block_unsupported",transactionBlock.diagnostics⟩

•Out "test_ledger_account_journal_admission: ok"
