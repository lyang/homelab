terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pve.url
  pm_api_token_id     = var.pve.token-id
  pm_api_token_secret = var.pve.token-secret
}

module "pve" {
  source   = "./modules/pve"
  talos-vm = var.talos-vm
}
