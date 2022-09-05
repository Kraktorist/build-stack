#!/usr/bin/env bash

function init_backend() {
    # init_backend "network"
    step=$1
    terraform init \
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
    cp "${step}.template" "${step}.tf"
}

function terraform_plan() {
    step=$1
    init_step $step
    init_backend $step
    terraform plan
    rm -rf "${step}.tf"
}

function terraform_apply() {
    step=$1
    init_step $step
    init_backend $step
    terraform apply -auto-approve
    rm -rf "${step}.tf"
}

function terraform_destroy() {
    step=$1
    init_step $step
    init_backend $step
    terraform destroy -auto-approve
    rm -rf "${step}.tf"
}

function terraform_status() {
    step=$1
    init_step $step
    init_backend $step
    terraform show
    rm -rf "${step}.tf"    
}

function provision_gitlab() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become ./ansible/gitlab/main.yml 
}

function provision_repos() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become ./ansible/gitlab/main.yml --tag infrastructure --tag apps
}

function provision_nexus() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} --become ./ansible/nexus/main.yml
}