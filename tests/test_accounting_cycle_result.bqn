# Test contract and shape invariants of cycle_result.bqn

cycle_result ← •Import "../src/accounting/cycle_result.bqn"

# 1. Success result shape and day_count
success ← cycle_result.Success ⟨"calendarMonth","2026-01-10","2026-01-01","2026-02-01",⟨⟩,⟨⟩⟩
! "ok" ≡ success.state
! "calendarMonth" ≡ success.mode
! "2026-01-10" ≡ success.observation
! "2026-01-01" ≡ success.start
! "2026-02-01" ≡ success.end_exclusive
! 31 ≡ success.day_count

# 2. Unavailable result shape
unavailable ← cycle_result.Unavailable ⟨"incomeAnchor","2026-01-10","missing_anchor"⟩
! "unavailable" ≡ unavailable.state
! "incomeAnchor" ≡ unavailable.mode
! "missing_anchor" ≡ unavailable.reason

# 3. Error result shape and diagnostic
err ← cycle_result.Error ⟨"fixed","2026-01-10","invalid_window","start is after end"⟩
! "error" ≡ err.state
! "invalid_window" ≡ (0⊑err.diagnostics).code

•Out "test_accounting_cycle_result passed"
