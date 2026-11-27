variable "bucket_name" {
  description = "Globally unique name of the Terraform state bucket. Supplied privately, never committed."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "The bucket name must be 3 to 63 characters of lowercase letters, digits, dots and hyphens."
  }
}
