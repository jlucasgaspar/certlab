output "bucket_name" {
  description = "Name of the state bucket. Marked sensitive so CI logs on a public repository never print it."
  value       = aws_s3_bucket.state.id
  sensitive   = true
}
