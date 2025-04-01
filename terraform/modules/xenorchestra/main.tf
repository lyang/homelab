terraform {
  required_providers {
    xenorchestra = {
      source  = "vatesfr/xenorchestra"
      version = "0.31.1"
    }
  }
}

resource "terraform_data" "iso" {
  input = {
    filepath = "${path.module}/generated/${var.xoa.common.iso.name}"
  }
  provisioner "local-exec" {
    command = "curl --silent --output ${self.input.filepath} ${var.xoa.common.iso.url}"
  }
}

resource "xenorchestra_vdi" "this" {
  name_label = var.xoa.common.iso.name
  sr_id      = data.xenorchestra_sr.iso.id
  filepath   = terraform_data.iso.output.filepath
  type       = "raw"
}

resource "xenorchestra_vm" "this" {
  count        = length(var.xoa.instances)
  host         = var.xoa.instances[count.index].host
  memory_max   = var.xoa.common.memory.max
  cpus         = var.xoa.common.cpus
  name_label   = format("%s-%02d", var.xoa.common.name, count.index + 1)
  template     = data.xenorchestra_template.this.id
  auto_poweron = true
  cdrom {
    id = xenorchestra_vdi.this.id
  }

  network {
    network_id       = data.xenorchestra_network.this.id
    mac_address      = sensitive(var.xoa.instances[count.index].network.mac)
    expected_ip_cidr = sensitive(var.xoa.common.network.cidr)
  }

  disk {
    sr_id      = var.xoa.instances[count.index].disk.sr
    name_label = "primary"
    size       = var.xoa.common.disk.size
    attached   = true
  }
}

