# Select one native Journal transaction and emit its exact inverse posting intent.
actual_source ← •Import "../src_next/actual_source.bqn"
date ← •Import "../src_next/date.bqn"
validate ← •Import "validate.bqn"
lib ← •Import "../src/text/parse.bqn"
args ← •args ⋄ tab←@+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
{𝕊: Fail "usage: base id index reverseDate"}⍟(4≠≠args) @
base←0⊑args ⋄ id←1⊑args ⋄ index←lib.ToNum 2⊑args ⋄ reverseDate←3⊑args
revDate ← (0=≠reverseDate)◶⟨{𝕊:reverseDate},{𝕊:date.Today @}⟩ @
check←validate.ValidateDate revDate ⋄ {𝕊:Fail 1⊑check}⍟(¬0⊑check) @
txs←actual_source.LoadTransactionRows base
selected←@
{𝕊:
  matches←({(𝕩.transaction_id≡id)∨(𝕩.description≡id)}¨txs)/txs
  {𝕊:Fail "native Journal transaction id/description must match exactly once"}⍟(1≠≠matches) @
  selected↩⊑matches
}⍟(index=0) @
{𝕊:
  {𝕊:Fail "native Journal transaction index is out of range"}⍟((index<1)∨index>≠txs) @
  selected↩(index-1)⊑txs
}⍟(index>0) @
{𝕊:Fail "selected transaction is not actual"}⍟(selected.layer≢"actual") @
•Out "OK"∾tab∾"REVERSE_NATIVE"∾tab∾(•Fmt index)∾tab∾selected.date_text∾tab∾selected.description∾tab∾selected.transaction_id∾tab∾(•Fmt ≠selected.postings)∾tab∾revDate
InverseAmount ← {𝕊 text: ('-'=⊑(text∾"0"))◶⟨{𝕊:"-"∾text},{𝕊:1↓text}⟩ @ }
{𝕊 p: •Out p.account_key∾"="∾InverseAmount p.amount_text}¨selected.postings
