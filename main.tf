locals {
  function_name          = var.rotation_strategy == "single" ? "postgresql-single-user" : "postgresql-multiuser"
  default_lambda_handler = "lambda_function.lambda_handler"
  lambda_runtime         = "python3.7"
  name                   = "${var.name}-rotate-secret"

  default_lambda_env_vars = {
    SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
  }
}

data "aws_region" "current" {}

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = var.secrets

  rotation_lambda_arn = module.rotation_lambda.lambda_function_arn
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

module "rotation_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = local.name
  handler       = coalesce(var.rotation_lambda_handler, local.default_lambda_handler)
  runtime       = local.lambda_runtime
  timeout       = 120
  tags          = var.tags
  publish       = true
  memory_size   = 128
  layers        = var.rotation_lambda_layers

  vpc_security_group_ids = [module.lambda_security_group.security_group_id]
  vpc_subnet_ids         = var.rotation_lambda_subnet_ids
  attach_network_policy  = true

  environment_variables = merge(var.rotation_lambda_env_variables, local.default_lambda_env_vars)

  allowed_triggers = {
    SecretsManager = {
      service    = "secretsmanager"
      source_account = var.aws_account_id
    }
  }

  recreate_missing_package  = var.recreate_missing_package
  role_permissions_boundary = var.role_permissions_boundary

  attach_policy_jsons    = true
  policy_jsons           = local.lambda_policies
  number_of_policy_jsons = length(local.lambda_policies)

  source_path = [
    {
      path             = "${path.module}/functions/${local.function_name}"
      pip_requirements = true
    }
  ]
}

locals {
  lambda_policies = flatten([
    data.aws_iam_policy_document.superuser[*].json,
    data.aws_iam_policy_document.secret.json,
    var.rotation_lambda_policy_jsons,
  ])
}

data "aws_iam_policy_document" "secret" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [for s in var.secrets : s.arn]
  }
  statement {
    actions = [
      "secretsmanager:GetRandomPassword",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "superuser" {
  count = var.rotation_strategy == "single" ? 0 : 1
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      var.master_secret_arn,
    ]
  }
}
