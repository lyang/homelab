terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pve.url
  pm_api_token_id     = var.pve.token-id
  pm_api_token_secret = var.pve.token-secret
}

provider "talos" {}

module "pve" {
  source   = "./modules/pve"
  talos-vm = var.talos-vm
}

module "talos" {
  source = "./modules/talos"
  talos-cluster = {
    name     = "homelab"
    endpoint = format("https://%s:6443", element(values(module.pve.talos-nodes), 0))
    nodes = {
      controlplanes = module.pve.talos-nodes
    }
  }
}
