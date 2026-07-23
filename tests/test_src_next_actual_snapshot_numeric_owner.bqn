#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"
outlook ← •Import "../src_next/outlook.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 jlines:
  {
    sources ⇐ ⟨
      {source_file⇐"actual.journal", required⇐1, lines⇐jlines},
      {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
    ⟩
  }
}

base ← "fixtures/actual-snapshot-numeric-owner-target"
ctx ← ctx_mod.BuildContext base
observation ← "2026-02-05"

ContextWithRows ← {𝕊 rows:
  {
    base ⇐ ctx.base,
    as_of ⇐ ctx.as_of,
    cy ⇐ ctx.cy,
    resolved ⇐ ctx.resolved,
    posting_rows ⇐ rows,
    arithmetic_currency_proof ⇐ ctx.arithmetic_currency_proof,
    cube ⇐ ctx.cube,
    tbds ⇐ ctx.tbds,
    issues ⇐ ctx.issues
  }
}

RowsFor ← {𝕊 lines:
  result ← ctx_mod.BuildCheckedPostingProjectionFromSnapshot ⟨Snapshot lines, ctx.resolved, ctx.cy.start⟩
  "ok" lib.AssertEq result.state
  result.posting_rows
}

# Target fixture: checked Posting IR -> local [O,O+1) TBDS closing. Pre-cycle
# history and the O-day row are included; later rows are excluded.
at_o ← actual_snapshot.BuildAt ⟨ctx, observation⟩
"ok" lib.AssertEq at_o.state
"snapshot_active" lib.AssertEq at_o.reason
0 lib.AssertEq ≠ at_o.diagnostics
observation lib.AssertEq at_o.as_of
250 lib.AssertEq at_o.liq_total
250 lib.AssertEq at_o.assets_total
250 lib.AssertEq at_o.net_worth
⟨
  ⟨"assets:cash/JPY", 250⟩,
  ⟨"income:base/JPY", ¯300⟩,
  ⟨"expenses:misc/JPY", 50⟩
⟩ lib.AssertEq at_o.entries

# O remains the only cutoff. Moving it beyond cycle end admits the end-exclusive
# and later out-of-cycle actual rows.
after_cycle ← actual_snapshot.BuildAt ⟨ctx, "2026-02-12"⟩
"ok" lib.AssertEq after_cycle.state
260 lib.AssertEq after_cycle.liq_total
⟨
  ⟨"assets:cash/JPY", 260⟩,
  ⟨"income:base/JPY", ¯300⟩,
  ⟨"income:later/JPY", ¯30⟩,
  ⟨"income:outside/JPY", ¯20⟩,
  ⟨"expenses:misc/JPY", 90⟩
⟩ lib.AssertEq after_cycle.entries

# Invalid O fails closed rather than resembling a valid zero snapshot.
invalid_o ← actual_snapshot.BuildAt ⟨ctx, "not-a-date"⟩
"error" lib.AssertEq invalid_o.state
"invalid_observation" lib.AssertEq invalid_o.reason
"unavailable" lib.AssertEq invalid_o.liq_total
0 lib.AssertEq ≠ invalid_o.entries

valid_lines ← ⟨
  Line ⟨"2026-01-31", "pre", "income:base", "assets:cash", "100"⟩,
  Line ⟨"2026-02-01", "start", "income:base", "assets:cash", "200"⟩,
  Line ⟨"2026-02-05", "at-o", "assets:cash", "expenses:misc", "50"⟩
⟩

# One rejected source row produces two posting rows, but one diagnostic. A valid
# coordinate at or before O fails the cumulative snapshot closed.
unknown_before_rows ← RowsFor valid_lines ∾ ⟨Line ⟨"2026-02-05", "bad", "assets:missing", "expenses:misc", "7"⟩⟩
unknown_before_ctx ← ContextWithRows unknown_before_rows
unknown_before ← actual_snapshot.BuildAt ⟨unknown_before_ctx, observation⟩
"error" lib.AssertEq unknown_before.state
"rejected_actual_evidence" lib.AssertEq unknown_before.reason
1 lib.AssertEq ≠ unknown_before.diagnostics
bad_diag ← ⊑ unknown_before.diagnostics
"actual.journal" lib.AssertEq bad_diag.source_file
3 lib.AssertEq bad_diag.source_row
"unknown_account" lib.AssertEq bad_diag.status
"unavailable" lib.AssertEq unknown_before.net_worth

# A rejected row after O is outside this snapshot. Valid rows through O still
# produce the expected balance.
unknown_after_rows ← RowsFor valid_lines ∾ ⟨Line ⟨"2026-02-06", "bad-later", "assets:missing", "expenses:misc", "7"⟩⟩
unknown_after ← actual_snapshot.BuildAt ⟨ContextWithRows unknown_after_rows, observation⟩
"ok" lib.AssertEq unknown_after.state
250 lib.AssertEq unknown_after.liq_total
0 lib.AssertEq ≠ unknown_after.diagnostics

# Invalid-date actual evidence has no trustworthy coordinate and is therefore
# applicability-unknown.
invalid_date_rows ← RowsFor valid_lines ∾ ⟨Line ⟨"2026-02-30", "bad-date", "assets:cash", "expenses:misc", "7"⟩⟩
invalid_date ← actual_snapshot.BuildAt ⟨ContextWithRows invalid_date_rows, observation⟩
"error" lib.AssertEq invalid_date.state
"rejected_actual_evidence" lib.AssertEq invalid_date.reason
1 lib.AssertEq ≠ invalid_date.diagnostics
"invalid_date" lib.AssertEq (⊑ invalid_date.diagnostics).status

# A valid empty journal is a real zero snapshot, not unavailable/error.
empty_rows ← RowsFor ⟨⟩
empty_snapshot ← actual_snapshot.BuildAt ⟨ContextWithRows empty_rows, observation⟩
"ok" lib.AssertEq empty_snapshot.state
0 lib.AssertEq +´ empty_snapshot.amounts
0 lib.AssertEq ≠ empty_snapshot.entries
0 lib.AssertEq empty_snapshot.liq_total
0 lib.AssertEq empty_snapshot.net_worth

# Outlook propagates snapshot failure and does not combine plan values with an
# invalid actual balance into normal daily-allowance numbers.
error_vm ← outlook.BuildAt ⟨unknown_before_ctx, observation⟩
"error" lib.AssertEq error_vm.state
"rejected_actual_evidence" lib.AssertEq error_vm.reason
"unavailable" lib.AssertEq error_vm.liq_total
"unavailable" lib.AssertEq error_vm.liq_daily
1 lib.AssertEq ≠ error_vm.diagnostics
machine ← outlook.Format error_vm
1 lib.AssertEq ∨´ "src_next_outlook_status: error"⍷machine
1 lib.AssertEq ∨´ "src_next_outlook_reason: rejected_actual_evidence"⍷machine
1 lib.AssertEq ∨´ "src_next_outlook_diagnostic: actual.journal"⍷machine
human ← outlook.FormatHuman error_vm
1 lib.AssertEq ∨´ "Outlookの入力を信頼できない"⍷human
0 lib.AssertEq ∨´ "使える可用資金"⍷human

invalid_o_vm ← outlook.BuildAt ⟨ctx, "not-a-date"⟩
"error" lib.AssertEq invalid_o_vm.state
"invalid_observation" lib.AssertEq invalid_o_vm.reason

•Out "test_src_next_actual_snapshot_numeric_owner.bqn: OK"
