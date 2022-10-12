#!/usr/bin/env bash
set -euo pipefail

FOLDER=test4
NETWORK=instances
SERVICE_ACCOUNT=${FOLDER}-editor
ROLE=editor
S3_TF_STATE=${FOLDER}-tfstates

KEY_FILE=.key.json

YC_FOLDER_ID=$(yc resource-manager folder create ${FOLDER} --format json | jq -r .id)
yc iam service-account create ${SERVICE_ACCOUNT} --folder-name ${FOLDER}
yc resource-manager folder add-access-binding ${FOLDER} \
  --service-account-name ${SERVICE_ACCOUNT} \
  --role ${ROLE} \
  --folder-name ${FOLDER}
yc iam key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --output ${KEY_FILE}
API_KEY=$(jq -r tostring ${KEY_FILE} | base64 -w 0)
rm -rf ${KEY_FILE}

secret=$(yc iam access-key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --format json)

AWS_ACCESS_KEY_ID=$(echo ${secret} | jq -r .access_key.key_id)
AWS_SECRET_ACCESS_KEY=$(echo ${secret} | jq -r .secret)
export AWS_REGION=ru-central1
aws --endpoint-url=https://storage.yandexcloud.net s3 mb s3://${S3_TF_STATE}

yc vpc network create ${NETWORK} \
  --folder-name ${FOLDER} 
gateway_id=$(yc vpc gateway create default \
  --folder-name ${FOLDER} \
  --format json | jq -r .id)
yc vpc route-table create routing \
  --route destination=0.0.0.0/0,gateway-id=${gateway_id} \
  --network-name ${NETWORK} \
  --folder-name ${FOLDER}

echo "export YC_CLOUD_ID=$(yc config get cloud-id)"
echo "export YC_FOLDER_ID=${YC_FOLDER_ID}"
echo "export ACCESS_KEY=${AWS_ACCESS_KEY_ID}"
echo "export SECRET_KEY=${AWS_SECRET_ACCESS_KEY}"
echo "export API_KEY=${API_KEY}"
echo "export S3_TF_STATE=${S3_TF_STATE}"