locals {
  cluster-endpoint = "https://${values(module.controlplane.instances)[0]}:6443"
  talos-version    = "v1.9.5"
  talos-iso = {
    "common" = {
      "iso" = {
        "name" = format("talos-%s-%s-%s.iso", local.talos-version, data.talos_image_factory_urls.this.platform, data.talos_image_factory_urls.this.architecture)
        "url"  = data.talos_image_factory_urls.this.urls.iso
      }
    }
  }
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = local.talos-version
  filters = {
    names = [
      "i915",
      "iscsi-tools",
      "xen-guest-agent",
    ]
  }
}

data "talos_image_factory_urls" "this" {
  talos_version = data.talos_image_factory_extensions_versions.this.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos.cluster-name
  cluster_endpoint = local.cluster-endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos.cluster-name
  cluster_endpoint = local.cluster-endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}
