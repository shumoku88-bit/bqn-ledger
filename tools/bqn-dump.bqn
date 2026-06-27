# tools/bqn-dump.bqn — Phase 2: compact BQN value diagnostic dumper
#
# Returns a namespace of introspection functions.
# Used by tools/bqn-dump (shell wrapper) and tests/test_bqn_dump.bqn.
#
# Phase 2 boundary:
# - no repo module loading
# - no TSV loading
# - no source writes
# - no report engine behavior changes
#
# Note: CBQN scoping — ← variables are not visible in the else
# branch of ? ; blocks. Functions below avoid this by not using
# ← in any block that uses ? ; in its body.
#
# Note: •Show prints to stdout in CBQN; we use •Fmt for
# string-only formatting without side effects.

{
  # ── Type detection ──
  IsNum ⇐ { 1 = •Type 𝕩 }
  IsChar ⇐ { 2 = •Type 𝕩 }
  IsArr ⇐ { 0 = •Type 𝕩 }

  # ── Shape/rank helpers ──
  IsScalarNum ⇐ { 0==𝕩 ∧ IsNum 𝕩 }
  IsBoxedScalar ⇐ { (0==𝕩) ∧ IsArr 𝕩 }

  # ── Character array (string) detection ──
  IsStr ⇐ { (1≠=𝕩)∨(0=≠𝕩) ? 0 ; IsChar ⊑𝕩 }

  # ── Boxed element detection for lists ──
  HasBoxedEls ⇐ { ((=𝕩)<1)∨(0=≠𝕩) ? 0 ; (0==⊑𝕩) ∧ IsArr ⊑𝕩 }

  # ── Kind classification ──
  Kind ⇐ {
    IsNum 𝕩       ? "number" ;
    IsBoxedScalar 𝕩 ? "boxed" ;
    IsStr 𝕩        ? "string" ;
    IsArr 𝕩        ? HasBoxedEls 𝕩? "list_boxed" ; "list" ;
    "unknown"
  }

  # ── Main dump: print diagnostics to stdout ──
  Dump ⇐ {
    v ← 𝕩
    •Out "kind: "∾Kind v
    •Out "shape: "∾•Fmt ≢v
    •Out "preview: "∾•Fmt v
    •Out "boxed: "∾{
      IsBoxedScalar 𝕩 ? "scalar_boxed" ;
      HasBoxedEls 𝕩   ? "elements_boxed" ;
      "none"
    } v
  }
}
