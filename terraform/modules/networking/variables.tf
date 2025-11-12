variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_name" {
  description = "Name of the app subnet"
  type        = string
  default     = "app-subnet"
}

variable "app_subnet_prefix" {
  description = "Address prefix for the app subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "database_subnet_name" {
  description = "Name of the database subnet"
  type        = string
  default     = "database-subnet"
}

variable "database_subnet_prefix" {
  description = "Address prefix for the database subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
