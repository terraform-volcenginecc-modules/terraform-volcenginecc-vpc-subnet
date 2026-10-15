# BASIC VPC SUBNET 示例

## 概述

VPC SUBNET 模块的可运行 basic 配置。它从输入变量设置 Provider，并调用已发布的 Registry 模块。

## 用法

```shell
terraform init
terraform plan
terraform apply
terraform plan
terraform destroy
```

## 依赖要求

| 名称 | 版本 |
|---|---|
| Terraform | `>= 1.5.7` |
| OpenTofu | `>= 1.11.8` |

## Providers

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 资源

| 名称 | 说明 |
|---|---|
| `terraform-volcenginecc-modules/vpc-subnet/volcenginecc` | 已发布的 VPC SUBNET 模块。 |

## 输入

| 名称 | 说明 |
|---|---|
| `region` | 模块定义的 region。 |
| `vpc_id` | 模块定义的 vpc_id。 |
| `zone_id` | 模块定义的 zone_id。 |

## 输出

| 名称 | 说明 |
|---|---|
| `subnet_ids` | 模块定义的 subnet_ids。 |

## 示例

本目录即为 basic 示例。

## 说明

- 请通过 Provider 支持的配置提供凭据，绝不应写入源文件。
- apply 后的最终 plan 必须报告无变更，才能接受该配置。
