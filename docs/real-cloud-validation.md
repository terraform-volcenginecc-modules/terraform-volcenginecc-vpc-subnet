# 真实云验证报告

## 当前结论

2026-08-18 已使用真实账号执行 PRD 的 basic 和 complete 场景。资源创建、属性回读、路由表关联、销毁以及销毁后的云端残留检查均已完成。

严格的 complete 场景“apply 后立即二次 Plan 必须 No changes”未通过。原因是根模块的 `subnets` 输出在刷新时，将只读路由表诊断从系统路由表更新为新关联的自定义路由表。该变化不涉及任何云资源操作，但 Terraform 仍返回 exit code `2`。

生命周期更新、替换等其他验收仍待执行，因此本报告不能作为模块已达到发布门禁的证明。

## Provider 基线

- 最低支持版本：`volcengine/volcenginecc >= 0.0.60`。
- 本次真实云验证使用 Provider `0.0.65`。
- 之前已检查 Provider `0.0.60` 至 `0.0.62` 的 Subnet Schema。
- `cidr_block`、`vpc_id`、`zone_id` 为仅创建时设置的字段。
- Subnet 资源中的 `route_table` 为只读字段。
- `enable_ipv_6` 和 `ipv_6_cidr_block` 为只写字段，目前有意未暴露。

## 发布验收证据

- [x] basic 创建成功。
- [x] basic 立即二次 Plan 返回 `No changes`。
- [x] complete 在两个可用区创建 public/private/database 六个子网。
- [x] complete 的 CIDR、AZ、VPC、名称、标签、类型分组和 `subnet_ids` 回读值与输入一致。
- [x] 通过 Provider 回读的路由表 `subnet_ids` 证明三组关联均成功。
- [ ] complete 立即二次 Plan 返回 `No changes`。
- [ ] 名称和描述原地更新。
- [ ] 非空标签更新后达到 `No changes`。
- [ ] 新增一个 map key 只创建一个子网。
- [ ] 删除一个 map key 只删除对应子网。
- [ ] CIDR 和 AZ 变化产生经过审阅的替换 Plan。
- [ ] 系统路由表 ID/类型回读后不产生永久差异。
- [x] basic 和 complete 销毁所有 fixture 资源并留下空 State。
- [x] 通过 ID 查询确认两个 fixture VPC、七个子网和三个自定义路由表均不存在。

## 延后验收

- 清除已管理标签，以及将标签改为未声明状态。
- IPv6 创建、更新、回读和幂等性。
- 在不产生双重 owner 的前提下，将一个临时子网移动到另一组逻辑路由表。

## 2026-08-18 PRD 基线运行

### Basic

- 运行 ID：`20260818101712`。
- 创建一个 VPC 和一个位于 `cn-beijing-a` 的 private 子网。
- 子网 CIDR 为 `10.90.1.0/24`，生成名称、标签、状态和 VPC 归属均与 fixture 一致。
- 立即二次 Plan 返回 exit code `0`，结果为 `No changes`。
- Destroy 删除两个资源；State 为空，按 ID 查询云端返回 `Data Source Not Found`。

### Complete

- 成功运行 ID：`20260818102212`。
- 创建一个 VPC、六个子网和三个自定义路由表。
- public/private/database 各包含两个子网，分布在 `cn-beijing-a` 和 `cn-beijing-b`；六个 `/24` CIDR 两两不重叠。
- CIDR、AZ、名称、标签、类型、状态和 VPC 归属断言全部通过。
- Provider 回读的 `route_tables[*].subnet_ids` 与 public/private/database 分组完全一致。
- 首次及重复执行的未 apply 二次 Plan 均返回 exit code `2`，仅包含输出变化：`subnets[*].route_table_id` 和 `route_table_type` 从创建时的系统路由表刷新为自定义路由表。没有提出云资源操作，但不满足严格的 `No changes` 门禁。
- Destroy 按依赖顺序删除全部十个资源；State 为空，逐个 ID 查询均返回 `Data Source Not Found`。

早期 complete 尝试并发创建三个路由表时遇到 `InvalidOperation.Conflict`。保留的 fixture 已将三个路由表改为串行创建，以匹配云控制面的操作限制。早期部分成功的资源已在重跑前完整销毁。
