PROJECT_ID="5"
TF_STAGE="${TF_STAGE}"
TF_USERNAME="${GITLAB_USER_NAME}"
TF_PASSWORD="${CI_JOB_TOKEN}"
TF_ADDRESS="https://gitlab.orema.com.tr/api/v4/projects/${PROJECT_ID}/terraform/state/${TF_STAGE}"

terraform init -upgrade \
  -backend-config=address=${TF_ADDRESS} \
  -backend-config=lock_address=${TF_ADDRESS}/lock \
  -backend-config=unlock_address=${TF_ADDRESS}/lock \
  -backend-config=username=${TF_USERNAME} \
  -backend-config=password=${TF_PASSWORD} \
  -backend-config=lock_method=POST \
  -backend-config=unlock_method=DELETE \
  -backend-config=retry_wait_min=5

