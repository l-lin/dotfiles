#!/bin/bash
set -e

cd "$HOME/.claude/hooks"
cat | npx tsx skill-activation-prompt.ts
