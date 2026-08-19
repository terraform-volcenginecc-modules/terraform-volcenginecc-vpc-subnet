# Complete example

Creates public, private, database, and intra classifications across two availability zones. It assigns logical `route_table_key` values so `subnet_ids_by_route_table_key` can be passed to a separately owned Route Table Module.

The classifications and route-table keys organize downstream composition only. This example intentionally does not create route tables, route entries, NAT Gateways, or Internet Gateways, so a `public` classification alone does not provide internet connectivity.

```bash
terraform init
terraform plan -var="vpc_id=vpc-xxxxxxxx"
```
