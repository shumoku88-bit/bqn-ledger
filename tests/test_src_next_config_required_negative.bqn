#!/usr/bin/env bqn

# Auto-discovered wrapper for the subprocess-level A4 negative check.

lib ← •Import "test_lib.bqn"
result ← •SH ⟨"bash", "checks/check-src-next-config-required-negative.sh"⟩

0 lib.AssertEq 0 ⊑ result

•Out "test_src_next_config_required_negative.bqn: OK"
