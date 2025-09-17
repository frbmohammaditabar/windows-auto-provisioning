variable "vault_addr" {}
variable "vault_token" {}

variable "pm_api_url" {}
variable "pm_user" {}
variable "pm_password" {}
variable "pm_node" {}
variable "pm_storage" {}
variable "pm_bridge" {}

variable "template_name" {}
variable "instance_prefix" {}
variable "instances" {
  type = list(string)
}
