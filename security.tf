
resource "aws_security_group" "app" {
  name        = "${var.environment}-terraform-app-sg"
  description = "Security group for Terraform lab EC2"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["106.215.172.6/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-terraform-app-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
