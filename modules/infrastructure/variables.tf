variable "vault_token" {
  type        = string
  description = "API token for connecting to VCD api"
  sensitive   = true

  validation {
    condition     = length(var.vault_token) != 0
    error_message = "API token is empty!"
  }
}

variable "network_name" {
  type = object({
    name = string
  })
}

variable "vault_secrets_path" {
  type        = string
  description = "The path to the secrets in Vault"
}

variable "public_subnet_name" {
  description = "The name of the public subnet"
}

variable "private_subnet_name" {
  description = "The name of the private subnet"
}

variable "security_group_names" {
  type    = list(string)
}

variable "placement_groups" {
  type = map(object({
    name        = string
    description = string
  }))
}

variable "nodes" {
  description = "Information about the VMs to create"
  type = map(object({
    name                   = string
    platform_id            = string
    zone                   = string
    cores                  = number
    memory                 = number
    auto_delete_boot       = bool
    additional_disks       = optional(map(object({
      size        = number
      auto_delete = bool
      device_name = string
      labels      = optional(map(string), {})
    })), {})
    subnet_type            = string
    static_ip              = string
    security_group         = string
    disk_type              = string
    boot_disk_size         = string
    use_placement_group    = bool
    placement_group_name   = string
    cloudinit_type         = string
  }))
}
