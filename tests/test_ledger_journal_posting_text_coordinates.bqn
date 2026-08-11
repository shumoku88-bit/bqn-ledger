#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
posting ← •Import "../src/ledger/journal_posting_text.bqn"

tab ← @+9

# The first semicolon owns the comment boundary; later semicolons are comment
# text and cannot re-enter the Posting body.
commented ← posting.Split "  Assets:Cash  -100 JPY ; first ; second"
lib.Assert commented.valid
"Assets:Cash" lib.AssertEq commented.account
"-100 JPY" lib.AssertEq commented.amount
⟨"-100","JPY"⟩ lib.AssertEq commented.words

# A canonical tab separator wins before the legacy three-token compatibility
# path. Single spaces remain legal inside the Account cell.
tabbed ← posting.Split "  Assets Long Cash"∾tab∾"-25 JPY ; note"
lib.Assert tabbed.valid
"Assets Long Cash" lib.AssertEq tabbed.account
"-25 JPY" lib.AssertEq tabbed.amount
⟨"-25","JPY"⟩ lib.AssertEq tabbed.words
0 lib.AssertEq tabbed.elided

# The first canonical two-space separator owns the boundary even when later
# repeated spaces occur inside the amount/comment suffix.
spaced ← posting.Split "  Assets Long Cash  -30 JPY   ; trailing"
lib.Assert spaced.valid
"Assets Long Cash" lib.AssertEq spaced.account
"-30 JPY" lib.AssertEq spaced.amount
⟨"-30","JPY"⟩ lib.AssertEq spaced.words

•Out "test_ledger_journal_posting_text_coordinates: ok"
