#!/usr/bin/env bash
# SessionStart hook: inject the project's AGENTS.md and enumerate project skills.
# Stdout is injected into the session context. Walks up from the session's
# working directory to the checkout root so it works from any subdirectory.
set -euo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$root" ]]; then
  root="${CLAUDE_PROJECT_DIR:-$PWD}"
  while [[ "$root" != "/" && ! -d "$root/.agents/skills" ]]; do
    root=$(dirname "$root")
  done
fi

# AGENTS.md holds the tool-neutral project instructions. Claude Code does not
# read it natively, so emit it here to bring its rules into the session.
if [[ -f "$root/AGENTS.md" ]]; then
  echo "Project instructions from AGENTS.md (repo root), injected by the SessionStart hook. Follow these for the whole session:"
  echo
  cat "$root/AGENTS.md"
  echo
fi

shopt -s nullglob
files=("$root"/.agents/skills/*/SKILL.md)
if ((${#files[@]} == 0)); then
  echo "Project skills: none found under .agents/skills/."
  exit 0
fi
echo "Project skills (.agents/skills/<name>/SKILL.md), enumerated by the SessionStart hook. This listing satisfies the AGENTS.md instruction to enumerate the skills at session start; do not repeat it. When a request names one or matches its description, read that SKILL.md and follow it before acting:"
for f in "${files[@]}"; do
  name=$(sed -n '/^---$/,/^---$/{s/^name:[[:space:]]*//p}' "$f" | head -1)
  desc=$(sed -n '/^---$/,/^---$/{s/^description:[[:space:]]*//p}' "$f" | head -1)
  [[ -n "$name" ]] || name=$(basename "$(dirname "$f")")
  echo "- $name: $desc"
done
