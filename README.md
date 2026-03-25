# Google Developer Knowledge MCP Server

Terraform-managed setup for the [Google Developer Knowledge MCP server](https://cloud.google.com/docs/developer-knowledge-mcp), which gives AI tools access to official Google developer documentation — Firebase, Google Cloud, Android, Maps, and more.

## What this does

This repo creates a **dedicated GCP project** so you can isolate and track costs for the Developer Knowledge API. It uses **OAuth / Application Default Credentials (ADC)** for authentication and provides configuration for both **Claude Code** (CLI) and **VS Code** (Claude extension).

### Tools provided by the MCP server

| Tool | Description |
|------|-------------|
| `search_documents` | Search Google's developer documentation for relevant pages and snippets |
| `get_documents` | Retrieve full page content using `parent` IDs from search results |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated
- A GCP billing account (`gcloud billing accounts list`)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or VS Code with the Claude extension

## Quick Start

### 1. Clone this repo

```bash
git clone https://github.com/ennywnad/google-dev-knowledge-mcp.git
cd google-dev-knowledge-mcp
```

### 2. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_id      = "dev-knowledge-mcp-yourname"  # Must be globally unique
billing_account = "XXXXXX-XXXXXX-XXXXXX"
```

> **Note:** The `project_id` must be globally unique across all of GCP. If `dev-knowledge-mcp` is taken, add a suffix like your initials or a number.

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Terraform will output your project ID and direct links to the API dashboard and billing reports.

### 4. Authenticate (OAuth / ADC)

```bash
cd ..
./scripts/setup-auth.sh
```

This runs `gcloud auth application-default login` scoped to your new project. A browser window will open for you to authorize.

### 5. Configure your AI tools

#### Claude Code (CLI)

```bash
./scripts/configure-claude-code.sh
```

Or manually:

```bash
claude mcp add google-dev-knowledge \
  --transport http \
  "https://developerknowledge.googleapis.com/mcp" \
  --header "X-goog-user-project: YOUR_PROJECT_ID"
```

#### VS Code (Claude Extension)

Copy `.vscode/mcp.json` into your project's `.vscode/` directory (or your user settings), and replace `YOUR_PROJECT_ID` with your actual project ID.

A reference config is also available at `mcp-configs/claude-code.json`.

### 6. Verify it works

Open Claude Code or VS Code and try:

```
How do I list Cloud Storage buckets?
```

You should see a tool call to `search_documents`. If you do, it's working.

## Monitoring Costs

Since this runs in a dedicated GCP project, tracking costs is straightforward:

- **API Dashboard:** After `terraform apply`, check the `api_console_url` output for a direct link to API metrics (requests, errors, latency).
- **Billing Reports:** Use the `billing_url` output to view costs filtered to this project.
- **Quota:** Go to **IAM & Admin > Quotas & System Limits** in the Cloud Console, filter by **Developer Knowledge API**.

The Developer Knowledge API is currently in Preview ("Pre-GA"). Check [Google's pricing page](https://cloud.google.com/developer-knowledge/pricing) for the latest cost details.

## Project Structure

```
.
├── README.md
├── .gitignore
├── .vscode/
│   └── mcp.json                  # VS Code MCP config (replace PROJECT_ID)
├── mcp-configs/
│   └── claude-code.json          # Reference config for Claude Code
├── scripts/
│   ├── setup-auth.sh             # ADC authentication setup
│   └── configure-claude-code.sh  # Add MCP server to Claude Code CLI
└── terraform/
    ├── main.tf                   # Project, API, and MCP server setup
    ├── variables.tf              # Input variables
    ├── versions.tf               # Provider version constraints
    └── terraform.tfvars.example  # Example variable values (copy to .tfvars)
```

## Known Limitations

- **English-only** results from the documentation search
- **Public docs only** — no GitHub, blogs, YouTube, or OSS content
- **Network-dependent** — requires live connection to Google Cloud services
- **Pre-GA** — subject to the "Pre-GA Offerings Terms" in Google's Service Specific Terms

## Cleanup

To tear down the project and stop all billing:

```bash
cd terraform
terraform destroy
```

This deletes the GCP project entirely, which removes the API, all credentials, and all associated resources.
