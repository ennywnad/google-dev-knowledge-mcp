#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup-auth.sh — Authenticate for the Google Developer Knowledge MCP server
#
# Uses Application Default Credentials (ADC) via gcloud CLI.
# Run this once after terraform apply, and again if your credentials expire.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../terraform"

# Try to read the project ID from Terraform output
if command -v terraform &>/dev/null && [[ -d "$TF_DIR" ]]; then
  PROJECT_ID=$(cd "$TF_DIR" && terraform output -raw project_id 2>/dev/null || true)
fi

# Fall back to argument or prompt
if [[ -z "${PROJECT_ID:-}" ]]; then
  PROJECT_ID="${1:-}"
fi

if [[ -z "$PROJECT_ID" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  echo ""
  echo "Or run from a directory where 'terraform output project_id' works."
  exit 1
fi

echo "==> Authenticating ADC for project: ${PROJECT_ID}"
echo ""

gcloud auth application-default login --project="$PROJECT_ID"

echo ""
echo "==> Done! ADC credentials are now set for project ${PROJECT_ID}."
echo "    Your MCP server config should use authProviderType: google_credentials"
echo ""
echo "    To verify, try a prompt in Claude Code or VS Code like:"
echo "    'How do I list Cloud Storage buckets?'"
