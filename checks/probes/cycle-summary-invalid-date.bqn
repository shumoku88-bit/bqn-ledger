#!/usr/bin/env bqn

ctx_mod ← •Import "../../src_next/context.bqn"
cs ← •Import "../../src_next/cycle_summary.bqn"

# Load root context to reuse resolved mappings and TBDS structure.
root_ctx ← ctx_mod.BuildContext "fixtures/cycle-remaining-plan-characterization"

# Build custom context pointing to the two-row invalid-date fixture.
ctx ← {
  base ⇐ "fixtures/cycle-remaining-plan-characterization/sub_invalid_date",
  cy ⇐ root_ctx.cy,
  resolved ⇐ root_ctx.resolved,
  posting_rows ⇐ root_ctx.posting_rows,
  arithmetic_currency_proof ⇐ root_ctx.arithmetic_currency_proof,
  cube ⇐ root_ctx.cube,
  tbds ⇐ root_ctx.tbds,
  issues ⇐ root_ctx.issues
}

# The runtime contract is controlled fail-closed output, not a BQN crash.
•Out cs.Format cs.Build ctx
