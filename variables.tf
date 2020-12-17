variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "asia-northeast1"
}

variable "default_zone" {
  description = "Default zone to create resources where applicable."
  type        = string
  default     = "asia-northeast1-b"
}

variable "source_bucket" {
  description = "Source bucket name"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "cluster_master_version" {
  description = "Cluster master version"
  type        = string
}

variable "pool_name" {
  description = "Nodepool name"
  type        = string
}

variable "function_name" {
  description = "Cloud Functions name"
  type        = string
}

variable "mail_address" {
  description = "My MailAddress"
  type        = string
}