data "aws_caller_identity" "current" {}

module "app_bucket" {
  source = "./modules/s3"

  bucket_name = (
    var.environment == "dev"
    ? "terraform-app-dev-${data.aws_caller_identity.current.account_id}"
    : "terraform-app-${var.environment}-${data.aws_caller_identity.current.account_id}"
  )
  environment = var.environment

  tags = {
    Name        = "Terraform App Bucket"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
