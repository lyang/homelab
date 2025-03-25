variable "xoa" {
  type = object({
    url   = string
    token = string
    storage = object({
      iso = string
      vdi = string
    })
  })
}

variable "talos-vm" {
  type = object({
    template = string
    cpus     = number
    memory = object({
      max = number
    })
    disk = object({
      size = number
    })
    network = object({
      name = string
    })
  })
}

variable "talos-node" {
  type = object({
    controlplane = object({
      count = number
      mac  = string
    })
    worker = object({
      count = number
      mac  = string
    })
  })
}
