variable "aws_region" {
  description = "AWS region of the stage environment."
  type        = string
  default     = "us-east-1"
}

variable "allowed_account_id" {
  description = "ID of the certlab-stage account. Terraform refuses to run in any other account. Supplied privately."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.allowed_account_id))
    error_message = "The account ID must be 12 digits."
  }
}

variable "bucket_suffix" {
  description = "Private suffix that makes the state bucket name globally unique. Supplied privately."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{8,24}$", var.bucket_suffix))
    error_message = "The suffix must be 8 to 24 lowercase letters or digits."
  }
}
