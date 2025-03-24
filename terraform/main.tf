terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
  }
}

data "talos_image_factory_versions" "this" {
  filters = {
    stable_versions_only = true
  }
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = element(data.talos_image_factory_versions.this.talos_versions, -1)
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

locals {
  talos-iso = format("talos-%s-%s-%s.iso", data.talos_image_factory_urls.this.talos_version, data.talos_image_factory_urls.this.platform, data.talos_image_factory_urls.this.architecture)
}

resource "terraform_data" "talos-iso" {
  provisioner "local-exec" {
    command = "curl --silent --output ${path.module}/generated/${local.talos-iso} ${data.talos_image_factory_urls.this.urls.iso}"
  }
}

