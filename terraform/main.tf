terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    deepmerge = {
      source  = "registry.terraform.io/isometry/deepmerge"
      version = "1.0.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.6"
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

provider "xenorchestra" {
  url   = var.xoa-provider.url
  token = var.xoa-provider.token
}

module "talos" {
  source = "./modules/talos"
  talos  = var.talos
}

module "flux" {
  source = "./modules/flux"
  flux   = provider::deepmerge::mergo(var.flux, { kubeconfig = module.talos.kubeconfig })
}

