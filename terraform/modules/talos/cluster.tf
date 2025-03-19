resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos-cluster.name
  cluster_endpoint = var.talos-cluster.endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos-cluster.name
  cluster_endpoint = var.talos-cluster.endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = var.talos-cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for host, ip in var.talos-cluster.nodes.controlplanes : ip]
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.talos-cluster.nodes.controlplanes
  node                        = each.value
  config_patches = [
    templatefile("${path.module}/templates/hostname.yaml.tmpl", {
      hostname = each.key
    }),
    file("${path.module}/files/scheduling.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.talos-cluster.nodes.workers
  node                        = each.value
  config_patches = [
    templatefile("${path.module}/templates/hostname.yaml.tmpl", {
      hostname = each.key
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = element(values(var.talos-cluster.nodes.controlplanes), 0)
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = element(values(var.talos-cluster.nodes.controlplanes), 0)
}
