###############################################################################
# Google Developer Knowledge MCP — GCP Project & API Setup
#
# Creates a dedicated GCP project, enables the Developer Knowledge API,
# and prepares everything needed for the MCP server.
###############################################################################

provider "google" {
  region = var.region
}

# -----------------------------------------------------------------------------
# Project
# -----------------------------------------------------------------------------
resource "google_project" "mcp" {
  name            = var.project_name
  project_id      = var.project_id
  billing_account = var.billing_account

  # Conditionally set org_id or folder_id
  org_id    = var.folder_id == "" ? (var.org_id != "" ? var.org_id : null) : null
  folder_id = var.folder_id != "" ? var.folder_id : null

  deletion_policy = "DELETE"
}

# -----------------------------------------------------------------------------
# Enable the Developer Knowledge API
# -----------------------------------------------------------------------------
resource "google_project_service" "developer_knowledge" {
  project = google_project.mcp.project_id
  service = "developerknowledge.googleapis.com"

  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# Enable the MCP server for the project
#
# NOTE: As of March 17, 2025 the MCP server is automatically enabled when the
# API is enabled. This null_resource runs the gcloud command as a safety net
# and for older projects.
# -----------------------------------------------------------------------------
resource "null_resource" "enable_mcp_server" {
  depends_on = [google_project_service.developer_knowledge]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud beta services mcp enable developerknowledge.googleapis.com \
        --project=${google_project.mcp.project_id}
    EOT
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "project_id" {
  description = "The GCP project ID for the Developer Knowledge MCP server"
  value       = google_project.mcp.project_id
}

output "project_number" {
  description = "The GCP project number"
  value       = google_project.mcp.number
}

output "api_console_url" {
  description = "Direct link to the API dashboard to monitor usage and costs"
  value       = "https://console.cloud.google.com/apis/api/developerknowledge.googleapis.com/metrics?project=${google_project.mcp.project_id}"
}

output "billing_url" {
  description = "Direct link to billing reports filtered to this project"
  value       = "https://console.cloud.google.com/billing/linkedaccount?project=${google_project.mcp.project_id}"
}

output "oauth_consent_url" {
  description = "Direct link to configure the OAuth consent screen (do this before creating a client ID)"
  value       = "https://console.cloud.google.com/apis/credentials/consent?project=${google_project.mcp.project_id}"
}

output "oauth_credentials_url" {
  description = "Direct link to create a Desktop app OAuth 2.0 client ID"
  value       = "https://console.cloud.google.com/apis/credentials/oauthclient?project=${google_project.mcp.project_id}"
}
