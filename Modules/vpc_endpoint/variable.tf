variable "aws_vpc_endpoint" {
  type = string
}
variable "subnet_ids" {
  type    = list(any)
  default = []
}
variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "security_group_ids" {
  type    = list(any)
  default = null
}
variable "route_table_ids" {
  type    = list(any)
  default = null
}
variable "environment" {
  type = string
}
variable "vpc_endpoint_type" {
  type = string
}
variable "private_dns_enabled" {
  type    = bool
  default = false
}
variable "vpc_id" {
  type = string
}
variable "tags" {
  type = map(any)
}
