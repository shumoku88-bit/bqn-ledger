#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
section ← •Import "../src/sections/home_calendar.bqn"

tab ← @+9
lf ← @+10
calendar ← {
  weekday_start⇐5,
  days⇐{
    count⇐4,
    index⇐↕4,
    day⇐1‿2‿3‿4,
    date⇐⟨"2026-08-01","2026-08-02","2026-08-03","2026-08-04"⟩,
    cycle_end⇐0‿1‿0‿1,
    plan_due⇐0‿0‿1‿1,
    issue_due⇐0‿0‿0‿1
  }
}
policy ← {
  cycle_end_marker⇐"*",plan_due_marker⇐"$",issue_due_marker⇐"!",multiple_marker⇐"+"
}

expected ← ∾⟨
  "2026-08-01",tab," 1 ","  2026-08-01",lf,
  "2026-08-02",tab," 2*","  2026-08-02",lf,
  "2026-08-03",tab," 3$","  2026-08-03",lf,
  "2026-08-04",tab," 4+","  2026-08-04",lf
⟩
expected lib.AssertEq section.FormatChoices ⟨calendar,policy⟩

•Out "test_section_home_calendar_choices: ok"
