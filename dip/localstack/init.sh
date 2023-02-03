#!/usr/bin/env bash

LOCALSTACK_HOST=localhost
LOCALSTACK_S3_PORT=4566

configure_aws_cli() {
  echo "configuring aws-cli"
  aws_dir="/root/.aws"
  if [[ -d "$aws_dir" ]]; then
    echo "'${aws_dir}' already exists => skipping aws configuration with dummy credentials"
  else
    mkdir "${aws_dir}"
    cat <<AWSDUMMYCREDENTIALS >"${aws_dir}/credentials"
    [default]
    AWS_ACCESS_KEY_ID = dummy
    AWS_SECRET_ACCESS_KEY = dummy
AWSDUMMYCREDENTIALS
    cat <<AWSCONFIG >"${aws_dir}/config"
    [default]
    region = eu-west-3
AWSCONFIG
  fi
}

create_bucket() {
  local bucket_name=$1
  if ! aws --endpoint-url=http://${LOCALSTACK_HOST}:${LOCALSTACK_S3_PORT} s3 ls "s3://${bucket_name}"; then
    echo "Creating bucket ${bucket_name}"
    aws --endpoint-url=http://${LOCALSTACK_HOST}:${LOCALSTACK_S3_PORT} s3 mb "s3://${bucket_name}"
  else
    echo "Bucket ${bucket_name} already exists => skipping"
  fi
}

configure_aws_cli
create_bucket some-bucket
