terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.6"
    }
  }
}

provider "flux" {
  kubernetes = {
    config_path = var.flux.kubeconfig
  }
  git = {
    url = var.flux.github.repo
    http = {
      username = var.flux.github.username
      password = var.flux.github.pat
    }
  }
}

provider "kubernetes" {
  config_path = var.flux.kubeconfig
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
