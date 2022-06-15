variable "create_vpc" {
  description = "Controls if VPC should be created"
  type        = bool
  default     = true
}
variable "environment" {
  description = "Environment value dev/test/stage/prod"
  type        = string
  default     = "dev"
}
variable "prefix_name" {
  type = string
}
variable "vpc_id" {
  type        = string
  description = "If you dont created VPC, pass existing vpcid"
  default     = ""
}
variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "0.0.0.0/0"
}
variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block."
  type        = bool
  default     = false
}
variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC"
  type        = bool
  default     = true
}
variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC"
  type        = bool
  default     = false
}
variable "vpc_tags" {
  description = "VPC tags"
  type        = map(any)
  default     = {}
}
variable "subnets" {
  description = "subnet details"
  type        = list(any)
}
variable "subnet_tags" {
  description = "Subnet tags"
  type        = map(any)
  default     = {}
}
variable "singleNATGateway" {
  description = "if true, will create single NAT gatway for all subnets, else create individual NAT gatways"
  type        = bool
  default     = true
}
variable "natrequired" {
  type    = bool
  default = true
}
variable "createigw" {
  type    = bool
  default = true
}
variable "igw_id" {
  type    = string
  default = ""
}
variable "igw_tags" {
  type    = map(any)
  default = {}
}
variable "rt_tags" {
  type    = map(any)
  default = {}
}
variable "eip_tags" {
  type    = map(any)
  default = {}
}
variable "nat_tags" {
  type    = map(any)
  default = {}
}
variable "nacl_tags" {
  type    = map(any)
  default = {}
}
variable "createnetwork_acl" {
  type    = bool
  default = true
}
variable "network_acl_id" {
  type    = string
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
