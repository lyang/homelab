variable "talos-vm" {
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
