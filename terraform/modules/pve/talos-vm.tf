resource "proxmox_vm_qemu" "talos-nodes" {
  count       = var.talos-vm.count
  name        = format("talos-%02d", count.index + 1)
  target_node = format("pve-%02d", count.index + 1)
  agent       = 1
  cores       = var.talos-vm.cores
  balloon     = var.talos-vm.balloon
  memory      = var.talos-vm.memory
  scsihw      = "virtio-scsi-single"
  boot        = "order=scsi0;ide0;net0"

  disks {
    ide {
      ide0 {
        cdrom {
          iso = var.talos-vm.iso
        }
      }
    }

    scsi {
      scsi0 {
        disk {
          size     = var.talos-vm.disk-size
          discard  = true
          iothread = true
          storage  = "local-lvm"
        }
      }
    }
  }

  network {
    id      = 0
    model   = "virtio"
    bridge  = "vmbr0"
    tag     = var.talos-vm.vlan
    macaddr = format(var.talos-vm.macaddr, count.index + 1)
  }
}
