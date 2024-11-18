terraform {
  required_providers {
    yandex = {
      source = "opentofu/yandex"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
  required_version = ">= 0.13"
}