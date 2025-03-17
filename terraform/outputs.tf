output "talos-nodes" {
  value = proxmox_vm_qemu.talos-nodes.*.default_ipv4_address
}
