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
The following are the ways that came to my mind:
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
- App runner
- Lightsail

I chose these two mainly because I want to use Docker and provide a simple service that serves static content and an API. Although I have never used App Runner or Lightsail, I will try to set them up.

ECS is a service I have used before using Terraform. Given that this is an opportunity for me to learn new AWS services, I decided not to go with ECS this time and I decided to focus on App Runner and LightSail. If I have issues with any of those two, I will implement a solution using ECS.

Lambda functions support running a Docker container on every request. However, it is incompatible with long-running processes like the one I created for this assignment. For similar reasons, SAM won't be used in this case either.

I decided not to use EKS because Kubernetes is a black box. I know and have managed it, but it may be too much for this simple scenario.

I decided not to use S3 given that I want to work around a simple Golang server application that can be containerized, and S3 will only allow me to use static sites with static resources.

I decided not to use Amplify because it is tied to Typescript applications and incompatible with containers.

Implementing Elastic Beanstalk using Terraform wasn't smooth. Documentation about how to use Elastic Beanstalk using Containers and Terraform had many complexities. Most resources recommended using the Elastic Beanstalk-specific CLI tool `eb`.

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
This is needed given that the provider's `profile` attribute is not working for now. See [ticket](https://github.com/hashicorp/terraform-provider-aws/issues/35693).
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
```bash
$ ./build-image.sh hellohippo 0.0.1 golang `git rev-parse HEAD`
```

You will see that the ECR repository was marked as immutable given that once a docker image is pushed and tagged we should not be able to update it.

### Deploying using App Runner
The file [apprunner.tf](iac/apprunner.tf) defines the minimum set of resources needed to deploy a container in AWS App Runner. It automatically assigns a url to it. There are further configurations that can be applied to it including:
- using a custom domain
- configuring tracing and observability
- setting up secrets pulled from Parameter store or Secrets Manager
- configuring autoscaling
- binding instance roles for the process to have access to AWS services

Currently the available url from App Runner is shown as an output after executing Terraform.

### Deploying using LightSail
The file [lightsail.tf](iac/lightsail.tf) defines the minumum set of resources needed to deploy a container in AWS Lightsail. It automatically assigns a url to it. There are further configurations that can be applied to it including:
- using a custom domain
- configuring the capacity (power and scale)

Currently the available url from LightSail is shown as an output after executing Terraform.

### Destroy the infrastructure
1. Initialize Terraform (or Tofu):
```bash
$ tofu destroy
```
2. Do not forget to delete both the S3 bucket and the DynamoDB database created to manage Terraform's state.

## Conclusion
I am very happy to have used this opportunity to learn about AWS LightSail and APP Runner.

To further learn about which AWS services can be used for this I recommend reading [Choosing an AWS container service](https://docs.aws.amazon.com/decision-guides/latest/containers-on-aws-how-to-choose/choosing-aws-container-service.html).

![image](https://docs.aws.amazon.com/images/decision-guides/latest/containers-on-aws-how-to-choose/images/container-options-on-aws.png)

I personally think that a solution with ECS with managed EC2 provides multiple benefits like:
- increased control on the resources
- best visibility

But I really liked using both LighSail and App Runner.

Lightsail offers basic support for containers.
App Runner offers a full range of configuration that completely facilitate the way containers are managed and provides security solutions, custom DNS, observability, tracing and more. I will personally try to use this service more in the future.
