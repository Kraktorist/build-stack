#!/usr/bin/env bash

function init_backend() {
    # init_backend "network"
    step=$1
    terraform init \
        -backend-config="endpoint=storage.yandexcloud.net" \
        -backend-config="bucket=dn-terraform-states" \
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