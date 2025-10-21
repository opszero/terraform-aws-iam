variable "management_account" {
  description = "Is this an AWS management account that has child accounts?"
  default     = false
}

variable "groups" {
  description = "Terraform object to create AWS IAM groups with custom IAM policies"
  default     = {}
  # name = {
  #   policy_arns = []
  #   enable_mfa = false
  # }
}

variable "users" {
  description = "Terraform object to create AWS IAM users"
  default     = {}
  #  "opszero" = {
  #    groups = ["developers"]
  #    ec2_instance_connect =  [
  #      "arn:${local.partition}:ec2:us-east-1:585584209241:instance/i-07e97d97102ddb52a",
  #      "arn:${local.partition}:ec2:us-east-1:585584209241:instance/i-0e3c1a0a62c51854a",
  #    ]
  #  },
  #   "test" = {
  #    groups = ["developers"]
  #    ec2_instance_connect =  [
  #      "arn:${local.partition}:ec2:us-east-1:585584209241:instance/i-07e97d97102ddb52b",
  #      "arn:${local.partition}:ec2:us-east-1:585584209241:instance/i-0e3c1a0a62c51854b",
  #    ]
  #  }

}

variable "github" {
  description = "Terraform object to create IAM OIDC identity provider in AWS to integrate with github actions"
  default     = {}
  # "deployer" = {
  #   org = "opszero"
  #   repos = ["mrmgr"]
  #   policy_arns = []
  # }
}

variable "gitlab" {
  description = "Terraform object to create IAM OIDC identity provider in AWS to integrate with gitlab CI"
  default     = {}
  #  "deployer" = {
  #    iam_role_name = "gitlab_oidc_role"
  #    gitlab_url    = "https://gitlab.com"
  #    audience      = "https://gitlab.com"
  #    match_field   = "sub"
  #    match_value   = [
  #      "project_path:opszero/mrmgr:ref_type:branch:ref:main"
  #    ]
  #    policy_arns   = []
  #  }
  # }
}

variable "bitbucket" {
  description = "Terraform object to create IAM OIDC identity provider in AWS to integrate with Bitbucket"
  default     = {}
  #  "deployer" = {
  #    workspace_name = "opszero"
  #    workspace_uuid = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx""
  #
  #    # This is matched against the sub claim, which provided in the following format:
  #    # {REPOSITORY_UUID}[:{ENVIRONMENT_UUID}]:{STEP_UUID}
  #    # More info here: https://support.atlassian.com/bitbucket-cloud/docs/deploy-on-aws-using-bitbucket-pipelines-openid-connect/#Using-claims-in-ID-tokens-to-limit-access-to-the-IAM-role-in-AWS
  #    subjects = [
  #      "{REPOSITORY_UUID}[:{ENVIRONMENT_UUID}]:{STEP_UUID}"
  #    ]
  #    policy_json   = []
  #  }
  # }
}

variable "opszero_enabled" {
  description = "Deploy opsZero omyac cloudformation stack"
  default     = false
}



variable "vanta_enabled" {
  default = false
}

variable "vanta_account_id" {
  description = "Vanta account id"
  default     = ""
}

variable "vanta_external_id" {
  description = "Vanta external id"
  default     = ""
}


variable "enable_mfa" {
  description = "Whether to enable MFA for IAM users"
  type        = bool
  default     = true
}


variable "enable_user_group_membership" {
  description = "Set to true to use aws_iam_user_group_membership for import support"
  type        = bool
  default     = false
}
