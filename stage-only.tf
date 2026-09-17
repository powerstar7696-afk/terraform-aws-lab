resource "aws_s3_bucket" "stage_only" {
  count = var.environment == "stage" ? 1 : 0

  bucket = "terraform-stage-only-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform Stage Only"
    Environment = "stage"
    ManagedBy   = "Terraform"
  }
}
