variable "subscription_id" {
  type        = string
  description = "FlightOperations.DEV.TEST"
  default     = "ba19e6ca-9953-43f0-84b4-fbfa087f2958"
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
