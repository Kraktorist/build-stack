FOLDER=boutique
SERVICE_ACCOUNT=boutique-editor
ROLE=editor
S3_TF_STATE=devops-netology-tfstates
YC_FOLDER_ID=$(yc resource-manager folder create ${FOLDER} --format json | jq -r .id)
yc iam service-account create ${SERVICE_ACCOUNT} --folder-name ${FOLDER}
yc resource-manager folder add-access-binding ${FOLDER} \
  --service-account-name ${SERVICE_ACCOUNT} \
  --role ${ROLE} \
  --folder-name ${FOLDER}
secret=$(yc iam access-key create \
  --service-account-name ${SERVICE_ACCOUNT} \
  --folder-name ${FOLDER} \
  --format json)

AWS_ACCESS_KEY_ID=$(echo ${secret} | jq -r .access_key.key_id)
AWS_SECRET_ACCESS_KEY=$(echo ${secret} | jq -r .secret)
export AWS_REGION=ru-central1
aws --endpoint-url=https://storage.yandexcloud.net s3 mb s3://${S3_TF_STATE}