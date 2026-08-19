# terraform-volcenginecc-vpc-subnet

Terraform module for creating multiple Volcengine subnets in an existing VPC with stable logical keys and explicit business classifications.

## Overview

This module manages subnets only. It does not create a VPC, route table, route entry, Internet Gateway, NAT Gateway, network ACL, security group, or route-table association.

Each subnet is keyed by a stable logical name and may be classified as `public`, `private`, `database`, or `intra`. The classification is module metadata used for naming and grouped outputs. An optional `route_table_key` groups created subnet IDs for direct composition with `terraform-volcenginecc-vpc-route-table`, while keeping route-table associations under one Terraform owner. Neither value changes cloud-side routing or connectivity by itself:

- A `public` classification does not make a subnet internet-facing.
- A `private`, `database`, or `intra` classification does not enforce isolation.
- The Subnet Resource exposes its associated route table as read-only information. System route-table behavior must be confirmed during this Module's real-cloud acceptance. The Route Table Module manages custom route tables, routes, and subnet associations by consuming `subnet_ids_by_route_table_key`.

Changing a subnet map key changes its Terraform resource address and normally destroys and recreates that subnet. Keep keys stable and change `name` when only the display name should change.

## Usage

```hcl
module "subnets" {
  source  = "volcengine/vpc-subnet/volcenginecc"
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

Provider authentication and region configuration belong in the caller:

```hcl
provider "volcenginecc" {
  region = "cn-beijing"
}
```

Use environment variables, a profile, or another supported credential source. Do not put access keys in Module configuration.

## Composition with the VPC Module

```hcl
module "vpc" {
  source  = "volcengine/vpc/volcenginecc"
  version = "~> 1.0"

  name       = "application"
  cidr_block = "10.10.0.0/16"
}

module "subnets" {
  source  = "volcengine/vpc-subnet/volcenginecc"
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

## Composition with the Route Table Module

`route_table_key` is a logical composition key, not a cloud Route Table ID. The following pattern makes the Route Table Module the sole owner of subnet associations:

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

Add route entries to the corresponding route-table items when the required next-hop resources exist. A public group requires an attached and enabled Internet Gateway plus a default route; a private egress group requires a NAT Gateway plus a default route.

## Examples

- [basic](examples/basic): creates one private-classified subnet in an existing VPC.
- [complete](examples/complete): creates public, private, database, and intra classifications across multiple availability zones.

## Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.5.0` |
| `volcengine/volcenginecc` | `>= 0.0.60` |

The Provider Subnet schema is unchanged from `0.0.60` through `0.0.62`. Real-cloud lifecycle acceptance for this Module is not yet complete; see [real-cloud validation](docs/real-cloud-validation.md).

## Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## Resources

| Type | Name |
|---|---|
| Resource | `volcenginecc_vpc_subnet.this` |

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---:|---:|---|
| `vpc_id` | `string` | — | Yes | Existing VPC ID. Changing it replaces every subnet. |
| `subnets` | `map(object(...))` | — | Yes | Subnets keyed by stable logical names. Supports classification and optional route-table grouping; must contain at least one item. |
| `name_prefix` | `string` | `null` | No | Prefix for generated names; the map key is used as the suffix. |
| `common_tags` | `map(string)` | `{}` | No | Tags applied to every subnet; per-subnet values override matching keys. |

Each `subnets` value supports:

| Attribute | Type | Default | Description |
|---|---|---:|---|
| `cidr_block` | `string` | — | Canonical private IPv4 CIDR. Changing it replaces the subnet. |
| `zone_id` | `string` | — | Availability zone ID such as `cn-beijing-a`. Changing it replaces the subnet. |
| `subnet_type` | `string` | `private` | One of `public`, `private`, `database`, or `intra`; metadata only. |
| `route_table_key` | `string` | `null` | Optional logical key used to group subnet IDs for the Route Table Module; this is not a Route Table ID. |
| `name` | `string` | generated | Explicit subnet name. |
| `description` | `string` | `null` | Subnet description. |
| `tags` | `map(string)` | `{}` | Per-subnet tags that override `common_tags`. |

## Outputs

| Name | Description |
|---|---|
| `subnet_ids` | Map of stable logical keys to Subnet IDs. |
| `subnet_ids_by_type` | IDs grouped into public/private/database/intra classifications. |
| `subnet_ids_by_route_table_key` | IDs grouped by non-null `route_table_key` values for downstream association. |
| `subnet_route_table_keys` | Subnet logical keys mapped to desired route-table logical keys. |
| `public_subnet_ids` | IDs classified as public. |
| `private_subnet_ids` | IDs classified as private. |
| `database_subnet_ids` | IDs classified as database. |
| `intra_subnet_ids` | IDs classified as intra. |
| `subnets` | Stable details for downstream modules, including read-only route-table information. |

## Notes

- The VPC must already exist. Pass `module.vpc.vpc_id` when composing with `terraform-volcenginecc-vpc`.
- `route_table_key` and `subnet_type` express composition intent only. Actual association is owned by `terraform-volcenginecc-vpc-route-table`; do not manage the same association from another State.
- A `public` subnet requires a working public-gateway route, while private outbound access requires a working NAT route. This Module deliberately does not claim those semantics from classification alone.
- Subnet CIDRs must belong to a VPC primary or secondary CIDR and must not overlap. The cloud API enforces containment, overlap, and service quota constraints.
- `cidr_block`, `vpc_id`, and `zone_id` are create-only Provider properties and changes replace affected subnets.
- `subnet_name`, `description`, and tags are updateable Provider properties.
- The Module always supplies both `key` and `value` for every Provider tag object to avoid incomplete nested-object differences.
- Empty effective tag maps are passed as `null`. Clearing previously managed tags still requires real-cloud acceptance before publication.
- IPv6 inputs are intentionally not exposed in the initial implementation because the Provider fields are write-only. They require a dedicated real-cloud create/update/readback/idempotency test first.
- Import an existing subnet into a stable key with `terraform import 'module.subnets.volcenginecc_vpc_subnet.this["private-a"]' subnet-xxxxxxxx`.
- Apply must be followed by another `terraform plan`; publication is acceptable only when the second plan reports no changes.
