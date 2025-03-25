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
