#!/usr/bin/env bash
# Stop hook: nudge the agent to reconcile CLAUDE.md when the codebase changed
# more recently than CLAUDE.md.
#
# Loop-free by design: the check is purely mtime-based, so re-saving CLAUDE.md
# (which the sync-claude-md skill does even when already aligned) clears it.
#
# Emits Stop-hook JSON on stdout to block stopping with a reason when stale;
# otherwise exits 0 silently. Never hard-fails the session.

set -u

# Resolve repo root relative to this script (.claude/hooks/ -> repo root).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)" || exit 0
cd "$ROOT" 2>/dev/null || exit 0
[ -f CLAUDE.md ] || exit 0

mtime() {
    # GNU stat, then BSD stat; 0 if missing.
    stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0
}

claude_mtime="$(mtime CLAUDE.md)"
newest=0
for f in src/*.lua SmartLFG.toc; do
    [ -f "$f" ] || continue
    m="$(mtime "$f")"
    [ "$m" -gt "$newest" ] && newest="$m"
done

if [ "$newest" -gt "$claude_mtime" ]; then
    printf '%s\n' '{"decision":"block","reason":"CLAUDE.md is older than changed source files (src/*.lua or SmartLFG.toc). Run the sync-claude-md skill to reconcile CLAUDE.md with the changes, then re-save CLAUDE.md (even if already aligned) so it is at least as new as the sources."}'
fi
exit 0
