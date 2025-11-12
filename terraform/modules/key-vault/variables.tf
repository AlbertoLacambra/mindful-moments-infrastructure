variable "resource_group_name" {  type = string  }
variable "location" {  type = string  }
variable "key_vault_name" {  type = string  }
variable "sku_name" {  type = string;  default = "standard"  }
variable "tenant_id" {  type = string  }
variable "app_service_principal_id" {  type = string  }
variable "secrets" {  type = map(string);  default = {};  sensitive = true  }
variable "tags" {  type = map(string);  default = {}  }
