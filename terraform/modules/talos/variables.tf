locals {
}

variable "talos" {
  type = object({
    cluster-name = string
    controlplane = object({
      common = object({
        name     = string
        template = string
        cpus     = number
        memory = object({
          max = number
        })
        storage = object({
          iso = string
        })
        iso = object({
          name = string
          url  = string
        })
        network = object({
          name = string
          cidr = string
        })
      })
      instances = list(object({
        host = string
        network = object({
          mac = string
        })
        disk = object({
          sr   = string
          size = number
        })
      }))
    })
    worker = object({
      common = object({
        name     = string
        template = string
        cpus     = number
        memory = object({
          max = number
        })
        storage = object({
          iso = string
        })
        iso = object({
          name = string
          url  = string
        })
        network = object({
          name = string
          cidr = string
        })
      })
      instances = list(object({
        host = string
        network = object({
          mac = string
        })
        disk = object({
          sr   = string
          size = number
        })
      }))
    })
  })
}
