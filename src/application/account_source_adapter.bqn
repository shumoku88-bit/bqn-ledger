# Read-only application adapter for canonical accounts.journal.
# Physical basename ownership stays in canonical_household_sources.bqn; schema
# admission stays in src/ledger/account_journal_admission.bqn.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
admission ← •Import "../ledger/account_journal_admission.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Load ← {𝕊 base:
  path ← Join ⟨base,sources.accounts⟩
  raw ← io.ReadRaw path
  admission.Admit raw
}

{Load⇐Load}
