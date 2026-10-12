# terraform-volcenginecc-vpc-subnet

在已有 VPC 中创建多个子网的 Terraform 模块，采用稳定的逻辑键并显式指定业务分类。

## 概述

本模块仅管理子网。它不会创建 VPC、路由表、路由条目、互联网网关、NAT 网关、网络 ACL、安全组，也不会建立路由表关联。

每个子网以一个稳定的逻辑名称作为键，可归类为 `public`、`private`、`database` 或 `intra`。该分类是模块元数据，用于命名与分组输出。可选的 `route_table_key` 将创建出的子网 ID 分组，便于与 `terraform-volcenginecc-vpc-route-table` 直接组合，同时将路由表关联交由同一个 Terraform 负责方管理。这两个取值本身都不会改变云端的路由或连通性：

- `public` 分类不会让子网具备面向公网的能力。
- `private`、`database` 或 `intra` 分类不会强制执行隔离。
- 子网资源以只读信息形式暴露其关联的路由表。系统路由表的行为必须在本模块的真实云验收阶段确认。路由表模块通过消费 `subnet_ids_by_route_table_key` 来管理自定义路由表、路由以及子网关联。

修改子网映射的键会改变其 Terraform 资源地址，通常会销毁并重建该子网。请保持键稳定；仅当需要变更显示名称时，再修改 `name`。

## 用法

```hcl
module "subnets" {
  source  = "terraform-volcenginecc-modules/vpc-subnet/volcenginecc"
  version = "~> 1.0"

  vpc_id      = module.vpc.vpc_id
  name_prefix = "application"

  subnets = {
    public-a = {
      cidr_block      = "10.10.1.0/24"
      zone_id         = "cn-beijing-a"
      subnet_type     = "public"
      route_table_key = "public"
    }
    private-a = {
      cidr_block      = "10.10.11.0/24"
      zone_id         = "cn-beijing-a"
      subnet_type     = "private"
      route_table_key = "private"
    }
  }

  common_tags = {
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}
```

Provider 鉴权与地域配置应由调用方负责：

```hcl
provider "volcenginecc" {
  region = "cn-beijing"
}
```

请使用环境变量、凭据 profile（配置文件）或其他受支持的凭据来源。请勿在模块配置中放置访问密钥。

## 与 VPC 模块组合

```hcl
module "vpc" {
  source  = "terraform-volcenginecc-modules/vpc/volcenginecc"
  version = "~> 1.0"

  name       = "application"
  cidr_block = "10.10.0.0/16"
}

module "subnets" {
  source  = "terraform-volcenginecc-modules/vpc-subnet/volcenginecc"
  version = "~> 1.0"

  vpc_id = module.vpc.vpc_id

  subnets = {
    private-a = {
      cidr_block  = "10.10.11.0/24"
      zone_id     = "cn-beijing-a"
      subnet_type = "private"
    }
  }
}
```

## 与路由表模块组合

`route_table_key` 是逻辑组合键，而非云端的路由表 ID。以下模式使路由表模块成为子网关联的唯一负责方：

```hcl
module "route_tables" {
  source  = "volcengine/vpc-route-table/volcenginecc"
  version = "~> 1.0"

  vpc_id = module.vpc.vpc_id

  route_tables = {
    for route_table_key, subnet_ids in module.subnets.subnet_ids_by_route_table_key :
    route_table_key => {
      subnet_ids = subnet_ids
    }
  }
}
```

当所需的下一跳资源就绪后，再向对应的路由表条目添加路由。公网分组需要已绑定并启用的互联网网关以及一条默认路由；私网出向分组需要 NAT 网关以及一条默认路由。

## 示例

- basic：在已有 VPC 中创建一个 private 分类的子网。
- complete：跨多个可用区创建 public、private、database 与 intra 分类。

## 版本要求

| 名称 | 版本 |
|---|---|
| Terraform | `>= 1.5.0` |
| `volcengine/volcenginecc` | `>= 0.0.60` |

## Provider

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 资源

| 类型 | 名称 |
|---|---|
| Resource | `volcenginecc_vpc_subnet.this` |

## 输入

| 名称 | 类型 | 默认值 | 是否必填 | 描述 |
|---|---|---:|---:|---|
| `vpc_id` | `string` | — | 是 | 已有 VPC 的 ID。修改它会替换所有子网。 |
| `subnets` | `map(object(...))` | — | 是 | 以稳定逻辑名称为键的子网。支持分类与可选的路由表分组；至少包含一个条目。 |
| `name_prefix` | `string` | `null` | 否 | 生成名称的前缀；映射键作为后缀。 |
| `common_tags` | `map(string)` | `{}` | 否 | 应用到每个子网的标签；单个子网的同名标签会覆盖此处取值。 |

每个 `subnets` 取值支持以下属性：

| 属性 | 类型 | 默认值 | 描述 |
|---|---|---:|---|
| `cidr_block` | `string` | — | 标准私网 IPv4 CIDR。修改它会替换子网。 |
| `zone_id` | `string` | — | 可用区 ID，例如 `cn-beijing-a`。修改它会替换子网。 |
| `subnet_type` | `string` | `private` | 取值为 `public`、`private`、`database` 或 `intra` 之一；仅作元数据。 |
| `route_table_key` | `string` | `null` | 可选的逻辑键，用于为路由表模块分组子网 ID；这不是路由表 ID。 |
| `name` | `string` | 自动生成 | 显式指定的子网名称。 |
| `description` | `string` | `null` | 子网描述。 |
| `tags` | `map(string)` | `{}` | 单个子网的标签，会覆盖 `common_tags`。 |

## 输出

| 名称 | 描述 |
|---|---|
| `subnet_ids` | 由稳定逻辑键到子网 ID 的映射。 |
| `subnet_ids_by_type` | 按 public/private/database/intra 分类分组的 ID。 |
| `subnet_ids_by_route_table_key` | 按非空 `route_table_key` 分组的 ID，供下游关联使用。 |
| `subnet_route_table_keys` | 子网逻辑键到期望路由表逻辑键的映射。 |
| `public_subnet_ids` | 分类为 public 的 ID。 |
| `private_subnet_ids` | 分类为 private 的 ID。 |
| `database_subnet_ids` | 分类为 database 的 ID。 |
| `intra_subnet_ids` | 分类为 intra 的 ID。 |
| `subnets` | 供下游模块使用的稳定详情，包括只读的路由表信息。 |

## 注意事项

- VPC 必须已存在。与 `terraform-volcenginecc-vpc` 组合时传入 `module.vpc.vpc_id`。
- `route_table_key` 与 `subnet_type` 仅表达组合意图。实际关联由 `terraform-volcenginecc-vpc-route-table` 负责；请勿从其他 State 管理同一关联。
- `public` 子网需要一条可用的公网网关路由，而私网出向访问需要一条可用的 NAT 路由。本模块刻意不仅凭分类即宣称具备这些语义。
- 子网 CIDR 必须属于 VPC 的主 CIDR 或辅助 CIDR，且不得相互重叠。云端 API 会强制执行包含关系、重叠校验与服务配额约束。
- `cidr_block`、`vpc_id` 与 `zone_id` 是仅创建时生效的 Provider 属性，修改会替换受影响的子网。
- `subnet_name`、`description` 与标签是可更新的 Provider 属性。
- 模块始终为每个 Provider 标签对象同时提供 `key` 与 `value`，以避免嵌套对象出现不完整的差异。
- 最终生效为空的标签映射以 `null` 传递。清除此前受管标签在发布前仍需经过真实云验收。
- 初始实现刻意未暴露 IPv6 输入，因为对应 Provider 字段为只写。这些字段需要先完成专门的真实云创建/更新/回读/幂等性测试。
- 使用 `terraform import 'module.subnets.volcenginecc_vpc_subnet.this["private-a"]' subnet-xxxxxxxx` 将已有子网导入到稳定键。
- apply 之后必须再次执行 `terraform plan`；只有当第二次 plan 报告无变更时，才可发布。
