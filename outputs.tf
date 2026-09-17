output "ec2_instance_id" {
  value = module.app_ec2.instance_id
}

output "ec2_public_ip" {
  value = module.app_ec2.public_ip
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "subnet_id" {
  value = module.networking.subnet_id
}

output "iam_role_name" {
  value = module.app_iam.role_name
}

output "app_bucket_name" {
  value = module.app_bucket.bucket_name
}
