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
        disk = object({
          size = number
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
          sr = string
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
        disk = object({
          size = number
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
          sr = string
        })
      }))
    })
  })
}
