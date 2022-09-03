#!/usr/bin/env bash
cd terraform
terraform init \
    -backend-config="endpoint=storage.yandexcloud.net" \
    -backend-config="bucket=dn-terraform-states" \
    -backend-config="region=ru-central1" \
    -backend-config="key=${ENV}/state.tfstate" \
    -backend-config="access_key=${ACCESS_KEY}" \
    -backend-config="secret_key=${SECRET_KEY}" \
    -backend-config="skip_region_validation=true" \
    -backend-config="skip_credentials_validation=true" 
export TF_VAR_config=/app/infra/envs/${ENV}/hosts.yml
terraform apply -auto-approve