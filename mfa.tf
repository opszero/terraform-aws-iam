data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_policy" "mfa" {
  count = var.enable_mfa ? 1 : 0
  name        = "MFAPolicy"
  path        = "/"
  description = "Policy ensures users are utilizing MFA"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PermitSelfPasswordChange",
        "Effect" : "Allow",
        "Action" : [
          "iam:ChangePassword",
          "iam:GetLoginProfile"
        ],
        "Resource" : "arn:${local.partition}:iam::${local.aws_account_id}:user/$${aws:username}"
      },
      {
        "Sid" : "SelfServiceMFA",
        "Effect" : "Allow",
        "Action" : [
          "iam:*List*",
          "iam:CreateAccessKey",
          "iam:CreateVirtualMFADevice",
          "iam:DeactivateMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ResyncMFADevice"
        ],
        "Resource" : [
          "arn:${local.partition}:iam::${local.aws_account_id}:mfa/$${aws:username}",
          "arn:${local.partition}:iam::${local.aws_account_id}:user/$${aws:username}"
        ]
      },
      {
        "Sid" : "PermitGetListMFA",
        "Effect" : "Allow",
        "Action" : [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListMFADevices",
          "iam:ListRoles",
          "iam:ListUsers",
          "iam:ListVirtualMFADevices"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "PermitGetAccountPasswordPolicy",
        "Effect" : "Allow",
        "Action" : "iam:GetAccountPasswordPolicy",
        "Resource" : "*"
      },
      {
        "Effect" : "Deny",
        "NotAction" : [
          "iam:ChangePassword",
          "iam:CreateAccessKey",
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:GetLoginProfile",
          "iam:List*"
        ],
        "NotResource" : "arn:${local.partition}:iam::${local.aws_account_id}:user/$${aws:username}",
        "Condition" : {
          "Null" : {
            "aws:MultiFactorAuthAge" : "true"
          }
        }
      },
      {
        "Effect" : "Deny",
        "NotAction" : [
          "iam:ChangePassword",
          "iam:CreateAccessKey",
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:GetAccountPasswordPolicy",
          "iam:GetLoginProfile",
          "iam:List*"
        ],
        "NotResource" : "arn:${local.partition}:iam::${local.aws_account_id}:user/$${aws:username}",
        "Condition" : {
          "NumericGreaterThan" : {
            "aws:MultiFactorAuthAge" : "86400"
          }
        }
      },
      {
        "Effect" : "Deny",
        "NotAction" : [
          "iam:ChangePassword",
          "iam:CreateAccessKey",
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:GetAccountPasswordPolicy",
          "iam:GetLoginProfile",
          "iam:List*"
        ],
        "NotResource" : "arn:${local.partition}:iam::${local.aws_account_id}:user/$${aws:username}",
        "Condition" : {
          "NumericGreaterThan" : {
            "aws:MultiFactorAuthAge" : "86400"
          }
        }
      },
      {
        "Effect" : "Deny",
        "NotAction" : [
          "iam:ChangePassword",
          "iam:CreateAccessKey",
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetAccountPasswordPolicy",
          "iam:GetUser",
          "iam:List*"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:MultiFactorAuthAge" : "true"
          }
        }
      },
      {
        "Effect" : "Deny",
        "NotAction" : [
          "iam:ChangePassword",
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetAccountPasswordPolicy",
          "iam:GetUser",
          "iam:List*",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken",
        ],
        "Resource" : "*",
        "Condition" : {
          "NumericGreaterThan" : {
            "aws:MultiFactorAuthAge" : "86400"
          }
        }
      }
    ]
  })
}
