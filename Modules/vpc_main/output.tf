output "allSubnets" {
  value = local.allSubnets
}
output "vpc_id" {
  value = var.create_vpc ? aws_vpc.vpc.0.id : var.vpc_id
}
// output "private_network_acl_id" {
//   value = [for s in aws_network_acl.private.*.tags : s["Name"]=="ags-dev-eks-dev-cp-nacl"]
//   //contains(["cp"],s["Name"])]
// }
output "private_network_acl_id" {
  value = aws_network_acl.private
  # value = aws_network_acl.private.*.id
}
output "public_network_acl_id" {
  value = aws_network_acl.public
 // value = aws_network_acl.public.*.id
}
output "applicationSubnetIds" {
  value = local.applicationSubnets
}
output "publicSubnetIds" {
  value = local.publicSubnetids
}
output "databaseSubnetIds" {
  value = local.databaseSubnets
}
output "cacheSubnetIds" {
  value = local.cacheSubnets
}
output "CPSubnetIds" {
  value = local.CPSubnets
}
output "NGSubnetids" {
  value = local.NGSubnets
}

output "cp_nacl_id" {
  value = local.cp_nacl_id
}
output "ng_nacl_id" {
  value = local.ng_nacl_id
}
output "cache_nacl_id" {
  value = local.cache_nacl_id
}
output "app_nacl_id" {
  value = local.app_nacl_id
}
output "db_nacl_id" {
  value = local.db_nacl_id
}
output "public_nacl_id" {
  value = local.public_nacl_id
}

output "private_routetable_ids" {
  value = local.private_routetables_ids
}
