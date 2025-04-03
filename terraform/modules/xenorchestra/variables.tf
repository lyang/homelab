variable "xoa" {
  type = object({
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
        size = number
        sr   = string
      })
    }))
  })
}
