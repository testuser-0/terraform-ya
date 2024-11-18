data "yandex_vpc_network" "vpc" {
  name = var.network_name.name
}

data "yandex_vpc_subnet" "public_subnet" {
  name = var.public_subnet_name
}

data "yandex_vpc_subnet" "private_subnet" {
  name = var.private_subnet_name
}

data "vault_generic_secret" "yandex_credentials" {
  path = var.vault_secrets_path
}

data "yandex_compute_image" "default_os_image" {
  family = "ubuntu-2204-lts"
}

data "yandex_vpc_security_group" "sg" {
  for_each = toset(var.security_group_names)
  name     = each.value
}

locals {
  security_group_ids = { for sg in data.yandex_vpc_security_group.sg : sg.name => sg.id }
}

resource "yandex_compute_placement_group" "placement_group" {
  for_each    = var.placement_groups
  name        = each.value.name
  folder_id   = data.vault_generic_secret.yandex_credentials.data["folder_id"]
  description = each.value.description
}

locals {
  placement_group_ids = { for group in yandex_compute_placement_group.placement_group : group.name => group.id }
}

resource "yandex_compute_disk" "boot_disk" {
  for_each = var.nodes

  name     = "${each.key}-boot-disk"
  type     = each.value.disk_type
  zone     = each.value.zone
  size     = each.value.boot_disk_size
  image_id = data.yandex_compute_image.default_os_image.id
}

locals {
  additional_disks = flatten([
    for instance_key, instance_value in var.nodes : [
      for disk_name, disk_value in instance_value.additional_disks : {
        instance_key = instance_key
        name         = "${instance_value.name}-${disk_name}"
        size         = disk_value.size
        auto_delete  = disk_value.auto_delete
        disk_type    = instance_value.disk_type
        zone         = instance_value.zone
        labels       = disk_value.labels
        device_name  = disk_value.device_name
      }
    ] if length(instance_value.additional_disks) > 0
  ])
}

resource "yandex_compute_disk" "additional_disks" {
  for_each = {
    for disk in local.additional_disks : "${disk.instance_key}-${disk.name}" => disk
  }

  name = lower(replace(each.value.name, "_", "-"))

  size = each.value.size
  type = each.value.disk_type
  zone = each.value.zone

  labels = merge(
    {
      instance_key = each.value.instance_key
    },
    each.value.labels != null ? each.value.labels : {}
  )
}

locals {
  disk_ids = {
    for disk_key, disk in yandex_compute_disk.additional_disks : disk_key => disk.id
  }

  disks_by_instance = {
    for instance_key in keys(var.nodes) : instance_key => [
      for disk in local.additional_disks : {
        id          = local.disk_ids["${disk.instance_key}-${disk.name}"]
        auto_delete = disk.auto_delete
        device_name = disk.device_name
      }
      if disk.instance_key == instance_key
    ]
  }
}

resource "yandex_compute_instance" "nodes" {
  for_each = var.nodes

  name        = each.value.name
  platform_id = each.value.platform_id
  zone        = each.value.zone
  hostname    = each.value.name
  allow_stopping_for_update = true

  resources {
    core_fraction = 100
    cores         = each.value.cores
    memory        = each.value.memory
  }

  boot_disk {
    disk_id     = yandex_compute_disk.boot_disk[each.key].id
    auto_delete = each.value.auto_delete_boot
  }

  dynamic "secondary_disk" {
    for_each = lookup(local.disks_by_instance, each.key, [])

    content {
      disk_id     = secondary_disk.value.id
      auto_delete = secondary_disk.value.auto_delete
      device_name = secondary_disk.value.device_name
    }
  }

  network_interface {
    subnet_id          = each.value.subnet_type == "public" ? data.yandex_vpc_subnet.public_subnet.id : data.yandex_vpc_subnet.private_subnet.id
    nat                = each.value.subnet_type == "public"
    ip_address         = each.value.static_ip
    security_group_ids = each.value.security_group != null ? [local.security_group_ids[each.value.security_group]] : []
  }

  metadata = {
    user-data = file("disks/cloud-init-${each.value.cloudinit_type}.yaml")
  }

  dynamic "placement_policy" {
    for_each = each.value.use_placement_group ? [1] : []
    content {
      placement_group_id = local.placement_group_ids[each.value.placement_group_name]
    }
  }

  depends_on = [
    yandex_compute_placement_group.placement_group,
    yandex_compute_disk.boot_disk
  ]
}