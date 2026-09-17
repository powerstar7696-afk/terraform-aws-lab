terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-345485442601-1789473168"
    key    = "terraform/dev/terraform.tfstate"
    region = "ap-south-1"
  }

}

provider "aws" {
  region = "ap-south-1"
}
