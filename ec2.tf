data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

module "app_ec2" {
  source = "./modules/ec2"

  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = "t3.micro"
  environment       = var.environment
  subnet_id         = module.networking.subnet_id
  security_group_id = aws_security_group.app.id
  key_name          = "defaultKeyPair"
}
