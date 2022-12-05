output "rotation_lambda_arn" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.postgres-rotator.outputs.RotationLambdaARN
}

output "rotation_lambda_security_group_id" {
  value = module.lambda_security_group.security_group_id
}
