#!/usr/bin/env bash

set -euo pipefail

module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validation_dir="$(mktemp -d)"
validation_module_dir="$validation_dir/module"
provider_version="${SUBNET_PROVIDER_VERSION:-latest}"

cleanup() {
  if [[ -n "$validation_dir" && -d "$validation_dir" ]]; then
    rm -rf -- "$validation_dir"
  fi
}
trap cleanup EXIT

terraform -chdir="$module_dir" fmt -check -recursive

mkdir -p "$validation_module_dir"
tar \
  --exclude=".terraform" \
  --exclude=".terraform.lock.hcl" \
  --exclude="*.tfplan" \
  --exclude="*.tfstate" \
  --exclude="*.tfstate.*" \
  -cf - \
  -C "$module_dir" . |
  tar -xf - -C "$validation_module_dir"

if [[ "$provider_version" != "latest" ]]; then
  PROVIDER_VERSION="$provider_version" perl -0pi -e \
    's#version\s*=\s*">= 0\.0\.60"#version = "=$ENV{PROVIDER_VERSION}"#g' \
    "$validation_module_dir/versions.tf"
fi

echo "Validating Provider version: $provider_version"
terraform -chdir="$validation_module_dir" init -backend=false -input=false >/dev/null
terraform -chdir="$validation_module_dir" validate

provider_env=(
  "VOLCENGINE_ACCESS_KEY=static-validation"
  "VOLCENGINE_SECRET_KEY=static-validation"
  "VOLCENGINE_REGION=cn-beijing"
)

valid_subnets='subnets={private-a={cidr_block="10.40.1.0/24",zone_id="cn-beijing-a",subnet_type="private",route_table_key="private"}}'

env "${provider_env[@]}" terraform -chdir="$validation_module_dir" plan \
  -refresh=false \
  -input=false \
  -lock=false \
  -var="vpc_id=vpc-static-validation" \
  -var="$valid_subnets" \
  >/dev/null

expect_plan_failure() {
  local description="$1"
  shift

  if env "${provider_env[@]}" terraform -chdir="$validation_module_dir" plan \
    -refresh=false \
    -input=false \
    -lock=false \
    "$@" \
    >/dev/null 2>&1; then
    echo "$description unexpectedly passed validation." >&2
    exit 1
  fi
}

expect_plan_failure \
  "An empty VPC ID" \
  -var="vpc_id=" \
  -var="$valid_subnets"

expect_plan_failure \
  "An empty subnet map" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={}'

expect_plan_failure \
  "An invalid subnet CIDR" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={private-a={cidr_block="not-a-cidr",zone_id="cn-beijing-a"}}'

expect_plan_failure \
  "A non-canonical subnet CIDR" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={private-a={cidr_block="10.40.1.1/24",zone_id="cn-beijing-a"}}'

expect_plan_failure \
  "A public IPv4 CIDR" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={private-a={cidr_block="8.8.8.0/24",zone_id="cn-beijing-a"}}'

expect_plan_failure \
  "An empty availability zone" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={private-a={cidr_block="10.40.1.0/24",zone_id=""}}'

expect_plan_failure \
  "An unsupported subnet type" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={private-a={cidr_block="10.40.1.0/24",zone_id="cn-beijing-a",subnet_type="dmz"}}'

expect_plan_failure \
  "An empty route table key" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={private-a={cidr_block="10.40.1.0/24",zone_id="cn-beijing-a",route_table_key=""}}'

expect_plan_failure \
  "An invalid generated subnet name" \
  -var="vpc_id=vpc-static-validation" \
  -var='subnets={"http://invalid"={cidr_block="10.40.1.0/24",zone_id="cn-beijing-a"}}'

expect_plan_failure \
  "An empty common tag key" \
  -var="vpc_id=vpc-static-validation" \
  -var="$valid_subnets" \
  -var='common_tags={""="invalid"}'

examples=(
  "basic"
  "complete"
)

for example in "${examples[@]}"; do
  echo "Validating example: $example"
  target_dir="$validation_dir/$example"
  cp -R "$module_dir/examples/$example" "$target_dir"

  MODULE_DIR="$validation_module_dir" perl -0pi -e \
    's#source\s*=\s*"volcengine/vpc-subnet/volcenginecc"#source = "$ENV{MODULE_DIR}"#g; s#^\s*version\s*=\s*"~> 1\.0"\s*\n##m' \
    "$target_dir/main.tf"

  if ! grep -Fq "source = \"$validation_module_dir\"" "$target_dir/main.tf"; then
    echo "Failed to rewrite the module source for $example" >&2
    exit 1
  fi

  terraform -chdir="$target_dir" init -backend=false -input=false >/dev/null
  terraform -chdir="$target_dir" validate
  env "${provider_env[@]}" terraform -chdir="$target_dir" plan \
    -refresh=false \
    -input=false \
    -lock=false \
    -var="vpc_id=vpc-static-validation" \
    >/dev/null
done

if grep -R -n -E '(access_key|secret_key)[[:space:]]*=' \
  "$module_dir" \
  --include='*.tf' \
  --exclude-dir='.terraform'; then
  echo "Static credentials must not be committed." >&2
  exit 1
fi

echo "Static validation passed for the root module and all examples."
