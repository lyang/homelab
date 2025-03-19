output "talos-nodes" {
  value = {
    for node in proxmox_vm_qemu.talos-nodes : node.name => node.default_ipv4_address
  }
}
