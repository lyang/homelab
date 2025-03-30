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
      mac   = string
      cidr  = string
    })
    worker = object({
      count = number
      mac   = string
      cidr  = string
    })
  })
}

variable "talos-cluster" {
  type = object({
    name = string
  })
}

variable "flux" {
  type = object({
    github = object({
      repo     = string
      username = string
      pat      = string
    })
    sops = object({
      age = object({
        public  = string
        private = string
      })
    })
  })
}
