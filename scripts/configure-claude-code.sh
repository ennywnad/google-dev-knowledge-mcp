#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# configure-claude-code.sh — Add the Google Developer Knowledge MCP server
# to Claude Code CLI using the `claude mcp add` command.
#
# Uses OAuth/ADC authentication (run setup-auth.sh first).
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../terraform"

# Try to read the project ID from Terraform output
if command -v terraform &>/dev/null && [[ -d "$TF_DIR" ]]; then
  PROJECT_ID=$(cd "$TF_DIR" && terraform output -raw project_id 2>/dev/null || true)
fi

if [[ -z "${PROJECT_ID:-}" ]]; then
  PROJECT_ID="${1:-}"
fi

if [[ -z "$PROJECT_ID" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  echo ""
  echo "Or run from a directory where 'terraform output project_id' works."
  exit 1
fi

echo "==> Adding Google Developer Knowledge MCP server to Claude Code"
echo "    Project: ${PROJECT_ID}"
echo ""

claude mcp add google-dev-knowledge \
  --transport http \
  "https://developerknowledge.googleapis.com/mcp" \
  --header "X-goog-user-project: ${PROJECT_ID}"

echo ""
echo "==> Done! The MCP server has been added to Claude Code."
echo "    Test it by asking: 'How do I list Cloud Storage buckets?'"
echo "    You should see a tool call to search_documents."
