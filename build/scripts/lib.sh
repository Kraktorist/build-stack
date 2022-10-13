#!/usr/bin/env bash

function yc_init() {
  yc config profile create current
  yc config set service-account-key $YC_SERVICE_ACCOUNT_KEY_FILE
  yc config set folder-id $YC_FOLDER_ID
}

function yc_get_network() {
  yc_init
  yc vpc network list
  yc vpc subnet list
}

function yc_get_instances() {
  yc_init
  yc compute instance list
}

function init_backend() {
    # init_backend "network"
    if [ -z ${ENV} ]; then
      echo "Environment variable 'ENV' is empty">/dev/stderr
      exit 1
    fi
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
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/misc/main.yml 
}

function provision_bastion() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/bastion/main.yml
}

function provision_gitlab() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/gitlab/main.yml 
}

function provision_infra_repo() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/gitlab/main.yml \
    --tag infrastructure
}

function provision_apps_repo() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/gitlab/main.yml \
    --tag apps
}

function provision_infra_runner() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/gitlab/main.yml \
    --tag runner
}

function provision_nexus() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/nexus/main.yml
}

function provision_k8s() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/kubespray/cluster.yml
}

function provision_k8s_runner() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/k8s/main.yml
}

function provision_monitoring() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/monitoring/main.yml
}

function deploy_boutique() {
  ansible-playbook \
    --extra-vars "DEPLOYMENT_NAMESPACE=${DEPLOYMENT_NAMESPACE}" \
    --extra-vars "DEPLOYMENT_NAME=${DEPLOYMENT_NAME}" \
    --extra-vars "NEXUS_GROUP_REGISTRY=${NEXUS_GROUP_REGISTRY}" \
    --extra-vars "NEXUS_GITLAB_USERNAME=${NEXUS_GITLAB_USERNAME}" \
    --extra-vars "NEXUS_GITLAB_PASSWORD=${NEXUS_GITLAB_PASSWORD}" \
    /app/ansible/deploy/main.yml
}
