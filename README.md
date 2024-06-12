# hello-hippo-iac-cicd

## Assignement
Pick and research two ways to serve websites on AWS
- provision all necessary infra using Terraform.
- pick any supported backend for Terraform state.
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

### About multiple accounts
