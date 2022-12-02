Based on https://github.com/JCapriotti/terraform-aws-rds-secret-rotation

# AWS RDS Secret Rotation Function

A Terraform module that creates a lambda function used for RDS rotation support.

## Features

* Supports PostgreSQL but is easy to add other engines.
* All required infrastructure is created for credential rotation (lambda, security group, etc)

Secret rotation is not only a great thing to do from a security perspective, but it negates the worry about the 
`aws_rds_cluster` resource storing passwords in state.

## Usage

### PostgreSQL Aurora Serverless

```terraform
module "root_user" {
  source = "git::https://bitbucket.org:perxhealth/terraform-aws-rds-secret-rotation-function"

  secrets                    = [{ arn: "arn:us-east-2:secret:21321321", id: "12321312", days: 7 }]
  rotation_lambda_subnet_ids = ["subnet-0123456789", "subnet-abcdef0123"]
  rotation_lambda_vpc_id     = "vpc-0123456789"
  db_security_group_id       = aws_security_group.rds.id
}
```

## Inputs

| Name                                                                                                                     | Description                                                                                                                                                                                  | Type           | Default | Required |
|--------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|---------|:--------:|
| <a name="input_secrets"></a> [secrets](#input_secrets)                                                                   | The secrets that you wish to rotate with this function.                                                                                                                                      | `list(object({arn: string, id: string, days: number}))`  | `null`  |   yes    |
| <a name="input_rotation_lambda_env_variables"></a> [rotation_lambda_env_variables](#input_rotation_lambda_env_variables) | Optional environment variables for the rotation lambda; useful for integration with for certain layer providers.                                                                             | `map(string)`  | `{}`    |    no    |
| <a name="input_rotation_lambda_handler"></a> [rotation_lambda_handler](#input_rotation_lambda_handler)                   | An optional lambda handler name; useful integration with for certain layer providers.                                                                                                        | `string`       | `null`  |    no    |
| <a name="input_rotation_lambda_layers"></a> [rotation_lambda_layers](#input_rotation_lambda_layers)                      | Optional layers for the rotation lambda.                                                                                                                                                     | `list(string)` | `null`  |    no    |
| <a name="input_rotation_lambda_policy_jsons"></a> [rotation_lambda_policy_jsons](#input_rotation_lambda_policy_jsons)    | Additional policies to add to the rotation lambda; useful for integration with layer providers.                                                                                              | `list(string)` | `[]`    |    no    |
| <a name="input_rotation_lambda_subnet_ids"></a> [rotation_lambda_subnet_ids](#input_rotation_lambda_subnet_ids)          | The VPC subnets that the rotation lambda runs in. Required for secret rotation.                                                                                                              | `list(string)` | `[]`    |    no    |
| <a name="input_rotation_lambda_vpc_id"></a> [rotation_lambda_vpc_id](#input_rotation_lambda_vpc_id)                      | The VPC that the secret rotation lambda runs in. Required for secret rotation.                                                                                                               | `string`       | null    |    no    |
| <a name="input_rotation_strategy"></a> [rotation_strategy](#input_rotation_strategy)                                     | Specifies how the secret is rotated, either by updating credentials for the user itself (`single`) or by using a superuser's credentials to change another user's credentials (`multiuser`). | `string`       | `single` |    no    |
| <a name="input_secret_recovery_window_days"></a> [secret_recovery_window_days](#input_secret_recovery_window_days)       | The number of days that Secrets Manager waits before deleting a secret.                                                                                                                      | `number`       | `0`     |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                            | Tags to use for created resources.                                                                                                                                                           | `map(string)`  | `{}`    |    no    |
| <a name="input_recreate_missing_package"></a> [recreate_missing_package](#input_recreate_missing_package)                | Whether to recreate missing Lambda package if it is missing locally or not.                                                                                                                  | `bool`         | true    |    no    |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_rotation_lambda_handler"></a> [default_rotation_lambda_handler](#output_default_rotation_lambda_handler) | The default lambda handler for the built-in function. Useful for when integrating with a layer. |
| <a name="output_rotation_lambda_role_name"></a> [rotation_lambda_role_name](#output_rotation_lambda_role_name) | The name of the IAM role created for the rotation lambda. |
| <a name="output_rotation_lambda_runtime"></a> [rotation_lambda_runtime](#output_rotation_lambda_runtime) | The runtime of the rotation lambda. |
| <a name="output_rotation_lambda_security_group_id"></a> [rotation_lambda_security_group_id](#output_rotation_lambda_security_group_id) | The security group created for the rotation lambda. |
