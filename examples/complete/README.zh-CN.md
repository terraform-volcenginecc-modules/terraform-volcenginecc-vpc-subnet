# 完整示例

跨两个可用区创建 public、private、database 与 intra 分类。它会分配逻辑 `route_table_key` 取值，以便将 `subnet_ids_by_route_table_key` 传递给由独立负责方管理的路由表模块。

这些分类与路由表键仅用于组织下游组合。本示例刻意不创建路由表、路由条目、NAT 网关或互联网网关，因此仅凭 `public` 分类并不提供互联网连通性。

```bash
terraform init
terraform plan -var="vpc_id=vpc-xxxxxxxx"
```
