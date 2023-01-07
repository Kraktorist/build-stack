#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function red {
    printf "${RED}$@${NC}\n"
}

function green {
    printf "${GREEN}$@${NC}\n"
}

function yellow {
    printf "${YELLOW}$@${NC}\n"
}

for i in "$@"; do
  case $i in
    -f=*|--folder=*)
      FOLDER="${i#*=}"
      shift
      ;;
    -n=*|--network=*)
      NETWORK="${i#*=}"
      shift
      ;;
    -s=*|--service-account=*)
      SERVICE_ACCOUNT="${i#*=}"
      shift
      ;;
    -r=*|--role=*)
      ROLE="${i#*=}"
      shift
      ;;
    -b=*|--bucket=*)
      S3_TF_STATE="${i#*=}"
      shift
      ;;
    -*|--*)
      echo $(yellow "Unknown option $i")
      exit 1
      ;;
    *)
      ;;
  esac
done

if [ -z ${FOLDER} ]; then
  FOLDER=boutique
  echo $(yellow "WARNING! Parameter --folder is not set. Default value --folder=${FOLDER} will be used.")
fi
if [ -z ${NETWORK} ]; then
  NETWORK=instances
  echo $(yellow "WARNING! Parameter --network is not set. Default value --network=${NETWORK} will be used.")
fi
if [ -z ${SERVICE_ACCOUNT} ]; then
  SERVICE_ACCOUNT=${FOLDER}-admin
  echo $(yellow "WARNING! Parameter --service-account is not set. Default value --service-account=${SERVICE_ACCOUNT} will be used.")
fi
if [ -z ${ROLE} ]; then
  ROLE=admin
  echo $(yellow "WARNING! Parameter --role is not set. Default value --role=${ROLE} will be used.")
fi

if [ -z ${S3_TF_STATE} ]; then
  S3_TF_STATE=${FOLDER}-tfstates
  echo $(yellow "WARNING! Parameter --bucket is not set. Default value --bucket=${S3_TF_STATE} will be used.")
fi

echo $(green "Press enter to continue")
read

echo $(yellow "Starting initialization:")
set -euo pipefail

KEY_FILE=.key.json

YC_FOLDER_ID=$(yc resource-manager folder create ${FOLDER} --format json | jq -r .id)
echo $(yellow "Creating Service Account ${SERVICE_ACCOUNT}")
yc iam service-account create ${SERVICE_ACCOUNT} --folder-name ${FOLDER}

echo $(yellow "Assigning requested role ${ROLE}")
yc resource-manager folder add-access-binding ${FOLDER} \
  --service-account-name ${SERVICE_ACCOUNT} \
  --role ${ROLE} \
  --folder-name ${FOLDER}

echo $(yellow "Creating IAM key for the service account")
yc iam key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --output ${KEY_FILE}
API_KEY=$(jq -r tostring ${KEY_FILE} | base64 -w 0)
rm -rf ${KEY_FILE}

echo $(yellow "Creating IAM access-key for access to S3")
secret=$(yc iam access-key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --format json)

echo $(yellow "Creating S3 bucket ${S3_TF_STATE}")
export AWS_ACCESS_KEY_ID=$(echo ${secret} | jq -r .access_key.key_id)
export AWS_SECRET_ACCESS_KEY=$(echo ${secret} | jq -r .secret)
export AWS_REGION=ru-central1
aws --endpoint-url=https://storage.yandexcloud.net s3 mb s3://${S3_TF_STATE}

echo $(yellow "Creating network ${NETWORK}")
yc vpc network create ${NETWORK} \
  --folder-name ${FOLDER} 

echo $(yellow "Creating Internet Gateway")
gateway_id=$(yc vpc gateway create default \
  --folder-name ${FOLDER} \
  --format json | jq -r .id)

echo $(yellow "Creating Routing Table")
yc vpc route-table create routing \
  --route destination=0.0.0.0/0,gateway-id=${gateway_id} \
  --network-name ${NETWORK} \
  --folder-name ${FOLDER}

echo $(yellow "EXPORTED VALUES:")
echo "YC_CLOUD_ID=$(yc config get cloud-id)"
echo "YC_FOLDER_ID=${YC_FOLDER_ID}"
echo "ACCESS_KEY=${AWS_ACCESS_KEY_ID}"
echo "SECRET_KEY=${AWS_SECRET_ACCESS_KEY}"
echo "API_KEY=${API_KEY}"
echo "S3_TF_STATE=${S3_TF_STATE}"