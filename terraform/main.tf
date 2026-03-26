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
# Enable APIs
# -----------------------------------------------------------------------------
resource "google_project_service" "developer_knowledge" {
  project = google_project.mcp.project_id
  service = "developerknowledge.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "billing_budgets" {
  project = google_project.mcp.project_id
  service = "billingbudgets.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  project = google_project.mcp.project_id
  service = "monitoring.googleapis.com"

  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# Billing Budget & Alerts
# Sends email notifications at 50%, 90%, and 100% of the monthly budget.
# -----------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email" {
  project      = google_project.mcp.project_id
  display_name = "Budget Alert Email"
  type         = "email"

  labels = {
    email_address = var.support_email
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account
  display_name    = "${var.project_name} - Monthly Budget"

  budget_filter {
    projects = ["projects/${google_project.mcp.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.email.id]
    disable_default_iam_recipients   = false
  }

  depends_on = [google_project_service.billing_budgets]
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
