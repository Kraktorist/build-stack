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

# function init_backend() {
#     # init_backend "network"
#     if [ -z ${ENV} ]; then
#       echo "Environment variable 'ENV' is empty">/dev/stderr
#       exit 1
#     fi
#     terraform -chdir=/app/terraform init \
#         -backend-config="bucket=${S3_TF_STATE}" \
#         -backend-config="key=${ENV}/cloud.tfstate" \
#         -reconfigure
# }

function init_backend() {
    # init_backend "network"
    if [ -z ${ENV} ]; then
      echo "Environment variable 'ENV' is empty">/dev/stderr
      exit 1
    fi
    terraform -chdir=/app/terraform workspace select ${ENV} || terraform -chdir=/app/terraform workspace new ${ENV}
    terraform -chdir=/app/terraform init \
        -backend-config="bucket=${S3_TF_STATE}" \
        -reconfigure
}

function terraform_plan() {
    init_backend
    terraform -chdir=/app/terraform plan
}

function terraform_apply() {
    init_backend
    terraform -chdir=/app/terraform apply -auto-approve
}

function terraform_destroy() {
    init_backend
    terraform -chdir=/app/terraform destroy -auto-approve
}

function terraform_status() {
    init_backend
    terraform -chdir=/app/terraform show  
}

function provision_misc() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/misc/main.yml 
}

function provision_bastion() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --become /app/ansible/bastion/main.yml
  echo "[INFO] Bastion has been reconfigured. Set ANSIBLE_SSH_COMMON_ARGS to use it."
}

function provision_gitlab() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/gitlab/main.yml 
}

function provision_infra_repo() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/gitlab/main.yml \
    --tag infrastructure
}

function provision_apps_repo() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/gitlab/main.yml \
    --tag apps
}

function provision_infra_runner() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/gitlab/main.yml \
    --tag runner
}

function provision_nexus() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/nexus/main.yml
}

function provision_k8s() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/kubespray/cluster.yml
}

function provision_k8s_runner() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/k8s_runner/main.yml
}

function provision_monitoring() {
  ansible-playbook -i ${TF_VAR_ansible_inventory} \
    --vault-password-file .vault \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    --become /app/ansible/monitoring/main.yml
}

function deploy_boutique() {
  ansible-playbook \
    --extra-vars "DEPLOYMENT_NAMESPACE=${DEPLOYMENT_NAMESPACE}" \
    --extra-vars "DEPLOYMENT_NAME=${DEPLOYMENT_NAME}" \
    --extra-vars "NEXUS_GROUP_REGISTRY=${NEXUS_GROUP_REGISTRY}" \
    --extra-vars "NEXUS_GITLAB_USERNAME=${NEXUS_GITLAB_USERNAME}" \
    --extra-vars "NEXUS_GITLAB_PASSWORD=${NEXUS_GITLAB_PASSWORD}" \
    --extra-vars "ansible_ssh_common_args='${ANSIBLE_SSH_COMMON_ARGS}'" \
    /app/ansible/deploy/main.yml
}
