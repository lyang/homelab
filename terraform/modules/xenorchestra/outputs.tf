output "instances" {
  value = {
    for node in xenorchestra_vm.this : node.name_label => node.ipv4_addresses[0]
  }
}
