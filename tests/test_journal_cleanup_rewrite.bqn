#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
cleanup ← •Import "../src_edit/journal_cleanup_plan.bqn"
rewrite ← •Import "../src_edit/journal_cleanup_rewrite.bqn"

profile ← "historical_external_plan"
fixture ← "fixtures/journal-legacy-entry-id-removal-boundary"
beforeRaw ← loader.ReadRaw (fixture∾"/before.journal")
before ← parser.ParseWithProfile ⟨beforeRaw,profile⟩
rows ← cleanup.Build before.transactions
built ← rewrite.BuildCandidate ⟨beforeRaw,before.transactions,rows⟩
"ok" lib.AssertEq built.state
1 lib.AssertEq ≠built.removals
1 lib.AssertEq built.before_counts.removable
0 lib.AssertEq built.after_counts.removable
1 lib.AssertEq built.after_counts.identity_free
(loader.ReadRaw (fixture∾"/after-unreferenced.journal")) lib.AssertEq built.candidate_raw
after ← parser.ParseWithProfile ⟨built.candidate_raw,profile⟩
"ok" lib.AssertEq after.state
"ok" lib.AssertEq (rewrite.VerifyEquivalent ⟨before.transactions,after.transactions,rows⟩).state
⟨"note","currency"⟩ lib.AssertEq {𝕩.key}¨(1⊑after.transactions).metadata
⟨"opening-20260701-001","entry-aaaaaaaaaaaaaaaaaaaaaaaa","budget-companion-household-001","entry-bbbbbbbbbbbbbbbbbbbbbbbb"⟩ lib.AssertEq {𝕩.source_event_id}¨0‿2‿3‿4⊏after.transactions

lf ← @+10
legacy ← "entry-cccccccccccccccccccccccc"
MakeRaw ← {𝕊 finalNewline:
  parts ← ⟨<"commodity JPY",<"",<"account assets:test",<"",<"account expenses:test",<"",<"2026-07-24 * Unicode 日本語",<("    ; event-id: "∾legacy),<"    ; note: 保持",<"    assets:test -1 JPY",<"    expenses:test 1 JPY"⟩
  raw ← ""
  {𝕊 i: {𝕊: raw ∾↩ lf}⍟(i>0) @ ⋄ raw ∾↩ >i⊑parts}¨↕≠parts
  {𝕊: raw ∾↩ lf}⍟finalNewline @
  raw
}
{𝕊 final:
  raw ← MakeRaw final
  parsed ← parser.ParseWithProfile ⟨raw,profile⟩
  "ok" lib.AssertEq parsed.state
  localRows ← cleanup.Build parsed.transactions
  result ← rewrite.BuildCandidate ⟨raw,parsed.transactions,localRows⟩
  "ok" lib.AssertEq result.state
  reparsed ← parser.ParseWithProfile ⟨result.candidate_raw,profile⟩
  "Unicode 日本語" lib.AssertEq (⊑reparsed.transactions).description
  ⟨"保持"⟩ lib.AssertEq {𝕩.value}¨(⊑reparsed.transactions).metadata
  final lib.AssertEq ((0<≠result.candidate_raw) ∧ lf=¯1⊑result.candidate_raw)
}¨0‿1

target ← 1⊑rows
MakeRow ← {𝕊 line: {
  number⇐target.number,classification⇐target.classification,reason⇐target.reason,
  date⇐target.date,description⇐target.description,event_id⇐target.event_id,
  event_id_line⇐line,source_start_line⇐target.source_start_line,
  incoming_reference_count⇐target.incoming_reference_count,plan_id⇐target.plan_id
}}
duplicate ← rewrite.BuildCandidate ⟨beforeRaw,before.transactions,⟨target,target⟩⟩
"error" lib.AssertEq duplicate.state
# Exact raw mismatch and range failures use supplied parsed evidence and modified plan rows.
lines ← <¨lf loader.SplitKeepEmpty beforeRaw
lineIndex ← target.event_id_line-1
wrongLines ← {(𝕩=lineIndex)⊑⟨𝕩⊑lines,<"    ; event-id: entry-dddddddddddddddddddddddd"⟩}¨↕≠lines
Join ← {𝕊 xs:
  result ← ""
  {𝕊 i: {𝕊: result ∾↩ lf}⍟(i>0) @ ⋄ result ∾↩ >i⊑xs}¨↕≠xs
  result
}
wrong ← rewrite.BuildCandidate ⟨Join wrongLines,before.transactions,rows⟩
"error" lib.AssertEq wrong.state
rangeRows ← {(𝕩=1)⊑⟨𝕩⊑rows,MakeRow 99999⟩}¨↕≠rows
range ← rewrite.BuildCandidate ⟨beforeRaw,before.transactions,rangeRows⟩
"error" lib.AssertEq range.state

•Out "test_journal_cleanup_rewrite.bqn: OK"
