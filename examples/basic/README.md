# Basic example

Creates one private-classified subnet in an existing VPC. The classification is metadata only; routing and connectivity are managed separately.

```bash
terraform init
terraform plan -var="vpc_id=vpc-xxxxxxxx"
```
