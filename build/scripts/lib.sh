#!/usr/bin/env bash

function yc_init() {
  yc config profile create current
  yc config set token $YC_TOKEN
  yc config set folder-id $YC_FOLDER_ID
}

function yc_get_network() {
  yc_init
  yc vpc network list --format yaml
}

function init_backend() {
    # init_backend "network"
    step=$1
    terraform -chdir=/app/terraform init \
        -backend-config="endpoint=storage.yandexcloud.net" \
        -backend-config="bucket=${S3_TF_STATE}" \
        -backend-config="region=ru-central1" \
        -backend-config="key=${ENV}/${step}.tfstate" \
        -backend-config="access_key=${ACCESS_KEY}" \
        -backend-config="secret_key=${SECRET_KEY}" \
        -backend-config="skip_region_validation=true" \
        -backend-config="skip_credentials_validation=true" \
        -reconfigure
}

function init_step() {
    # init_backend "network"
    step=$1
    cp /app/terraform/${step}.template /app/terraform/${step}.tf
}

function terraform_plan() {
    step=$1
    init_step $step
    init_backend $step
    terraform -chdir=/app/terraform plan
    rm -rf "${step}.tf"
}

function terraform_apply() {
    step=$1
    init_step $step
    init_backend $step
    terraform -chdir=/app/terraform apply -auto-approve
    rm -rf /app/terraform/${step}.tf
}

function terraform_destroy() {
    step=$1
    init_step $step
    init_backend $step
    terraform -chdir=/app/terraform destroy -auto-approve
    rm -rf "${step}.tf"
}

function terraform_status() {
    step=$1
    init_step $step
    init_backend $step
    terraform -chdir=/app/terraform show
    rm -rf "${step}.tf"    
}

function provision_misc() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become /app/ansible/misc/main.yml 
}

function provision_gitlab() {
  provision_misc
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become /app/ansible/gitlab/main.yml 
}

function provision_repos() {
  provision_misc
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become /app/ansible/gitlab/main.yml --tag infrastructure --tag apps
}

function provision_nexus() {
  provision_misc
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become /app/ansible/nexus/main.yml
}