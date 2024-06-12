#! /bin/bash

export AWS_PROFILE=hellohippo

aws s3 mb s3://hellohippo-golang-app-terraform-backend

aws dynamodb create-table \
         --table-name terraform-lock \
         --attribute-definitions AttributeName=LockID,AttributeType=S \
         --key-schema AttributeName=LockID,KeyType=HASH \
         --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
