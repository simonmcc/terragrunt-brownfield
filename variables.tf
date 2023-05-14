variable "location" {
  description = "Azure location, `az account list-locations`"
  type        = string
}

variable "resource_group_name" {
  description = "The name of an existing resource group."
  type        = string
}
