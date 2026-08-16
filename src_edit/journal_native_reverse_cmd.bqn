# Select one native Journal transaction and emit its exact inverse posting intent.
actual_source ← •Import "../src/application/editor_actual.bqn"
dateToday ← •Import "../src/application/date_today.bqn"
validate ← •Import "validate.bqn"
lib ← •Import "../src/text/parse.bqn"
args ← •args ⋄ tab←@+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
{𝕊: Fail "usage: base id index reverseDate"}⍟(4≠≠args) @
base←0⊑args ⋄ id←1⊑args ⋄ index←lib.ToNum 2⊑args ⋄ reverseDate←3⊑args
revDate ← (0=≠reverseDate)◶⟨{𝕊:reverseDate},{𝕊:dateToday.Today @}⟩ @
check←validate.ValidateDate revDate ⋄ {𝕊:Fail 1⊑check}⍟(¬0⊑check) @
txs←actual_source.LoadTransactionRows base
{𝕊:Fail "native Journal transaction index is out of range"}⍟((index<0)∨index>≠txs) @
matches←({(𝕩.transaction_id≡id)∨(𝕩.description≡id)}¨txs)/txs
{𝕊:Fail "native Journal transaction id/description must match exactly once"}⍟((index=0)∧1≠≠matches) @
selected←(index=0)◶⟨{𝕊:(index-1)⊑txs},{𝕊:⊑matches}⟩ @
{𝕊:Fail "selected transaction is not actual"}⍟(selected.layer≢"actual") @
•Out "OK"∾tab∾"REVERSE_NATIVE"∾tab∾(•Fmt index)∾tab∾selected.date_text∾tab∾selected.description∾tab∾selected.transaction_id∾tab∾(•Fmt ≠selected.postings)∾tab∾revDate
InverseAmount ← {𝕊 text: ('-'=⊑(text∾"0"))◶⟨{𝕊:"-"∾text},{𝕊:1↓text}⟩ @ }
{𝕊 p: •Out p.account_key∾"="∾InverseAmount p.amount_text}¨selected.postings
