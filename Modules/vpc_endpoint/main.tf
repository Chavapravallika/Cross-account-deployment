resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${var.aws_vpc_endpoint}"
  vpc_endpoint_type   = var.vpc_endpoint_type
  private_dns_enabled = var.private_dns_enabled
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  route_table_ids     = var.route_table_ids
  tags = merge(
    {
      "Environment" = var.environment
    },
    var.tags
  )
}
