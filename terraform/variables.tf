variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "uksouth"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, staging, prod)."
}

variable "db_admin_username" {
  type        = string
  description = "PostgreSQL admin username."
}

variable "db_admin_password" {
  type        = string
  description = "PostgreSQL admin password."
  sensitive   = true
}

variable "container_image" {
  type        = string
  description = "Full container image reference, e.g. ghcr.io/org/repo:sha."
}
