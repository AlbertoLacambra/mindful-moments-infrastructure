variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
}

variable "sku_name" {
  description = "SKU name for App Service Plan"
  type        = string
  default     = "B1"
}

variable "os_type" {
  description = "OS type for App Service Plan"
  type        = string
  default     = "Linux"
}

variable "node_version" {
  description = "Node.js version"
  type        = string
  default     = "20-lts"
}

variable "subnet_id" {
  description = "ID of the subnet for VNet integration"
  type        = string
}

variable "app_settings" {
  description = "Application settings"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
