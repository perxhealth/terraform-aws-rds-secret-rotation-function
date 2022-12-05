locals {
  application_id         = var.rotation_strategy == "single" ? "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser" : "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationMultiUser"
  name                   = "${var.name}-rotate-secret"
}

data "aws_region" "current" {}
data "aws_partition" "current" {}


resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = var.secrets

  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.postgres-rotator.outputs.RotationLambdaARN
  secret_id           = each.value.id

  rotation_rules {
    automatically_after_days = each.value.days
  }
}

module "lambda_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name          = local.name
  description   = "Contains egress rules for secret rotation lambda"
  vpc_id        = var.rotation_lambda_vpc_id
  egress_rules  = ["https-443-tcp"]

  egress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.db_security_group_id
    },
  ]

  tags = merge(var.tags, {Name = local.name})
}

module "db_ingress" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  create_sg         = false
  security_group_id = var.db_security_group_id
  ingress_with_source_security_group_id = [
    {
      description              = "Secret rotation lambda"
      rule                     = "postgresql-tcp"
      source_security_group_id = module.lambda_security_group.security_group_id
    },
  ]
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "postgres-rotator" {
  name           = "${var.name}-postgres-rotator"
  application_id = local.application_id
  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_RESOURCE_POLICY",
  ]
  parameters = {
    functionName = local.name
    endpoint     = "https://secretsmanager.${data.aws_region.current.name}.${data.aws_partition.current.dns_suffix}"
    vpcSubnetIds = join(",", var.rotation_lambda_subnet_ids)
    vpcSecurityGroupIds = module.lambda_security_group.security_group_id
    superuserSecretArn = var.master_secret_arn
  }
}
