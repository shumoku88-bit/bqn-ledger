# journal_prefix_converter_cmd.bqn
# Narrow file adapter for the pure canonical prefix converter. The supplied
# output is a caller-owned temporary sibling, never a production default.

converter ← •Import "../src_next/journal_canonical_prefix_converter.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"

tab ← @+9
args ← •args
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
Codes ← {𝕊 diagnostics:
  result ← "conversion_failed"
  {𝕊: result ↩ (⊑diagnostics).code}⍟(0<≠diagnostics) @
  result
}

{𝕊: Fail ⟨"usage","expected convert or reconstruct with explicit file arguments"⟩}⍟(0=≠args) @
mode ← 0⊑args
isConvert ← mode≡"convert"
isReconstruct ← mode≡"reconstruct"
{𝕊: Fail ⟨"usage","mode must be convert or reconstruct"⟩}⍟(¬(isConvert∨isReconstruct)) @
expectedCount ← isConvert⊑8‿6
{𝕊: Fail ⟨"usage","wrong number of explicit file arguments"⟩}⍟(expectedCount≠≠args) @

accountsPath ← 1⊑args
snapshotPath ← 2⊑args
sourceIdentity ← 3⊑args
cycleStart ← 4⊑args
accountLines ← loader.ReadLines accountsPath
snapshotRaw ← loader.ReadRaw snapshotPath
converted ← converter.Convert ⟨snapshotRaw,sourceIdentity,accountLines,cycleStart⟩
{𝕊: Fail ⟨Codes converted.diagnostics,"canonical prefix conversion failed; no output was published"⟩}⍟(converted.state≢"ok") @

{𝕊:
  temporaryPath ← 5⊑args
  temporaryPath •FChars converted.canonical_prefix_bytes
  written ← loader.ReadRaw temporaryPath
  {𝕊: Fail ⟨"temporary_bytes_mismatch","staged prefix bytes differ from the verified semantic result"⟩}⍟(written≢converted.canonical_prefix_bytes) @
  s ← converted.validation_summary
  •Out "OK"∾tab∾"CANONICAL_PREFIX"∾tab∾(•Fmt s.source_row_count)∾tab∾(•Fmt s.transaction_count)∾tab∾(•Fmt s.posting_count)
}⍟isConvert @

{𝕊:
  verifiedPrefixPath ← 5⊑args
  suffixPath ← 6⊑args
  temporaryPath ← 7⊑args
  suppliedPrefix ← loader.ReadRaw verifiedPrefixPath
  {𝕊: Fail ⟨"verified_prefix_mismatch","supplied prefix is not the deterministic verified conversion result"⟩}⍟(suppliedPrefix≢converted.canonical_prefix_bytes) @
  suffixBytes ← loader.ReadRaw suffixPath
  resolved ← ak.Resolve accountLines
  reconstructed ← converter.Reconstruct ⟨converted,suffixBytes,resolved,cycleStart⟩
  {𝕊: Fail ⟨Codes reconstructed.diagnostics,"synthetic reconstruction failed; no output was published"⟩}⍟(reconstructed.state≢"ok") @
  temporaryPath •FChars reconstructed.reconstructed_candidate_bytes
  written ← loader.ReadRaw temporaryPath
  {𝕊: Fail ⟨"temporary_bytes_mismatch","staged candidate bytes differ from the verified reconstruction result"⟩}⍟(written≢reconstructed.reconstructed_candidate_bytes) @
  s ← reconstructed.validation_summary
  •Out "OK"∾tab∾"RECONSTRUCTED_CANDIDATE"∾tab∾(•Fmt s.transaction_count)∾tab∾(•Fmt s.posting_count)
}⍟isReconstruct @
