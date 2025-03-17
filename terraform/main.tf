terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.pve.url
  pm_api_token_id = var.pve.token-id
  pm_api_token_secret = var.pve.token-secret
}

resource "proxmox_vm_qemu" "talos-nodes" {
  count = var.vm.count
  name = format("talos-%02d", count.index + 1)
  target_node = format("pve-%02d", count.index + 1)
  agent = 1
  cores = var.vm.cores
  balloon = var.vm.balloon
  memory = var.vm.memory
  scsihw = "virtio-scsi-single"
  boot = "order=scsi0;ide0;net0"

  disks {
    ide {
      ide0 {
        cdrom {
          iso = var.vm.iso
        }
      }
    }

    scsi {
      scsi0 {
        disk {
          size = var.vm.disk-size
          discard = true
          iothread = true
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
    tag = var.vm.vlan
    macaddr = format(var.vm.macaddr, count.index + 1)
  }
}
