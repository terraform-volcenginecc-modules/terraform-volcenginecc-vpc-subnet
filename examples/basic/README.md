# BASIC VPC SUBNET Example

## Overview

Runnable basic configuration for the VPC SUBNET module. It configures the provider from input variables and calls the published Registry module.

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
| `zone_id` | Module-defined zone_id. |

## Outputs

| Name | Description |
|---|---|
| `subnet_ids` | Module-defined subnet_ids. |

## Examples

This directory is the basic example.

## Notes

- Supply credentials through supported provider configuration, never in source files.
- The final plan after apply must report no changes before the configuration is accepted.
