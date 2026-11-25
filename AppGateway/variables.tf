variable "subscription_id" {
  type        = string
  description = "Azure subscription ID; pass with -var at plan/apply time."
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

variable "backend_fqdn" {
  type        = string
  default     = "httpbin.org"
  description = "Backend host for every pool; httpbin.org answers any path with 200."
}

variable "probe_path" {
  type        = string
  default     = "/status/200"
  description = "Health probe path on the backend."
}

variable "backend_path_prefix" {
  type        = string
  default     = "/anything"
  description = "Prefix for the per-app backend path override, e.g. /anything/alpha/."
}
