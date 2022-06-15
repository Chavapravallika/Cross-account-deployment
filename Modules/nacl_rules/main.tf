resource "aws_network_acl_rule" "ingress" {
  count          = length(var.ingress_rules) > 0 ? length(var.ingress_rules) : 0
  from_port      = lookup(element(var.ingress_rules, count.index), "from_port")
  protocol       = lookup(element(var.ingress_rules, count.index), "protocol")
  cidr_block     = lookup(element(var.ingress_rules, count.index), "cidr_block")
  to_port        = lookup(element(var.ingress_rules, count.index), "to_port")
  network_acl_id = var.network_acl_id
  rule_number    = lookup(element(var.ingress_rules, count.index), "rule_no")
  egress         = lookup(element(var.ingress_rules, count.index), "egress")
  rule_action    = lookup(element(var.ingress_rules, count.index), "action")
}
resource "aws_network_acl_rule" "egress" {
  count          = length(var.egress_rules) > 0 ? length(var.egress_rules) : 0
  from_port      = lookup(element(var.egress_rules, count.index), "from_port")
  protocol       = lookup(element(var.egress_rules, count.index), "protocol")
  cidr_block     = lookup(element(var.egress_rules, count.index), "cidr_block")
  to_port        = lookup(element(var.egress_rules, count.index), "to_port")
  network_acl_id = var.network_acl_id
  rule_number    = lookup(element(var.egress_rules, count.index), "rule_no")
  egress         = lookup(element(var.egress_rules, count.index), "egress")
  rule_action    = lookup(element(var.egress_rules, count.index), "action")
}
