#!/bin/bash
# LOG hook — records every terraform plan to the deploy log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../deploy.log"

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty')
INTERRUPTED=$(echo "$INPUT" | jq -r '.tool_response.interrupted // false')

if echo "$CMD" | grep -q "terraform plan"; then
  if [ "$INTERRUPTED" = "true" ]; then
    STATUS="INTERRUPTED"
  elif echo "$STDOUT" | grep -q "^Error:"; then
    STATUS="FAILED"
  else
    STATUS="SUCCESS"
  fi
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] terraform plan executed — $STATUS" >> "$LOG_FILE"
fi
