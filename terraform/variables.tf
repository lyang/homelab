variable "pve" {
  type = object({
    url = string 
    token-id = string 
    token-secret = string 
  })
}

variable "vm" {
  type = object({
    count = number
    cores = number
    balloon = number
    memory = number
    iso = string
    disk-size = string
    vlan = number
    macaddr = string
  })
}
