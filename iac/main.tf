terraform {
  required_version = "1.7.2"
    required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45.0"
    }
  }
  backend "s3" {
    bucket         = "hellohippo-golang-app-terraform-backend"  # Name of the S3 bucket where the state will be stored.
    key            = "terraform.tfstate" # Path within the bucket where the state will be read/written.
    region         = "us-east-1" # AWS region of the S3 bucket.
    dynamodb_table = "terraform-lock" # DynamoDB table used for state locking.
    encrypt        = true  # Ensures the state is encrypted at rest in S3.
  }
}

#provider "aws" {
#  profile                  = "hellohippo"
#}
