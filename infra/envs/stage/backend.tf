# Remote state in the bucket created by infra/bootstrap/stage.
# The bucket name is private and comes from backend.local.hcl (ignored by Git):
#   terraform init -backend-config=backend.local.hcl
terraform {
  backend "s3" {
    key          = "envs/stage/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
