variable "project_id" {
  description = "The GCP project ID to create for the Developer Knowledge MCP server"
  type        = string
  default     = "dev-knowledge-mcp"
}

variable "project_name" {
  description = "Human-readable project name"
  type        = string
  default     = "Developer Knowledge MCP"
}

variable "billing_account" {
  description = "The billing account ID to associate with the project (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
  sensitive   = true
}

variable "org_id" {
  description = "The GCP organization ID. Leave empty if creating under 'No organization'."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "The GCP folder ID to create the project under. Leave empty for org root or no-org."
  type        = string
  default     = ""
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "support_email" {
  description = "Email address to receive billing budget alerts"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 10
}
