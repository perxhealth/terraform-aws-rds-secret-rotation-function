output "default_rotation_lambda_handler" {
  value = local.default_lambda_handler
}

output "rotation_lambda_role_name" {
  value = module.rotation_lambda.lambda_role_name
}

output "rotation_lambda_role_arn" {
  value = module.rotation_lambda.lambda_role_arn
}

output "rotation_lambda_runtime" {
  value = local.lambda_runtime
}

output "rotation_lambda_security_group_id" {
  value = module.lambda_security_group.security_group_id
}
