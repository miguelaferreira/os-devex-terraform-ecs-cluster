#!/usr/bin/env sh

set -e

if [ -f ".env" ]; then
  source .env
fi

set -v

CI_VARIABLES=ci-variables.tfvars
OVERRIDES_FILE=ci-overrides.tf
echo 'vpc_id = "string"' >> ${CI_VARIABLES}
echo 'vpc_private_subnet_ids = ["list"]' >> ${CI_VARIABLES}
echo 'ssh_key_name = "string"' >> ${CI_VARIABLES}
echo 'cloud_config_content = "string"' >> ${CI_VARIABLES}

echo 'provider "aws" {
  region     = "string"
  access_key = "string"
  secret_key = "string"
}
' >  ${OVERRIDES_FILE}

terraform init
terraform validate -var-file ${CI_VARIABLES} .

rm -f ci-*.tf*
