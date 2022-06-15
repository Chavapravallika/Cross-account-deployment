variable "network_acl_id" {
  type    = any
  default = ""
}
variable "ingress_rules" {
  type    = list(any)
  default = []
}
variable "egress_rules" {
  type    = list(any)
  default = []
}
variable "vpc_id" {
  type    = string
  default = ""
}
