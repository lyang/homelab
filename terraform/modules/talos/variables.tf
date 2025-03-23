variable "talos-cluster" {
  type = object({
    name     = string
    endpoint = string
    nodes = object({
      controlplanes = map(string)
      workers       = optional(map(string), {})
    })
  })
}
