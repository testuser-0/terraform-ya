module "k8s" {
  source = "../modules/infrastructure"

  vault_token          = var.vault_token
  network_name         = var.network_name
  placement_groups     = var.placement_groups
  nodes                = var.nodes
  public_subnet_name   = var.public_subnet_name
  private_subnet_name  = var.private_subnet_name
  vault_secrets_path   = var.vault_secrets_path
  security_group_names = var.security_group_names

}