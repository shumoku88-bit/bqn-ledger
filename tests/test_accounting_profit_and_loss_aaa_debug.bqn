#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"

registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
lf ← @+10
Raw ← {𝕊 lines: ∾{𝕩∾lf}¨lines}
maxConsecutive ← "9007199254740991"
accounts ← ⟨
  "expenses:subset-a	role=expense	currency=JPY",
  "assets:subset-bridge	role=asset	currency=JPY",
  "expenses:subset-b	role=expense	currency=JPY",
  "liabilities:subset-a	role=liability	currency=JPY",
  "liabilities:subset-bridge	role=liability	currency=JPY",
  "liabilities:subset-b	role=liability	currency=JPY"
⟩
debugRaw ← Raw ⟨
  "commodity JPY","",
  "account expenses:subset-a","    ; role: expense","",
  "account assets:subset-bridge","    ; role: asset","",
  "account expenses:subset-b","    ; role: expense","",
  "account liabilities:subset-a","    ; role: liability","",
  "account liabilities:subset-bridge","    ; role: liability","",
  "account liabilities:subset-b","    ; role: liability","",
  "2026-01-10 * subset A","    ; event-id: pnl-expense-subset-a","    ; layer: actual",
  "    expenses:subset-a "∾maxConsecutive∾" JPY","    liabilities:subset-a -"∾maxConsecutive∾" JPY","",
  "2026-01-11 * subset bridge","    ; event-id: pnl-expense-subset-bridge","    ; layer: actual",
  "    assets:subset-bridge 1 JPY","    liabilities:subset-bridge -1 JPY","",
  "2026-01-12 * subset B","    ; event-id: pnl-expense-subset-b","    ; layer: actual",
  "    expenses:subset-b 2 JPY","    liabilities:subset-b -2 JPY"
⟩
built ← snapshot.Build ⟨accounts,debugRaw,registry⟩
•Out "debug snapshot state: "∾built.state
{𝕊 d:
  •Out "stage="∾d.stage
  •Out "code="∾d.code
  •Out "line="∾•Fmt d.line
  •Out "message="∾d.message
}¨built.diagnostics
0 lib.AssertEq 1
