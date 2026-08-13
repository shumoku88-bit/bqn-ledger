#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
section ← •Import "../src/sections/home_calendar.bqn"

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

⟨" 1 "," 2*"," 3$"," 4+"⟩ lib.AssertEq section.CellText ⟨calendar,policy⟩

•Out "test_section_home_calendar_cell_text: ok"
