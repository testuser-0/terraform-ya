variable "vault_token" {}

data "vault_generic_secret" "yandex_credentials" {
  path = "opentofu/yandex/test_kz1"
}

variable "network_name" {
  type = object({
    name = string
  })
  default = {
    name = "test_kz1_network"
  }
}

variable "public_subnet_name" {
  description = "The name of the public subnet"
  default     = "public-subnet"
}

variable "private_subnet_name" {
  description = "The name of the private subnet"
  default     = "private-subnet"
}

variable "vault_secrets_path" {
  type        = string
  description = "The path to the secrets in Vault"
  default     = "opentofu/yandex/test_kz1"
}

variable "security_group_names" {
  type    = list(string)
  default = ["bastion_security_group"]
}

variable "placement_groups" {
  type = map(object({
    name        = string
    description = string
  }))
  default = {
    "worker"  = { name = "k8s-worker-pg", description = "Placement group for k8s worker nodes" }
  }
}

variable "nodes" {
  description = "Information about the VMs to create"
  type = map(object({
    name             = string
    platform_id      = string
    zone             = string
    cores            = number
    memory           = number
    auto_delete_boot = bool
    boot_disk_size   = number
    additional_disks = optional(map(object({
      size        = number
      auto_delete = bool
      device_name = string
      labels      = optional(map(string), {})
    })), {})
    disk_type            = string
    subnet_type          = string
    static_ip            = string
    security_group       = string
    use_placement_group  = bool
    placement_group_name = string
    cloudinit_type       = string
  }))

  default = {
    "test-kz1-postal-1" = {
      name                 = "test-kz1-postal-1"
      platform_id          = "standard-v3"
      zone                 = "kz1-a"
      cores                = 2
      memory               = 4
      auto_delete_boot     = true
      boot_disk_size       = 40
      additional_disks     = {}
      disk_type            = "network-ssd"
      subnet_type          = "private"
      static_ip            = "10.20.10.27"
      security_group       = null
      use_placement_group  = true
      placement_group_name = "k8s-worker-pg"
      cloudinit_type       = "general"
    }
  }
}

