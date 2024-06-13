# hello-hippo-iac-cicd

## Assignement
Pick and research two ways to serve websites on AWS
- DNS name or IP address should stay the same after redeployment
- deploy the same code into two different AWS accounts (think dev and prod). You should also be able to specify different parameters between accounts, such as the domain name or amount of compute needed.

## Solution

### Identify which services are available to my user
Using the [check_permissions.sh](./util_scripts/check_permissions.sh) I got:
```json
{
    "AttachedPolicies": [
        {
            "PolicyName": "AdministratorAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
        },
        {
            "PolicyName": "IAMUserChangePassword",
            "PolicyArn": "arn:aws:iam::aws:policy/IAMUserChangePassword"
        }
    ]
}
```

### Picking ways to serve websites in AWS
The following are the ways that came up to my mind:
- ECS
- EC2 with Docker installed containing some simple scripts for managing the applications
- EKS (but given our meeting, I decided not to follow this path)
- Elastic beanstalk
- Mix of an S3 static set of files consuming a backend in the previously mentioned services
- AWS Lambda functions

Other alternatives I found after some investigation were:
- App Runner
- Lightsail
- Amplify
- SAM

All of these ways to deploy applications are fascinating. To select two of them, I focused on their needs. We want: `changes to HTML should cause redeployment`. I decided to create a simple application in Golang that contains both a front end and a back end. I want to reuse the same application in both selected solutions, and this meant that the best choices are:
- Elastic beanstalk
- ECS

I chose these two mainly because I want to use Docker and provide a simple service that serves static content and an API.
Implementing Elastic Beanstalk is expected to be a smooth process, offering a standardized approach to deployments and rollbacks. While I haven't deployed this using Terraform before, I'm confident it won't pose significant challenges.
ECS is a service I have used before using Terraform, and given that I have administrator access, I should not have any problems. I know Hello Hippo uses Fargate, but I will create my own EC2 machines for this exercise.

In both services, any update to the application code will generate a new version of the Docker image. This way, we will cover the requirement: `changes to HTML should cause redeployment.`.

I decided not to use EKS because Kubernetes is a black box. I know and have managed it, but it may be too much for this simple scenario.

I decided not to use S3 or Lambda Functions, given that I want to work around a simple Golang server application that can be containerized, and none of those two services are compatible with Docker.

I decided not to use App Runner, Lightsail, Amplify, or SAM because I have not used those. I have experience with around 50% of AWS services, but these are simply some I have not used yet. I know I could learn about them quickly, but I want to speed up the process, and the scope I already chose is OK.

### About Terraform
I stopped using Terraform some months ago and moved to [Opentofu](https://github.com/opentofu/opentofu) given:
- [Terraform licensing change](https://github.com/hashicorp/terraform/blob/main/LICENSE)
- [IBM and Hashicorp acquisition processes](https://www.hashicorp.com/blog/hashicorp-joins-ibm)
Given that I have not Terraform installed anymore I will be using OpenTofu v1.7.2. There should not be important differences given that I will be using the same providers, in this case Hashicorp's AWS provider.

### About Hashicorp's AWS Provider version
This [bug](https://github.com/hashicorp/terraform-provider-aws/issues/37138) made me work with version 5.45.0 of the AWS provider.

### About Terraform lock using Dynamodb
I used this [script](util-scripts/create-dynamodb-terraform-lock.sh) and got:
```bash
make_bucket: hellohippo-golang-app-terraform-backend
```
And:
```json
{
    "TableDescription": {
        "AttributeDefinitions": [
            {
                "AttributeName": "LockID",
                "AttributeType": "S"
            }
        ],
        "TableName": "terraform-lock",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "CREATING",
        "CreationDateTime": 1718223828.441,
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 1,
            "WriteCapacityUnits": 1
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:471112922998:table/terraform-lock",
        "TableId": "bf357113-9b06-4e44-a8f9-3470d22eea23",
        "DeletionProtectionEnabled": false
    }
}
```
Then I configured Terraform to use that information [here](iac/main.tf).
### About multiple accounts
I first listed the organizations I had access to.
```bash
$ aws organizations describe-organization
{
    "Organization": {
        "Id": "o-st6dyf2srb",
        "Arn": "arn:aws:organizations::471112825629:organization/o-st6dyf2srb",
        "FeatureSet": "ALL",
        "MasterAccountArn": "arn:aws:organizations::471112825629:account/o-st6dyf2srb/471112825629",
        "MasterAccountId": "471112825629",
        "MasterAccountEmail": "aws.development+test_org_2@fivexl.io",
        "AvailablePolicyTypes": [
            {
                "Type": "SERVICE_CONTROL_POLICY",
                "Status": "ENABLED"
            }
        ]
    }
}
```
This is the information for the management account.
I will use this account to create IAM users, groups and roles to give access to member accounts.

I wanted to describe the management account but failed:
```bash
$ aws --profile hellohippo organizations describe-account --account-id 471112825629

An error occurred (AccessDeniedException) when calling the DescribeAccount operation: You don't have permissions to access this resource.
```

So I wondered if I was able to create member accounts. I gave it a try using Terraform:
```bash
$ tofu apply plan
aws_organizations_account.dev_account: Creating...
╷
│ Error: creating AWS Organizations Account (dev_account): AccessDeniedException: You don't have permissions to access this resource.
│ 
│   with aws_organizations_account.dev_account,
│   on organizations.tf line 1, in resource "aws_organizations_account" "dev_account":
│    1: resource "aws_organizations_account" "dev_account" {
│ 
╵

```
This means I am limited in the number of accounts I can create, and I won't be able to fulfill the following requirements:
```text
- deploy the same code into two different AWS accounts (think dev and prod). You should also be able to specify different parameters between accounts, such as the domain name or amount of compute needed.
```

### Creating the infrastructure
0. Export the needed environment variables before running Terraform (or Tofu):
```bash
$ export AWS_ACCESS_KEY_ID=**************
$ export AWS_SECRET_ACCESS_KEY=**************
$ export AWS_REGION=us-east-1
```
1. Initialize Terraform (or Tofu):
```bash
$ tofu init
```
2. Make a plan using Terraform (or Tofu):
```bash
$ tofu plan -out plan
```
3. Apply the plan using Terraform (or Tofu):
```bash
$ tofu apply plan
```

### Creating the ECR repository and publishing the Docker image
1. After generating all the infrastructure, we will have access to an ECR repository called: `golang`.
2. Run the [build-image.sh](util_scripts/build-image.sh). This will use a locally installed Docker and configured AWS credentials to build and publish the Docker image we will work with.

### Deploying using Elastic Beanstalk

### Deploying using ECS

### Destroy the infrastructure
1. Initialize Terraform (or Tofu):
```bash
$ tofu destroy
```
2. Do not forget to delete both the S3 bucket and the DynamoDB database created to manage Terraform's state.
