locals {
  association-list = flatten([
    for subnet in var.subnets : [
      for index, cidr in subnet.cidr : {
        cidr             = cidr
        subnetType       = subnet["subnetType"]
        isprivate        = subnet["isprivate"]
        indexValue       = index
        tags             = subnet["tags"]
        subnetnameprefix = subnet["subnetname_prefix"]
      }
    ]
  ])
}
data "aws_availability_zones" "azs" {}

# VPC Creation
resource "aws_vpc" "vpc" {
  count                            = var.create_vpc ? 1 : 0
  cidr_block                       = var.cidr
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block = var.enable_ipv6
  tags = merge(
    {
      "Environment" : var.environment
    },
    var.vpc_tags
  )
}
# Subnets creation
resource "aws_subnet" "subnets" {
  count                   = length(local.association-list) > 0 ? length(local.association-list) : 0
  availability_zone       = data.aws_availability_zones.azs.names[lookup(element(local.association-list, count.index), "indexValue") % length(data.aws_availability_zones.azs.names)]
  vpc_id                  = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id
  cidr_block              = lookup(element(local.association-list, count.index), "cidr")
  map_public_ip_on_launch = !lookup(element(local.association-list, count.index), "isprivate")
  tags = merge(
    {
      "Name" = "${lookup(element(local.association-list, count.index), "subnetnameprefix")}-${element(data.aws_availability_zones.azs.names, lookup(element(local.association-list, count.index), "indexValue"))}",
      "Environment" : var.environment
    },
    lookup(element(local.association-list, count.index), "tags")
  )
}
# segregate Subnets
locals {
  publicSubnets = [
    for s in local.association-list : s
    if s.isprivate == false
  ]
  privateSubnets = [
    for s in local.association-list : s
    if s.isprivate == true
  ]
}
# Get Public and private Subnet details
locals {
  publicSubnetDetails = flatten([
    for subnet in aws_subnet.subnets : [
      for publicsubnet in local.publicSubnets : { "subnetid" = subnet["id"], "subnetType" = publicsubnet["subnetType"], "cidr" = publicsubnet["cidr"] }
      if publicsubnet.cidr == subnet.cidr_block
    ]
  ])
  privateSubnetDetails = flatten([
    for subnet in aws_subnet.subnets : [
      for privatesubnet in local.privateSubnets : { "subnetid" = subnet["id"], "subnetType" = privatesubnet["subnetType"], "cidr" = privatesubnet["cidr"] }
      if privatesubnet.cidr == subnet.cidr_block
    ]
  ])
  allSubnets = concat(local.publicSubnetDetails, local.privateSubnetDetails)
  privateSubnetGroups = [
    for subnet in var.subnets : subnet
    if subnet.isprivate == true
  ]
  publicSubnetGroups = [
    for subnet in var.subnets : subnet
    if subnet.isprivate == false
  ]
}
# Create Internet gateway
resource "aws_internet_gateway" "igw" {
  count  = var.createigw ? 1 : 0
  vpc_id = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id
  tags = merge(
    {
      "Name" = "${var.prefix_name}-${var.environment}-igw",
      "Environment" : var.environment
    },
    var.igw_tags
  )
}
# Create routing table for public subnets
resource "aws_route_table" "public" {
  vpc_id = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.createigw ? aws_internet_gateway.igw.0.id : var.igw_id
  }
  tags = merge(
    {
      "Name" = "${var.prefix_name}-${var.environment}-public-rt",
      "Environment" : var.environment
    },
    var.rt_tags
  )
}
# Associate public routing table to public subnets
resource "aws_route_table_association" "public" {
  count          = length(local.publicSubnetDetails)
  subnet_id      = lookup(element(local.publicSubnetDetails, count.index), "subnetid")
  route_table_id = aws_route_table.public.id
}
# Create elastid Ips
resource "aws_eip" "nat_eip" {
  count      = length(local.privateSubnetGroups)
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = merge(
    {
      "Name" = "${var.prefix_name}-${var.environment}-eip-${count.index + 1}",
      "Environment" : var.environment
    },
    var.eip_tags
  )
}
# Create Natgateways
resource "aws_nat_gateway" "nat" {
  count         = length(local.privateSubnetGroups)
  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = lookup(element(local.publicSubnetDetails, count.index), "subnetid")
  depends_on    = [aws_internet_gateway.igw]
  tags = merge(
    {
      "Name" = "${var.prefix_name}-${var.environment}-nat-${count.index + 1}",
      "Environment" : var.environment
    },
    var.nat_tags
  )
}
# Create routing table for private subnets based on NAT gateway count
resource "aws_route_table" "private" {
  count  = length(aws_nat_gateway.nat.*)
  vpc_id = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }
  tags = merge(
    {
      "Name" = "${var.prefix_name}-${var.environment}-private-rt-${count.index + 1}",
      "Environment" : var.environment
    },
    var.rt_tags
  )
}
locals {
  subnetcidr_route_associations = [
    for index, rt in aws_route_table.private.*.id : {
      subnetcidr    = local.privateSubnetGroups[index]["cidr"]
      routetable_id = rt
    }
  ]
  subnet_route_association = flatten([
    for subnetcidr_route_association in local.subnetcidr_route_associations : [
      for subnetcidr in subnetcidr_route_association["subnetcidr"] : {
        subnetcidr    = subnetcidr
        routetable_id = subnetcidr_route_association["routetable_id"]
      }
    ]
  ])
  subnetid_route_association = flatten([
    for subnet in aws_subnet.subnets : [
      for privatesubnet in local.subnet_route_association : { "subnetid" = subnet.id, "rountetable_id" = privatesubnet.routetable_id }
      if privatesubnet.subnetcidr == subnet.cidr_block
    ]
  ])
}
# Associate private routing table to private subnets 
resource "aws_route_table_association" "private" {
  count          = length(local.subnetid_route_association)
  subnet_id      = lookup(element(local.subnetid_route_association, count.index), "subnetid")
  route_table_id = lookup(element(local.subnetid_route_association, count.index), "rountetable_id")
}
locals {
  privatesubnetTypes     = [for privateSubnetDetail in local.privateSubnetDetails : privateSubnetDetail.subnetType]
  distprivateSubnetTypes = distinct(local.privatesubnetTypes)
  publicsubnetTypes      = [for publicSubnetDetail in local.publicSubnetDetails : publicSubnetDetail.subnetType]
  distpublicSubnetTypes  = distinct(local.publicsubnetTypes)

  applicationSubnets = [
    for privateSubnet in local.privateSubnetDetails : { "subnetid" = privateSubnet.subnetid, "cidr" = privateSubnet.cidr }
    if privateSubnet.subnetType == "application"
  ]
  databaseSubnets = [
    for privateSubnet in local.privateSubnetDetails : { "subnetid" = privateSubnet.subnetid, "cidr" = privateSubnet.cidr }
    if privateSubnet.subnetType == "database"
  ]
  CPSubnets = [
    for privateSubnet in local.privateSubnetDetails : { "subnetid" = privateSubnet.subnetid, "cidr" = privateSubnet.cidr }
    if privateSubnet.subnetType == "eks-dev-cp"
  ]
  NGSubnets = [
    for privateSubnet in local.privateSubnetDetails : { "subnetid" = privateSubnet.subnetid, "cidr" = privateSubnet.cidr }
    if privateSubnet.subnetType == "eks-dev-ng"
  ]
  cacheSubnets = [
    for privateSubnet in local.privateSubnetDetails : { "subnetid" = privateSubnet.subnetid, "cidr" = privateSubnet.cidr }
    if privateSubnet.subnetType == "cache"
  ]
  publicSubnetids = [
    for publicSubnet in local.publicSubnetDetails : { "subnetid" = publicSubnet.subnetid, "cidr" = publicSubnet.cidr }
    if publicSubnet.subnetType == "public"
  ]
}
resource "aws_network_acl" "private" {
  count  = var.createnetwork_acl ? length(local.distprivateSubnetTypes) : 0
  vpc_id = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id
  subnet_ids = [for privateSubnetDetail in local.privateSubnetDetails : privateSubnetDetail.subnetid
    if privateSubnetDetail.subnetType == element(local.distprivateSubnetTypes, count.index)
  ]
  tags = merge({
    "Environment" = var.environment
    "Name"        = "${var.prefix_name}-${var.environment}-${element(local.distprivateSubnetTypes, count.index)}-nacl"
    },
    var.nacl_tags
  )
}
resource "aws_network_acl" "public" {
  count  = var.createnetwork_acl ? length(local.distpublicSubnetTypes) : 0
  vpc_id = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id
  subnet_ids = [for publicSubnetDetail in local.publicSubnetDetails : publicSubnetDetail.subnetid
    if publicSubnetDetail.subnetType == element(local.distpublicSubnetTypes, count.index)
  ]
  tags = merge({
    "Environment" = var.environment
    "Name"        = "${var.prefix_name}-${var.environment}-${element(local.distpublicSubnetTypes, count.index)}-nacl"
    },
    var.nacl_tags
  )
}

locals {
  public_nacl_id = [
    for publicNACL in aws_network_acl.public : publicNACL.id 
    if length(regexall("public", publicNACL.tags.Name)) > 0
  ]

  db_nacl_id = [
    for privateNACL in aws_network_acl.private :  privateNACL.id
    if length(regexall("database", privateNACL.tags.Name)) > 0
  ]

  app_nacl_id = [
    for privateNACL in aws_network_acl.private : privateNACL.id
    if length(regexall("application", privateNACL.tags.Name)) > 0
  ]

  cp_nacl_id = [
    for privateNACL in aws_network_acl.private : privateNACL.id 
    if length(regexall("cp", privateNACL.tags.Name)) > 0
  ]

  ng_nacl_id = [
    for privateNACL in aws_network_acl.private : privateNACL.id 
    if length(regexall("ng", privateNACL.tags.Name)) > 0
  ]

  cache_nacl_id = [
    for privateNACL in aws_network_acl.private : privateNACL.id 
    if length(regexall("cache", privateNACL.tags.Name)) > 0
  ]

  //routetables

  private_routetables_ids = [
    for private_routetable in aws_route_table.private : private_routetable.id
  ]
}
