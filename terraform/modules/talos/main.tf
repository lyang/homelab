terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
    deepmerge = {
      source = "registry.terraform.io/isometry/deepmerge"
    }
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

module "controlplane" {
  source = "../xenorchestra"
  xoa    = provider::deepmerge::mergo(var.talos.controlplane, local.talos-iso)
}

module "worker" {
  source = "../xenorchestra"
  xoa    = provider::deepmerge::mergo(var.talos.worker, local.talos-iso)
}

resource "talos_machine_secrets" "this" {
  talos_version = local.talos-version
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each                    = module.controlplane.instances
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value
  config_patches = [
    templatefile("${path.module}/files/common-patch.yaml", {
      hostname        = each.key
      talos-installer = data.talos_image_factory_urls.this.urls.installer
    }),
    file("${path.module}/files/controlplane-patch.yaml")
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each                    = module.worker.instances
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value
  config_patches = [
    templatefile("${path.module}/files/common-patch.yaml", {
      hostname        = each.key
      talos-installer = data.talos_image_factory_urls.this.urls.installer
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(module.controlplane.instances)[0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(module.controlplane.instances)[0]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.talos.cluster-name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = values(module.controlplane.instances)
  nodes                = concat(values(module.controlplane.instances), values(module.worker.instances))
}

resource "local_file" "kubeconfig" {
  filename             = "${path.module}/generated/.kubeconfig"
  directory_permission = "0700"
  file_permission      = "0600"
  content              = talos_cluster_kubeconfig.this.kubeconfig_raw
}

resource "local_file" "talosconfig" {
  filename             = "${path.module}/generated/.talosconfig"
  directory_permission = "0700"
  file_permission      = "0600"
  content              = data.talos_client_configuration.this.talos_config
}
