#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
navigation ← •Import "../src/application/home_navigation.bqn"

1 lib.AssertEq navigation.ValidMove "day-prev"
1 lib.AssertEq navigation.ValidMove "week-next"
1 lib.AssertEq navigation.ValidMove "month-next"
0 lib.AssertEq navigation.ValidMove "inspect"
0 lib.AssertEq navigation.ValidMove "week"

# Day and week movement are continuous Gregorian coordinates, independent of the
# currently visible calendar month.
"2026-02-01" lib.AssertEq navigation.MoveDate ⟨"2026-01-31","day-next"⟩
"2025-12-31" lib.AssertEq navigation.MoveDate ⟨"2026-01-01","day-prev"⟩
"2026-02-04" lib.AssertEq navigation.MoveDate ⟨"2026-01-28","week-next"⟩
"2025-12-29" lib.AssertEq navigation.MoveDate ⟨"2026-01-05","week-prev"⟩

# Month movement retains the existing AddMonths clipping contract. No preferred
# day-of-month state is invented after a clip.
"2026-02-28" lib.AssertEq navigation.MoveDate ⟨"2026-01-31","month-next"⟩
"2026-02-28" lib.AssertEq navigation.MoveDate ⟨"2026-03-31","month-prev"⟩
feb ← navigation.MoveDate ⟨"2026-01-31","month-next"⟩
"2026-03-28" lib.AssertEq navigation.MoveDate ⟨feb,"month-next"⟩

•Out "test_home_navigation: ok"
