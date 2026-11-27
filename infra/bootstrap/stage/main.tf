# Creates the bucket that stores the Terraform state of the stage environment.
# The first apply uses local state. Then the state migrates into this same bucket
# (see infra/README.md), so a lost laptop does not lose the bootstrap state.

module "state_backend" {
  source = "../../modules/state-backend"

  bucket_name = "certlab-stage-tfstate-${var.bucket_suffix}"
}
