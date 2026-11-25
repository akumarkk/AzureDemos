variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
  default     = "REDACTED_SUBSCRIPTION_ID"
}

variable "location" {
  type    = string
  default = "westus2"
}

variable "resource_group_name" {
  type    = string
  default = "azedemo-appgw-rg"
}

variable "apps" {
  type        = list(string)
  description = "One listener, pool, setting, probe and rule is generated per entry."
}

variable "explicit_empty" {
  type        = bool
  default     = false
  description = "Set optional text fields to an empty string so config matches what Azure returns."
}
