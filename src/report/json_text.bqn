# Pure JSON text constructors. Callers explicitly choose string/number/array/object;
# unsupported runtime values cannot be silently coerced to null.

amount ← •Import "../ledger/amount_text.bqn"

String ← {𝕊 value:
  quote←@+34 ⋄ slash←@+92
  Escape ← {
    (𝕩=quote) ? slash∾quote ;
    (𝕩=slash) ? slash∾slash ;
    (𝕩=@+8) ? slash∾"b" ;
    (𝕩=@+9) ? slash∾"t" ;
    (𝕩=@+10) ? slash∾"n" ;
    (𝕩=@+12) ? slash∾"f" ;
    (𝕩=@+13) ? slash∾"r" ;
    (𝕩<@+32) ? slash∾"u00"∾((⌊(𝕩-@)÷16)⊑"0123456789abcdef")∾((16|𝕩-@)⊑"0123456789abcdef") ;
    ⟨𝕩⟩
  }
  quote∾(∾Escape¨value)∾quote
}
ExactNumber ← {𝕊 coefficient‿scale: amount.Format ⟨coefficient,scale⟩}
Boolean ← {𝕊 value: value⊑"false"‿"true"}
Pair ← {𝕊 key‿encodedValue: (String key)∾": "∾encodedValue}
Array ← {𝕊 encodedValues: "["∾(∾{𝕊 i: ((i>0)/", ")∾i⊑encodedValues}¨↕≠encodedValues)∾"]"}
Object ← {𝕊 encodedPairs: "{"∾(∾{𝕊 i: ((i>0)/", ")∾i⊑encodedPairs}¨↕≠encodedPairs)∾"}"}

{String⇐String,ExactNumber⇐ExactNumber,Boolean⇐Boolean,Pair⇐Pair,Array⇐Array,Object⇐Object}
