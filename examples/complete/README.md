# COMPLETE VPC SUBNET Example

## Overview

Runnable complete configuration for the VPC SUBNET module. It configures the provider from input variables and calls the published Registry module.

## Usage

```shell
terraform init
terraform plan
terraform apply
terraform plan
terraform destroy
```

## Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.5.7` |
| OpenTofu | `>= 1.11.8` |

## Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## Resources

| Name | Description |
|---|---|
| `terraform-volcenginecc-modules/vpc-subnet/volcenginecc` | Published VPC SUBNET module. |

## Inputs

| Name | Description |
|---|---|
| `region` | Module-defined region. |
| `vpc_id` | Module-defined vpc_id. |
| `zone_ids` | Module-defined zone_ids. |

## Outputs

| Name | Description |
|---|---|
| `subnet_ids` | Module-defined subnet_ids. |
| `subnet_ids_by_type` | Module-defined subnet_ids_by_type. |
| `subnet_ids_by_route_table_key` | Module-defined subnet_ids_by_route_table_key. |

## Examples

This directory is the complete example.

## Notes

- Supply credentials through supported provider configuration, never in source files.
- The final plan after apply must report no changes before the configuration is accepted.
