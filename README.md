# MrMgr (AWS IAM)

Configures AWS IAM users, groups, OIDC.

## Usage

This belongs within the [infrastructure as code](https://github.com/opszero/template-infra).

```
# iam/main.tf

provider "aws" {
  profile = "opszero"
  region  = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "opszero-opszero-terraform-tfstate"
    region  = "us-east-1"
    profile = "opszero"
    encrypt = "true"

    key     = "iam"
  }
}

resource "aws_iam_policy" "deployer" {
  name        = "github-deployer-policy"
  description = "Github Deployer"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

module "opszero-eks" {
  source = "github.com/opszero/terraform-aws-mrmgr"

  github = {
    "deployer" = {
      org = "opszero"
      repos = [
        "terraform-aws-mrmgr"
      ]
      policy_arns = [
        aws_iam_policy.deployer.arn
      ]
    }
  }

  groups = {
    "Backend" = {
      policy_arns = [
        aws_iam_policy.deployer.arn,
        "arn:${local.partition}:iam::aws:policy/IAMSelfManageServiceSpecificCredentials",
        "arn:${local.partition}:iam::aws:policy/IAMUserChangePassword",
      ]
      enable_mfa = false
      enable_self_management = true # Optional
    }
  }

  users = {
    "opszero" = {
      "groups" = [
        "Backend"
      ]
    },
  }
}
```

```
# environments/<nameofenv>/main.tf

module "opszero-eks" {
  source = "github.com/opszero/terraform-aws-kubespot"

  ...

  sso_roles = {
    admin_roles = [
      "arn:${local.partition}:iam::1234567789101:role/github-deployer"
    ]
    readonly_roles = []
    dev_roles = []
    monitoring_roles = []
  }

  ...
}


```

## Users

Users will be created _without_ a login profile. This means the user will exist
but will not have a password to login with. Login profiles and credentials will
be managed via console manually (to prevent automated disruption of everyone).

When removing a user, first disable console access.

Users without MFA will have no privilege within the system. In order to have
access to AWS users will need to attach a MFA device to their account.

- Log in via console
- Select "My Security Credentials"
- Choose "Assign MFA device"
- Use a virtual MFA device
- Enter two consecutive MFA codes from your 2FA app
- Sign out
- Sign in with MFA

### List Existing Users

```bash
aws --profile <profile> iam list-attached-user-policies --user-name <username>| jq '.AttachedPolicies[].PolicyArn'
```

## Groups

# OIDC

OIDC Deployer allows us to access resources within another piece of
infrastructure through the use of OpenID. Check below for examples oh how dto do
deployments.

### Github

Example configuration for deploying to an EKS cluster without the need for AWS
Access Keys.

```terraform
resource "aws_iam_policy" "deployer" {
  name        = "github-deployer-policy"
  description = "Github Deployer"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

module "iam" {
  source = "github.com/opszero/mrmgr//modules/aws"

  github = {
    "deployer" = {
      org = "opszero"
      repos = [
        "mrmgr"
      ]
      policy_arns = [
        aws_iam_policy.deployer.arn
      ]
    }
  }
}

```

kubespot

```terraform
module "opszero-eks" {
  source = "github.com/opszero/terraform-aws-kubespot"

  ...

  sso_roles = {
    admin_roles = [
      "arn:${local.partition}:iam::1234567789101:role/github-deployer"
    ]
    readonly_roles = []
    dev_roles = []
    monitoring_roles = []
  }

  ...
}

```

eksdeploy.yml

```yaml
---
on:
  push:
    branches:
      - develop
      - master

name: Deploy to Amazon EKS

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    permissions: # Important to add.
      contents: read
      id-token: write
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: arn:${local.partition}:iam::1234567789101:role/github-deployer
          aws-region: us-east-1
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: 1234567789101.dkr.ecr.us-east-1.amazonaws.com
          ECR_REPOSITORY: mrmgr
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
      - name: Release Develop
        if: ${{ github.ref == 'refs/heads/develop' }}
        env:
          ECR_REGISTRY: 1234567789101.dkr.ecr.us-east-1.amazonaws.com
          ECR_REPOSITORY: mrmgr
          IMAGE_TAG: ${{ github.sha }}
        run: |
          aws eks update-kubeconfig --name mrmgr-develop
          helm upgrade --install mrmgr charts/mrmgr \
            -f ./charts/develop.yaml \
            --set image.repository=$ECR_REGISTRY/$ECR_REPOSITORY \
            --set image.tag=$IMAGE_TAG \
```

### Gitlab

Example configuration for deploying to AWS without the need for AWS
Access Keys. To list EKS cluster via GitLab Pipelines without using AWS credentials. You can also attach other policies to this IAM role.

```bash
resource "aws_iam_policy" "deployer" {
  name        = "gitlab-deployer-policy"
  description = "GitLab Deployer"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

module "iam" {
  source = "github.com/opszero/mrmgr//modules/aws"

  gitlab = {
    "deployer" = {
      iam_role_name = "gitlab_oidc_role"
      audience      = "https://gitlab.com"
      gitlab_url    = "https://gitlab.com"
      match_field   = "sub"
      match_value = [
        "project_path:opszero/mrmgr:ref_type:branch:ref:main"
      ]
      policy_arns = [
        aws_iam_policy.deployer.arn
      ]
    }
  }
}
```

.gitlab_ci.yml

```
variables:
  REGION: us-east-1
  ROLE_ARN:  arn:${local.partition}:iam::${AWS_ACCOUNT_ID}:role/gitlab_role

image:
  name: amazon/aws-cli:latest
  entrypoint:
    - '/usr/bin/env'

assume role:
    script:
        - >
          STS=($(aws sts assume-role-with-web-identity
          --role-arn ${ROLE_ARN}
          --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
          --web-identity-token $CI_JOB_JWT_V2
          --duration-seconds 3600
          --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
          --output text))
        - export AWS_ACCESS_KEY_ID="${STS[0]}"
        - export AWS_SECRET_ACCESS_KEY="${STS[1]}"
        - export AWS_SESSION_TOKEN="${STS[2]}"
        - export AWS_REGION="$REGION"
        - aws sts get-caller-identity
        - aws eks list-clusters

```

#### GitLab CI Outputs

![gitlabci_output](https://raw.githubusercontent.com/thaunghtike-share/mytfdemo/main/aws_console_outputs_photos/opszero.png)

## BitBucket

```bash
module "mrmgr" {
  source = "github.com/opszero/terraform-aws-mrmgr"

  bitbucket = {
    "deployer" = {
      subjects = [
        "{REPOSITORY_UUID}[:{ENVIRONMENT_UUID}]:{STEP_UUID}"
      ]
      policy_json = [
        aws_iam_policy.deployer.json
      ]
    }
  }
```
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bitbucket"></a> [bitbucket](#input\_bitbucket) | Terraform object to create IAM OIDC identity provider in AWS to integrate with Bitbucket | `map` | `{}` | no |
| <a name="input_github"></a> [github](#input\_github) | Terraform object to create IAM OIDC identity provider in AWS to integrate with github actions | `map` | `{}` | no |
| <a name="input_gitlab"></a> [gitlab](#input\_gitlab) | Terraform object to create IAM OIDC identity provider in AWS to integrate with gitlab CI | `map` | `{}` | no |
| <a name="input_groups"></a> [groups](#input\_groups) | Terraform object to create AWS IAM groups with custom IAM policies | `map` | `{}` | no |
| <a name="input_management_account"></a> [management\_account](#input\_management\_account) | Is this an AWS management account that has child accounts? | `bool` | `false` | no |
| <a name="input_opszero_enabled"></a> [opszero\_enabled](#input\_opszero\_enabled) | Deploy opsZero omyac cloudformation stack | `bool` | `false` | no |
| <a name="input_users"></a> [users](#input\_users) | Terraform object to create AWS IAM users | `map` | `{}` | no |
| <a name="input_vanta_account_id"></a> [vanta\_account\_id](#input\_vanta\_account\_id) | Vanta account id | `string` | `""` | no |
| <a name="input_vanta_enabled"></a> [vanta\_enabled](#input\_vanta\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_vanta_external_id"></a> [vanta\_external\_id](#input\_vanta\_external\_id) | Vanta external id | `string` | `""` | no |
## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.opszero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_iam_policy.mfa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vanta_child](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vanta_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.vanta_auditor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.vanta_child](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vanta_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vanta_security_audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.SecurityAudit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vanta_child](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vanta_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [tls_certificate.github](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |
## Outputs

No outputs.
# 🚀 Built by opsZero!

<a href="https://opszero.com"><img src="https://opszero.com/wp-content/uploads/2024/07/opsZero_logo_svg.svg" width="300px"/></a>

Since 2016 [opsZero](https://opszero.com) has been providing Kubernetes
expertise to companies of all sizes on any Cloud. With a focus on AI and
Compliance we can say we seen it all whether SOC2, HIPAA, PCI-DSS, ITAR,
FedRAMP, CMMC we have you and your customers covered.

We provide support to organizations in the following ways:

- [Modernize or Migrate to Kubernetes](https://opszero.com/solutions/modernization/)
- [Cloud Infrastructure with Kubernetes on AWS, Azure, Google Cloud, or Bare Metal](https://opszero.com/solutions/cloud-infrastructure/)
- [Building AI and Data Pipelines on Kubernetes](https://opszero.com/solutions/ai/)
- [Optimizing Existing Kubernetes Workloads](https://opszero.com/solutions/optimized-workloads/)

We do this with a high-touch support model where you:

- Get access to us on Slack, Microsoft Teams or Email
- Get 24/7 coverage of your infrastructure
- Get an accelerated migration to Kubernetes

Please [schedule a call](https://calendly.com/opszero-llc/discovery) if you need support.

<br/><br/>

<div style="display: block">
  <img src="https://opszero.com/wp-content/uploads/2024/07/aws-advanced.png" width="150px" />
  <img src="https://opszero.com/wp-content/uploads/2024/07/AWS-public-sector.png" width="150px" />
  <img src="https://opszero.com/wp-content/uploads/2024/07/AWS-eks.png" width="150px" />
</div>