
module "app_iam" {
  source      = "./modules/iam"
  environment = var.environment

}
