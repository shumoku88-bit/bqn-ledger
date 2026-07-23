#!/usr/bin/env bqn
# Read-only native Journal transaction export for UI shell wrappers.
# Args: base directory, format tsv|text.
# TSV fields: number date memo from to amount display

actual_source ← •Import "../src_next/actual_source.bqn"
args ← •args ⋄ tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
{𝕊: Fail "usage: journal_list_cmd.bqn <baseDir> <format: tsv|text>"}⍟(2≠≠args) @
baseDir ← 0⊑args ⋄ format ← 1⊑args
{𝕊: Fail ("invalid format: "∾format∾" (expected 'tsv' or 'text')")}⍟(¬∨´format⊸≡¨"tsv"‿"text") @
Join ← {𝕊 xs: out←"" ⋄ {out∾↩𝕩∾","}¨xs ⋄ (0<≠out) ? ¯1↓out ; ""}
Make ← {𝕊 tx:
  debits←({𝕩.delta>0}¨tx.postings)/tx.postings
  credits←({𝕩.delta<0}¨tx.postings)/tx.postings
  ⟨tx.date,tx.description,Join {𝕩.account_key}¨credits,Join {𝕩.account_key}¨debits,•Fmt +´0∾{𝕩.delta}¨debits⟩
}
rows ← Make¨actual_source.LoadTransactions baseDir
Display ← {𝕊 index:
  n←index+1 ⋄ f←index⊑rows
  (•Fmt n)∾": "∾(0⊑f)∾"  "∾(1⊑f)∾"  "∾(2⊑f)∾"→"∾(3⊑f)∾"  "∾(4⊑f)
}
PrintTsv ← {𝕊 index:
  n←index+1 ⋄ f←index⊑rows
  •Out (•Fmt n)∾tab∾(0⊑f)∾tab∾(1⊑f)∾tab∾(2⊑f)∾tab∾(3⊑f)∾tab∾(4⊑f)∾tab∾Display index
}
(format≡"tsv")◶⟨
  {𝕊: •Out "Journal transactions:" ⋄ {•Out Display 𝕩}¨↕≠rows},
  {𝕊: PrintTsv¨↕≠rows}
⟩ @
