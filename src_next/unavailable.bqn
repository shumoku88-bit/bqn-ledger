# unavailable.bqn
# Canonical taxonomy of unavailable sentinels for src_next.
#
# Sentinels follow the pattern "unavailable/<reason>":
#   NoPolicy  — policy not configured
#   NoCycle   — cycle period missing/invalid
#   NoData    — cycle valid but no data in period

{
  StartsWith ⇐ { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 },
  IsUnavailable ⇐ { "unavailable/" StartsWith 𝕩 },
  noPolicy ⇐ "unavailable/no_policy",
  noCycle ⇐ "unavailable/no_cycle",
  noData ⇐ "unavailable/no_data"
}
