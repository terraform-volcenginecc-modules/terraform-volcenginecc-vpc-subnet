# 真实云环境测试目录

本目录保留 `terraform-volcenginecc-vpc-subnet` 的可复跑真实云测试配置。版本控制只保留测试配置和辅助脚本；Terraform State、Plan、Lock 文件和 Provider 缓存均由 `.gitignore` 排除。

## 测试内容

- `basic/`：创建临时 VPC 和一个 private Subnet，验证 PRD 的 basic 单子网场景。
- `complete/`：创建临时 VPC，在两个可用区批量创建 public/private/database 各两个 Subnet，并通过三个独立 Route Table 验证实际关联。
- `lifecycle/`：创建临时 VPC，通过 Module 创建一个 Subnet，验证二次 Plan、更新名称/描述/标签、新增第二个 Subnet、再次 Plan 和最终销毁。
- `validate.sh`：在临时目录中执行格式、初始化、校验和 `refresh=false` 静态 Plan，不创建云资源。

## 静态检查

```bash
cd tests
./validate.sh
```

## 真实云生命周期

真实云测试会创建并销毁 VPC 和 Subnet。凭证由 Provider 默认凭证链读取，不应写入测试配置。

```bash
export SUBNET_TEST_RUN_ID="$(date +%Y%m%d%H%M%S)"

terraform -chdir=lifecycle init
terraform -chdir=lifecycle state list
```

开始新测试前，`state list` 必须没有任何输出。不要在非空 State 中只更换 `SUBNET_TEST_RUN_ID`。

创建一个 Subnet：

```bash
terraform -chdir=lifecycle apply \
  -var="run_id=${SUBNET_TEST_RUN_ID}" \
  -var="phase=create"

terraform -chdir=lifecycle plan \
  -detailed-exitcode \
  -var="run_id=${SUBNET_TEST_RUN_ID}" \
  -var="phase=create"
```

第二次 Plan 预期为 `No changes`。

更新已有 Subnet 并新增第二个 Subnet：

```bash
terraform -chdir=lifecycle apply \
  -var="run_id=${SUBNET_TEST_RUN_ID}" \
  -var="phase=update"

terraform -chdir=lifecycle plan \
  -detailed-exitcode \
  -var="run_id=${SUBNET_TEST_RUN_ID}" \
  -var="phase=update"
```

再次 Plan 预期为 `No changes`。测试完成后保持最后一次成功 Apply 的参数执行清理：

```bash
terraform -chdir=lifecycle plan -destroy \
  -var="run_id=${SUBNET_TEST_RUN_ID}" \
  -var="phase=update"

terraform -chdir=lifecycle destroy \
  -var="run_id=${SUBNET_TEST_RUN_ID}" \
  -var="phase=update"

terraform -chdir=lifecycle state list
```

执行 Destroy 前必须先审阅 `plan -destroy` 中列出的全部资源。销毁后 `state list` 应无输出。

## PRD basic / complete 验证

两套 fixture 均从 Provider 默认凭证链读取凭证。每次运行使用新的 `run_id`，并在开始前确认对应 State 为空。

```bash
export SUBNET_TEST_RUN_ID="$(date +%Y%m%d%H%M%S)"

terraform -chdir=basic init
terraform -chdir=basic plan -out=create.tfplan \
  -var="run_id=${SUBNET_TEST_RUN_ID}"
terraform -chdir=basic apply create.tfplan
terraform -chdir=basic plan -detailed-exitcode \
  -var="run_id=${SUBNET_TEST_RUN_ID}"
terraform -chdir=basic plan -destroy -out=destroy.tfplan \
  -var="run_id=${SUBNET_TEST_RUN_ID}"
terraform -chdir=basic apply destroy.tfplan
```

`complete/` 使用同样的命令。Apply 后还必须核对：

- 六个 Subnet 的 CIDR 两两不重叠，CIDR、AZ、名称和标签与输入一致；
- public/private/database 每组恰好两个 Subnet，且分布在两个 AZ；
- `route_tables[*].subnet_ids` 的 Provider 回读值与 `subnet_ids_by_route_table_key` 一致；
- 每个 Subnet 和三个 Route Table 的 `vpc_id` 均为 fixture VPC；
- Destroy 顺序为 Route Table、Subnet、VPC，最终 State 为空，并按 ID 反查云端资源不存在。

不要使用 `subnet_route_table_ids` 作为实际关联证据，它是根据输入合成的期望映射；实际关联必须检查 `route_tables[*].subnet_ids`。

## 待验证专项

- `cidr_block`、`zone_id` 和 `vpc_id` 修改是否只替换目标 Subnet。
- 删除一个 map key 是否只删除对应 Subnet。
- 非空 Tags 更新、清空和改为未声明后的回读及幂等性。
- IPv6 write-only 输入的创建、更新、回读与二次 Plan。
- 新建 Subnet 自动关联系统 Route Table 的只读输出。
