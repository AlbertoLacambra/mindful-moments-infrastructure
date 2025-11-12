variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "server_name" {
  type = string
}
variable "database_name" {
  type = string
}
variable "administrator_login" {
  type    = string
  default = "psqladmin"
}
variable "administrator_password" {
  type      = string
  sensitive = true
}
variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}
variable "postgres_version" {
  type    = string
  default = "15"
}
variable "storage_mb" {
  type    = number
  default = 32768
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}
variable "delegated_subnet_id" {
  type = string
}
variable "private_dns_zone_id" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
