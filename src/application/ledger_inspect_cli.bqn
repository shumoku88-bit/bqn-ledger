# Non-authoritative canonical Actual Fact/provenance inspection.

sources ← •Import "report_source_adapter.bqn"
tab ← @+9 ⋄ args ← •args
Fail ← {𝕊 diagnostics:{𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.stage∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics ⋄ •Exit 1}
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected canonical Household BASE" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:•Out "ERROR"∾tab∾"currency_registry"∾tab∾registryResult.code∾tab∾registryResult.message ⋄ •Exit 1}⍟(registryResult.state≢"ok") @
actual ← sources.CanonicalActual ⟨base,registryResult.registry⟩
{𝕊:Fail actual.diagnostics}⍟(actual.state≢"ok") @
facts ← actual.facts
•Out "ledger_inspect"∾tab∾"state"∾tab∾"ok"
•Out "ledger_inspect"∾tab∾"transactions"∾tab∾•Fmt facts.transactions.count
•Out "ledger_inspect"∾tab∾"postings"∾tab∾•Fmt facts.postings.count
domains ← (0<facts.domains.count)◶⟨
  {𝕊:""},
  {𝕊:(⊑facts.domains.code)∾∾{","∾𝕩}¨1↓facts.domains.code}
⟩ @
•Out "ledger_inspect"∾tab∾"domains"∾tab∾domains
source ← ⊑facts.sources.name
{𝕊 i:•Out "transaction"∾tab∾source∾tab∾(i⊑facts.transactions.transaction_id)∾tab∾i⊑facts.transactions.date_text}¨facts.transactions.index
{𝕊 i:
  accountIndex ← i⊑facts.postings.account_index ⋄ transactionIndex ← i⊑facts.postings.transaction_index
  •Out "posting"∾tab∾source∾tab∾(transactionIndex⊑facts.transactions.transaction_id)∾tab∾(i⊑facts.postings.posting_id)∾tab∾(accountIndex⊑facts.accounts.key)∾tab∾(•Fmt i⊑facts.postings.coefficient)∾tab∾•Fmt i⊑facts.postings.scale
}¨facts.postings.index
