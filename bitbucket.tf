module "bitbucket" {
  for_each = var.bitbucket

  source = "github.com/opszero/terraform-aws-bitbucket-oidc?ref=v1.0.0"

  workspace_name = each.value.workspace_name
  workspace_uuid = each.value.workspace_uuid

  roles = {
    role1 = {
      name             = "bitbucket-${each.key}"
      allowed_subjects = lookup(each.value, "subjects", [])
      # This is matched against the sub claim, which provided in the following format:
      # {REPOSITORY_UUID}[:{ENVIRONMENT_UUID}]:{STEP_UUID}
      # More info here: https://support.atlassian.com/bitbucket-cloud/docs/deploy-on-aws-using-bitbucket-pipelines-openid-connect/#Using-claims-in-ID-tokens-to-limit-access-to-the-IAM-role-in-AWS

      inline_policies_json = lookup(each.value, "policy_json", [])
      # You can either add policies inline here or add them via aws_iam_role_policy_attachment resource
    }
  }
}
