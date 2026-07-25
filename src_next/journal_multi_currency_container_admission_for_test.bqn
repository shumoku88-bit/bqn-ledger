# journal_multi_currency_container_admission_for_test.bqn
# Pure test-only proof boundary. Production Journal routes do not import this module.

Admit ← {𝕊 raw‿resolved:
  {
    state⇐"error",
    declared_domains⇐⟨⟩,
    transactions⇐⟨⟩,
    diagnostics⇐⟨⟩
  }
}

{Admit⇐Admit}
