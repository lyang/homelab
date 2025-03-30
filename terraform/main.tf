terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.5.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    xenorchestra = {
      source  = "vatesfr/xenorchestra"
      version = "0.31.1"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.root}/generated/.kubeconfig"
}

provider "flux" {
  kubernetes = {
    config_path = "${path.root}/generated/.kubeconfig"
  }
  git = {
    url = var.flux.github.repo
    http = {
      username = var.flux.github.username
      password = var.flux.github.pat
    }
  }
}

provider "xenorchestra" {
  url   = var.xoa.url
  token = var.xoa.token
}

data "talos_image_factory_versions" "this" {
  filters = {
    stable_versions_only = true
  }
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = local.talos-version
  filters = {
    names = [
      "i915",
      "xen-guest-agent",
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "this" {
  talos_version = data.talos_image_factory_extensions_versions.this.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
}

resource "terraform_data" "talos-iso" {
  provisioner "local-exec" {
    command = "curl --silent --output ${path.module}/generated/${local.talos-iso} ${data.talos_image_factory_urls.this.urls.iso}"
  }
}

data "xenorchestra_sr" "storage-iso" {
  name_label = var.xoa.storage.iso
}

data "xenorchestra_sr" "storage-vdi" {
  name_label = var.xoa.storage.vdi
}

resource "xenorchestra_vdi" "talos-iso" {
  depends_on = [terraform_data.talos-iso]
  name_label = local.talos-iso
  sr_id      = data.xenorchestra_sr.storage-iso.id
  filepath   = "${path.module}/generated/${local.talos-iso}"
  type       = "raw"
}

data "xenorchestra_template" "talos-template" {
  name_label = var.talos-vm.template
}

data "xenorchestra_network" "talos-network" {
  name_label = var.talos-vm.network.name
}

resource "xenorchestra_vm" "talos-controlplane" {
  count        = var.talos-node.controlplane.count
  memory_max   = var.talos-vm.memory.max
  cpus         = var.talos-vm.cpus
  name_label   = format("talos-controlplane-%02d", count.index + 1)
  template     = data.xenorchestra_template.talos-template.id
  auto_poweron = true
  cdrom {
    id = xenorchestra_vdi.talos-iso.id
  }

  network {
    network_id       = data.xenorchestra_network.talos-network.id
    mac_address      = format(var.talos-node.controlplane.mac, count.index + 1)
    expected_ip_cidr = var.talos-node.controlplane.cidr
  }

  disk {
    sr_id      = data.xenorchestra_sr.storage-vdi.id
    name_label = format("talos-controlplane-%02d-disk", count.index + 1)
    size       = var.talos-vm.disk.size
    attached   = true
  }
}

resource "xenorchestra_vm" "talos-worker" {
  count        = var.talos-node.worker.count
  memory_max   = var.talos-vm.memory.max
  cpus         = var.talos-vm.cpus
  name_label   = format("talos-worker-%02d", count.index + 1)
  template     = data.xenorchestra_template.talos-template.id
  auto_poweron = true
  cdrom {
    id = xenorchestra_vdi.talos-iso.id
  }

  network {
    network_id       = data.xenorchestra_network.talos-network.id
    expected_ip_cidr = var.talos-node.worker.cidr
    mac_address      = format(var.talos-node.worker.mac, count.index + 1)
  }

  disk {
    sr_id      = data.xenorchestra_sr.storage-vdi.id
    name_label = format("talos-worker-%02d-disk", count.index + 1)
    size       = var.talos-vm.disk.size
    attached   = true
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = local.talos-version
}

locals {
  talos-cluster-endpoint = format("https://%s:6443", xenorchestra_vm.talos-controlplane[0].ipv4_addresses[0])
  talos-iso              = format("talos-%s-%s-%s.iso", local.talos-version, data.talos_image_factory_urls.this.platform, data.talos_image_factory_urls.this.architecture)
  talos-version          = element(data.talos_image_factory_versions.this.talos_versions, -1)
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos-cluster.name
  cluster_endpoint = local.talos-cluster-endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos-cluster.name
  cluster_endpoint = local.talos-cluster-endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each = {
    for index, node in xenorchestra_vm.talos-controlplane :
    node.name_label => node
  }
  node = each.value.ipv4_addresses[0]
  config_patches = [
    templatefile("${path.module}/files/common-patch.yaml.tmpl", {
      hostname        = each.key
      talos-installer = data.talos_image_factory_urls.this.urls.installer
    }),
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each = {
    for index, node in xenorchestra_vm.talos-worker :
    node.name_label => node
  }
  node = each.value.ipv4_addresses[0]
  config_patches = [
    templatefile("${path.module}/files/common-patch.yaml.tmpl", {
      hostname        = each.key
      talos-installer = data.talos_image_factory_urls.this.urls.installer
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = xenorchestra_vm.talos-controlplane[0].ipv4_addresses[0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = xenorchestra_vm.talos-controlplane[0].ipv4_addresses[0]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.talos-cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in xenorchestra_vm.talos-controlplane : node.ipv4_addresses[0]]
  nodes                = concat([for node in xenorchestra_vm.talos-controlplane : node.ipv4_addresses[0]], [for node in xenorchestra_vm.talos-worker : node.ipv4_addresses[0]])
}

resource "local_file" "kubeconfig" {
  filename = "${path.root}/generated/.kubeconfig"
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
}

resource "local_file" "talosconfig" {
  filename = "${path.root}/generated/.talosconfig"
  content  = data.talos_client_configuration.this.talos_config
}

resource "flux_bootstrap_git" "this" {
  path = "clusters/homelab"
}

resource "kubernetes_secret" "sops" {
  metadata {
    name      = "sops"
    namespace = flux_bootstrap_git.this.namespace
  }
  data = {
    "sops.agekey" = var.flux.sops.age.private
  }
}
