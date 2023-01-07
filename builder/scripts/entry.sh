#!/usr/bin/env bash

export YC_SERVICE_ACCOUNT_KEY_FILE=/app/key.json
echo $API_KEY | base64 -d>${YC_SERVICE_ACCOUNT_KEY_FILE}
echo $ANSIBLE_VAULT_PASSWORD>.vault
eval `ssh-agent -s`
ssh-add ~/ya_key
export ENV_PATH=/app/infrastructure/envs/${ENV}
export TF_VAR_config=/app/infrastructure/envs/${ENV}/config.yml
export TF_VAR_ansible_inventory=/app/infrastructure/envs/${ENV}/inventory.yml
export TF_VAR_ENV=${ENV}
export YC_STORAGE_ACCESS_KEY=${ACCESS_KEY}
export YC_STORAGE_SECRET_KEY=${SECRET_KEY}

source /app/scripts/lib.sh