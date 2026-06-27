#!/usr/bin/env bqn
# test_src_next_calc_envelope_calc.bqn — tests for envelope_calc.bqn primitives

lib ← •Import "test_lib.bqn"
calc ← •Import "../src_next/calc/envelope_calc.bqn"

# ── P1: EnvelopePace ───────────────────────────────────────
# allocated=40000, spent=8815, elapsed=12, total=60
p1 ← calc.EnvelopePace ⟨40000, 8815, 12, 60⟩
8000   lib.AssertEq p1.ideal_spent       # ⌊40000×12/60 = 8000
815    lib.AssertEq p1.overshoot          # 8815-8000 = 815
734    lib.AssertEq p1.daily_actual       # ⌊8815/12 = 734
666    lib.AssertEq p1.daily_target       # ⌊40000/60 = 666
"WARN" lib.AssertEq p1.health             # 734 > 666, < 1.5×666

# SAFE case: allocated=40000, spent=6000, elapsed=12, total=60
p1s ← calc.EnvelopePace ⟨40000, 6000, 12, 60⟩
"SAFE"  lib.AssertEq p1s.health
¯2000   lib.AssertEq p1s.overshoot        # underspent by 2000

# SHORT case: allocated=40000, spent=15000, elapsed=12, total=60
p1d ← calc.EnvelopePace ⟨40000, 15000, 12, 60⟩
"SHORT" lib.AssertEq p1d.health

# Zero elapsed (no spending yet)
p1z ← calc.EnvelopePace ⟨40000, 0, 0, 60⟩
0      lib.AssertEq p1z.daily_actual
0      lib.AssertEq p1z.pace_ratio
"SAFE" lib.AssertEq p1z.health

# ── P2: DaysToRecover ─────────────────────────────────────
# allocated=40000, spent=8815, elapsed=12, total=60
# daily_target=⌊40000/60=666, overshoot=8815-666×12=823
8 lib.AssertEq (calc.DaysToRecover ⟨40000, 8815, 12, 60, 550⟩)  # ⌈823/116=8
5 lib.AssertEq (calc.DaysToRecover ⟨40000, 8815, 12, 60, 500⟩)  # ⌈823/166=5
4 lib.AssertEq (calc.DaysToRecover ⟨40000, 8815, 12, 60, 400⟩)  # ⌈823/266=4

# Already at pace → 0
0 lib.AssertEq (calc.DaysToRecover ⟨40000, 6000, 12, 60, 600⟩)

# limit == target → cannot recover (division by zero → ∞)
∞ lib.AssertEq (calc.DaysToRecover ⟨40000, 8815, 12, 60, 666⟩)

# ── P3: RequiredDailyLimit ─────────────────────────────────
# allocated=40000, spent=8815, elapsed=12, total=60, target_days=7
# total_allowed=⌊40000×19/60=12666, remaining=12666-8815=3851, /7=550
550 lib.AssertEq (calc.RequiredDailyLimit ⟨40000, 8815, 12, 60, 7⟩)

# target_days=3 → total_allowed=⌊40000×15/60=10000, remaining=1185, /3=395
395 lib.AssertEq (calc.RequiredDailyLimit ⟨40000, 8815, 12, 60, 3⟩)

# target_days=14 → total_allowed=⌊40000×26/60=17333, remaining=8518, /14=608
608 lib.AssertEq (calc.RequiredDailyLimit ⟨40000, 8815, 12, 60, 14⟩)

# Already at pace (underspent): can spend more per day
# total_allowed=⌊40000×19/60=12666, remaining=12666-6000=6666, /7=952
952 lib.AssertEq (calc.RequiredDailyLimit ⟨40000, 6000, 12, 60, 7⟩)

# ── P4: EnvelopeDepletion ──────────────────────────────────
# remaining=31185, spent=8815, elapsed=12, total=60
# burn_rate=⌊8815/12=734, days_until_empty=⌈31185/734=43, days_left=48, shortfall=48-43=5
d4 ← calc.EnvelopeDepletion ⟨31185, 8815, 12, 60⟩
734 lib.AssertEq d4.burn_rate
48  lib.AssertEq d4.days_left
43  lib.AssertEq d4.days_until_empty
5   lib.AssertEq d4.shortfall_days      # 48-43 = 5 days short

# Safe case: remaining=34000, spent=6000, elapsed=12, total=60
# burn_rate=500, days_until_empty=⌈34000/500=68, days_left=48, shortfall=0
d4u ← calc.EnvelopeDepletion ⟨34000, 6000, 12, 60⟩
0  lib.AssertEq d4u.shortfall_days

# Tight case: remaining=5000, spent=37000, elapsed=48, total=60
# burn_rate=⌊37000/48=770, days_until_empty=⌈5000/770=7, days_left=12, shortfall=12-7=5
d4t ← calc.EnvelopeDepletion ⟨5000, 37000, 48, 60⟩
5  lib.AssertEq d4t.shortfall_days

# Already empty
d4e ← calc.EnvelopeDepletion ⟨0, 8815, 12, 60⟩
0   lib.AssertEq d4e.days_until_empty
48  lib.AssertEq d4e.shortfall_days      # 48-0 = 48 days left uncovered

# Zero spent (no burn rate) — sentinel 999, so shortfall=0
d4z ← calc.EnvelopeDepletion ⟨31185, 0, 0, 60⟩
0   lib.AssertEq d4z.burn_rate
999 lib.AssertEq d4z.days_until_empty
0   lib.AssertEq d4z.shortfall_days      # 60-999 negative → 0

# ── Format outputs (just ensure they produce strings) ─────
fp ← calc.FormatPace ⟨p1, "食費"⟩
1 lib.AssertEq (0 < ≠ fp)

fr ← calc.FormatRecovery ⟨8, 550, "食費"⟩
1 lib.AssertEq (0 < ≠ fr)

frt ← calc.FormatRecoveryTarget ⟨550, 7, "食費"⟩
1 lib.AssertEq (0 < ≠ frt)

fd ← calc.FormatDepletion ⟨d4, "食費"⟩
1 lib.AssertEq (0 < ≠ fd)

# Machine format: verify key fields present in output
# (Format*Machine functions output via •Out, test by capturing)
# At minimum, verify the format functions exist and don't crash

•Out "All envelope_calc tests passed."
