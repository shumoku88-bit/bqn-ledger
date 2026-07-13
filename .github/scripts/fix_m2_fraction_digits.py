#!/usr/bin/env python3
from pathlib import Path

path = Path("src_edit/validate.bqn")
text = path.read_text(encoding="utf-8")
old = "count ↩ (≠ s) - 1 - ⊑ positions"
new = "count ↩ ((≠ s) - 1) - ⊑ positions"
if text.count(old) != 1:
    raise SystemExit(f"expected one fraction expression, got {text.count(old)}")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
