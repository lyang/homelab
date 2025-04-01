output "kubeconfig" {
  value = local_file.kubeconfig.filename
}

output "talosconfig" {
  value = local_file.talosconfig.filename
}
