# test_simple.bqn
F ← {
  x ← 𝕩
  (x=1) ◶ ⟨ {x+100}, {10+1} ⟩ @
}

•Out •Fmt F 1
•Out •Fmt F 2
