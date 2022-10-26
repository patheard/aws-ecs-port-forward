locals {
  cidr_block = "10.0.0.0/16"
}

module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.5//vpc"
  name   = var.product_name

  high_availability  = true
  enable_flow_log    = false
  block_ssh          = true
  block_rdp          = true
  single_nat_gateway = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

locals {
  endpoints_interface = toset(["ecr.dkr", "ecr.api", "logs", "ssm", "ssmmessages", "ec2messages"])
  endpoints_gateway   = toset(["s3"])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.endpoints_interface

  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]
  subnet_ids = module.vpc.private_subnet_ids
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.endpoints_gateway

  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.${each.value}"
  route_table_ids   = [module.vpc.main_route_table_id]
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc_endpoints"
  description = "PrivateLink VPC endpoints"
  vpc_id      = module.vpc.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO INTERNAL SERVICE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "internal" {
  name        = "internal"
  description = "Allow inbound traffic to internal service"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "internal-egress-endpoints" {
  description              = "Internal egress to VPC PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.internal.id
}

resource "aws_security_group_rule" "vpc-endpoints-ingress-internal" {
  description              = "VPC PrivateLink endpoints ingress from internal"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal.id
  security_group_id        = aws_security_group.vpc_endpoints.id
}

resource "aws_security_group_rule" "internal-egress-endpoints-gateway" {
  for_each = aws_vpc_endpoint.gateway

  description       = "Security group rule for internal task egress to S3 gateway"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.internal.id
  prefix_list_ids = [
    each.value.prefix_list_id
  ]
}

resource "aws_flow_log" "internal" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.internal_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "internal_flow_log" {
  name              = "internal_flow_log"
  retention_in_days = 14
}
