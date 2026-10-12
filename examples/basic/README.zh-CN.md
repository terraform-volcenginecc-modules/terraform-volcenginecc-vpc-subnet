# 基础示例

在已有 VPC 中创建一个 private 分类的子网。该分类仅为元数据；路由与连通性另行管理。

```bash
terraform init
terraform plan -var="vpc_id=vpc-xxxxxxxx"
```
