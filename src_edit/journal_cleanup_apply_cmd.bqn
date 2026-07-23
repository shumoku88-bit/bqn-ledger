#!/usr/bin/env bqn
# Prepare a verified cleanup candidate at a caller-owned temporary path.

loader ← •Import "../src_next/loader.bqn"
actual ← •Import "../src_next/actual_source.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
cleanup ← •Import "journal_cleanup_plan.bqn"
rewrite ← •Import "journal_cleanup_rewrite.bqn"

args ← •args ⋄ tab ← @+9
Join ← {𝕊 fields: 1↓∾(tab⊸∾)¨fields}
Fail ← {𝕊 code‿message: •Out Join ⟨"ERROR",code,message⟩ ⋄ •Exit 1}
{𝕊: Fail ⟨"usage","expected base directory and candidate output path"⟩}⍟(2≠≠args) @
base ← 0⊑args ⋄ candidatePath ← 1⊑args
route ← actual.ModeAndFile base
{𝕊: Fail ⟨"actual_source_not_journal","cleanup apply requires ACTUAL_SOURCE=journal"⟩}⍟(route.mode≢"journal") @
raw ← loader.ReadRaw (base∾"/"∾route.file)
parsed ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
{𝕊: Fail ⟨"journal_invalid","configured Journal did not parse"⟩}⍟(parsed.state≢"ok") @
rows ← cleanup.Build parsed.transactions
built ← rewrite.BuildCandidate ⟨raw,parsed.transactions,rows⟩
{𝕊:
  d ← ⊑built.diagnostics
  Fail ⟨d.code,d.message⟩
}⍟(built.state≢"ok") @
count ← ≠built.removals ⋄ total ← ≠rows
{𝕊:
  candidatePath •FChars built.candidate_raw
  {𝕊: Fail ⟨"candidate_write_mismatch","temporary candidate bytes differ"⟩}⍟((loader.ReadRaw candidatePath) ≢ built.candidate_raw) @
  •Out Join ⟨"OK","CLEANUP_REWRITE",route.file,•Fmt count,•Fmt total⟩
  {𝕊 row:
    •Out Join ⟨"REMOVE",•Fmt row.number,•Fmt row.event_id_line,row.date,row.event_id,row.description⟩
  }¨built.removals
}⍟(0<count) @
{𝕊: •Out Join ⟨"OK","CLEANUP_NOOP",route.file,"0",•Fmt total⟩}⍟(0=count) @
