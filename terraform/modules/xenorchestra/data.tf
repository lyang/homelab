data "xenorchestra_sr" "iso" {
  name_label = sensitive(var.xoa.common.storage.iso)
}

data "xenorchestra_template" "this" {
  name_label = var.xoa.common.template
}

data "xenorchestra_network" "this" {
  name_label = var.xoa.common.network.name
}
