
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}
