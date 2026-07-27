# report_context_duplication_probe.bqn
#
# Read-only characterization of the transitional full-report context routes.
# It compares the ordinary compatibility context, the selected-domain adapter,
# and selected-domain construction from explicitly prepared source inputs.
# No production instrumentation or private data access is required.
#
# Usage: bqn tools/characterization/report_context_duplication_probe.bqn <baseDir> [currency]

ctx_mod ← •Import "../../src_next/context.bqn"
selected ← •Import "../../src_next/selected_domain_context.bqn"
loader ← •Import "../../src_next/loader.bqn"
ak ← •Import "../../src_next/account_key.bqn"
cycle ← •Import "../../src_next/cycle.bqn"
actual_source ← •Import "../../src_next/actual_source.bqn"
admission ← •Import "../../src/ledger/journal_complete_admission.bqn"
setup ← •Import "../../src_next/currency_setup.bqn"

Ms ← {𝕊 sec: •Fmt (⌊ 0.5 + 1000000 × sec) ÷ 1000 }
AdmissionAccounts ← {𝕊 resolved: {key⇐resolved.accounts,currency⇐resolved.currencies} }

Main ← {𝕊 args:
  {𝕊: •Out "Usage: report_context_duplication_probe.bqn <baseDir> [currency]" ⋄ •Exit 2}⍟(1 > ≠args) @
  base ← 0 ⊑ args
  currency ← ""
  {𝕊: currency ↩ 1 ⊑ args}⍟(1 < ≠args) @
  {𝕊:
    defaultResult ← setup.ResolveDefault loader.ReadLinesOptional (base ∾ "/config.tsv")
    {𝕊: •Out "ERROR: explicit currency or valid DEFAULT_CURRENCY is required" ⋄ •Exit 2}⍟(defaultResult.state ≢ "ok") @
    currency ↩ defaultResult.currency
  }⍟(1 = ≠args) @

  # Route A: the ordinary context used by full report sections.
  tLegacy0 ← •MonoTime @
  legacy ← ctx_mod.BuildContext base
  tLegacy1 ← •MonoTime @

  # Route B: the current selected-domain adapter used by balances. This adapter
  # performs its own account/source reads and preliminary complete admission.
  tSelected0 ← •MonoTime @
  directSelected ← selected.Build ⟨base, currency⟩
  tSelected1 ← •MonoTime @
  {𝕊: •Out "ERROR: direct selected context failed" ⋄ •Exit 1}⍟(directSelected.state ≢ "ok") @

  # Reproduce only the read-only adapter preparation in selected.Build. The
  # semantic BuildFromPrepared stage remains production code and is timed as a
  # unit; this probe does not copy its accounting logic.
  tAccounts0 ← •MonoTime @
  resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
  tAccounts1 ← •MonoTime @

  tActualRead0 ← •MonoTime @
  sourceFile ← actual_source.ResolveRelativePath base
  raw ← loader.ReadRaw (base ∾ "/" ∾ sourceFile)
  tActualRead1 ← •MonoTime @

  tPreAdmission0 ← •MonoTime @
  preliminary ← admission.Admit ⟨raw,AdmissionAccounts resolved,setup.registry_value⟩
  tPreAdmission1 ← •MonoTime @
  {𝕊: •Out "ERROR: preliminary selected admission failed" ⋄ •Exit 1}⍟(preliminary.state ≢ "ok") @

  tCycle0 ← •MonoTime @
  cy ← cycle.ReadCycleFromAdmittedTransactions ⟨base, preliminary.transactions⟩
  tCycle1 ← •MonoTime @

  tNonActual0 ← •MonoTime @
  nonactualSnapshot ← ctx_mod.LoadNonActualPostingSourceSnapshot base
  tNonActual1 ← •MonoTime @

  tPreparedBuild0 ← •MonoTime @
  preparedSelected ← selected.BuildFromPrepared ⟨currency, raw, resolved, cy, sourceFile, nonactualSnapshot⟩
  tPreparedBuild1 ← •MonoTime @
  {𝕊: •Out "ERROR: prepared selected context failed" ⋄ •Exit 1}⍟(preparedSelected.state ≢ "ok") @

  sameScale ← directSelected.calculation_scale = preparedSelected.calculation_scale
  sameRows ← (≠directSelected.posting_rows) = ≠preparedSelected.posting_rows
  sameTransactions ← (≠directSelected.actual_transactions) = ≠preparedSelected.actual_transactions
  sameShape ← sameScale ∧ sameRows ∧ sameTransactions
  {𝕊: •Out "ERROR: direct/prepared selected context shape mismatch" ⋄ •Exit 1}⍟(¬sameShape) @

  preparationTimes ← ⟨tAccounts1-tAccounts0, tActualRead1-tActualRead0, tPreAdmission1-tPreAdmission0, tCycle1-tCycle0, tNonActual1-tNonActual0⟩
  preparationTime ← +´ preparationTimes

  •Out "--- REPORT CONTEXT DUPLICATION PROBE ---"
  •Out "Legacy_BuildContext_ms: " ∾ Ms (tLegacy1-tLegacy0)
  •Out "Selected_Build_adapter_total_ms: " ∾ Ms (tSelected1-tSelected0)
  •Out "Sequential_context_total_ms: " ∾ Ms ((tLegacy1-tLegacy0) + tSelected1-tSelected0)
  •Out "Prepared_accounts_ms: " ∾ Ms (tAccounts1-tAccounts0)
  •Out "Prepared_actual_source_read_ms: " ∾ Ms (tActualRead1-tActualRead0)
  •Out "Prepared_preliminary_admission_ms: " ∾ Ms (tPreAdmission1-tPreAdmission0)
  •Out "Prepared_cycle_resolution_ms: " ∾ Ms (tCycle1-tCycle0)
  •Out "Prepared_nonactual_snapshot_read_ms: " ∾ Ms (tNonActual1-tNonActual0)
  •Out "Prepared_input_total_ms: " ∾ Ms preparationTime
  •Out "Selected_BuildFromPrepared_ms: " ∾ Ms (tPreparedBuild1-tPreparedBuild0)
  •Out "Direct_prepared_shape_parity: ok"
  •Out "Legacy_cycle_start: " ∾ legacy.cy.start
  •Out "Selected_cycle_start: " ∾ preparedSelected.cy.start
  •Out "Legacy_posting_rows: " ∾ •Fmt ≠legacy.posting_rows
  •Out "Selected_posting_rows: " ∾ •Fmt ≠preparedSelected.posting_rows
  •Out "Selected_actual_transactions: " ∾ •Fmt ≠preparedSelected.actual_transactions
}

Main •args
