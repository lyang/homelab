variable "flux" {
  type = object({
    github = object({
      repo     = string
      username = string
      pat      = string
    })
    kubeconfig = string
    sops = object({
      age = object({
        public  = string
        private = string
      })
    })
  })
}
