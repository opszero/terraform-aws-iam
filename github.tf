module "oidc-github" {
  for_each = var.github

  source = "github.com/opszero/terraform-aws-oidc-github?ref=v1.1.0"

  github_repositories = each.value.repos

  create_oidc_provider = true

  attach_admin_policy     = false
  attach_read_only_policy = false

  iam_role_name        = "github-${each.key}"
  iam_role_policy_arns = lookup(each.value, "policy_arns", [])

  additional_thumbprints = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    data.tls_certificate.github.certificates[0].sha1_fingerprint,
  ]
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}
