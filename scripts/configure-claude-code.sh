#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# configure-claude-code.sh — Add the Google Developer Knowledge MCP server
# to Claude Code CLI using OAuth (Desktop app client ID + secret).
#
# Prerequisites:
#   1. Run `terraform apply` to set up the project and OAuth consent screen.
#   2. Create a Desktop app OAuth client ID at the URL output by Terraform
#      (oauth_credentials_url), then download the JSON or copy the values.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../terraform"

# Try to read the project ID from Terraform output
if command -v terraform &>/dev/null && [[ -d "$TF_DIR" ]]; then
  PROJECT_ID=$(cd "$TF_DIR" && terraform output -raw project_id 2>/dev/null || true)
  CONSENT_URL=$(cd "$TF_DIR" && terraform output -raw oauth_consent_url 2>/dev/null || true)
  CREDS_URL=$(cd "$TF_DIR" && terraform output -raw oauth_credentials_url 2>/dev/null || true)
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

echo "==> Configuring Google Developer Knowledge MCP for Claude Code"
echo "    Project: ${PROJECT_ID}"
echo ""

if [[ -n "${CONSENT_URL:-}" ]]; then
  echo "    1. Configure OAuth consent screen (if not done yet):"
  echo "       ${CONSENT_URL}"
  echo ""
fi
if [[ -n "${CREDS_URL:-}" ]]; then
  echo "    2. Create a Desktop app OAuth client ID (if not done yet):"
  echo "       ${CREDS_URL}"
  echo ""
fi

# Accept client_id as arg 2, or prompt
if [[ -n "${2:-}" ]]; then
  CLIENT_ID="$2"
else
  read -r -p "    OAuth Client ID: " CLIENT_ID
fi

if [[ -z "$CLIENT_ID" ]]; then
  echo "Error: OAuth Client ID is required."
  exit 1
fi

# Accept client_secret via env var or prompt (never as a positional arg)
if [[ -z "${MCP_CLIENT_SECRET:-}" ]]; then
  read -r -s -p "    OAuth Client Secret: " MCP_CLIENT_SECRET
  echo ""
fi

export MCP_CLIENT_SECRET

echo ""
echo "==> Adding MCP server to Claude Code..."

# Remove any existing entry so we can re-add with updated config
claude mcp remove google-dev-knowledge -s local 2>/dev/null || true

claude mcp add google-dev-knowledge \
  --transport http \
  --client-id "$CLIENT_ID" \
  --client-secret \
  "https://developerknowledge.googleapis.com/mcp" \
  --header "X-goog-user-project: ${PROJECT_ID}"

echo ""
echo "==> Done! Claude Code will open a browser for OAuth consent on first use."
echo "    Test it by asking: 'How do I list Cloud Storage buckets?'"
