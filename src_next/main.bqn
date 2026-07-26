# main.bqn — compatibility wrapper
#
# The named developer inspection entrypoint is now:
#   src_next/developer_inspection.bqn
#
# This wrapper remains temporarily so direct callers of `bqn src_next/main.bqn`
# continue to receive byte-equivalent diagnostic output. It is not the
# production report entrypoint; daily use remains `tools/report`.

inspection ← •Import "developer_inspection.bqn"
inspection.Run ⊑•args
