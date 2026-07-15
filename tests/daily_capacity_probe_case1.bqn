#!/usr/bin/env bqn

reference ← •Import "daily_capacity_contract_reference.bqn"

observation ← { date ⇐ "2026-07-01", source ⇐ "synthetic_test" }
horizon ← {
  state ⇐ "resolved",
  kind ⇐ "cycle",
  start ⇐ "2026-07-01",
  end_exclusive ⇐ "2026-07-11",
  source_ref ⇐ "synthetic:cycle"
}
domain ← {
  state ⇐ "proven",
  currency ⇐ "JPY",
  amount_scale ⇐ 0,
  basis ⇐ "synthetic_single_currency",
  message ⇐ ""
}
assets ← {
  state ⇐ "resolved",
  scope_id ⇐ "synthetic-assets",
  basis_kind ⇐ "account_balance",
  policy_ref ⇐ "owner:test-assets",
  rows ⇐ ⟨⟩
}
obligations ← {
  state ⇐ "resolved",
  scope_id ⇐ "synthetic-obligations",
  policy_ref ⇐ "owner:test-obligations",
  rows ⇐ ⟨⟩
}
input ← {
  observation ⇐ observation,
  horizon ⇐ horizon,
  arithmetic_domain ⇐ domain,
  asset_scope ⇐ assets,
  obligation_scope ⇐ obligations
}

•Out •Fmt reference.Build input
