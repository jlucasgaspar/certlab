provider "aws" {
  region = var.aws_region

  # Stops a run that uses credentials of another account, such as the management account.
  allowed_account_ids = [var.allowed_account_id]

  default_tags {
    tags = {
      project     = "certlab"
      environment = "stage"
      managed-by  = "terraform"
      owner       = "certlab-maintainer"
    }
  }
}
