variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}

variable "count" {
  description = "The number of apps to be deployed"
  type        = number
  default     = 1
}

variable "resources" {
  description = "The resource to assign to the application."
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 500,
    memory = 256
  }
}

variable "constraints" {
  description = "The constraints to assign to the application."
  type = list(object({
    attribute = string
    operator  = string
    value     = string
  }))
  default = []
}
variable "update" {
  description = "The update strategy to assign to the application."
  type = object({
    max_parallel      = number
    min_healthy_time  = string
    healthy_deadline  = string
    progress_deadline = string
    auto_revert       = bool
    auto_promote      = bool
    canary            = number
    stagger           = string
  })
  default = {
    max_parallel      = 1,
    min_healthy_time  = "10s",
    healthy_deadline  = "3m",
    progress_deadline = "10m",
    auto_revert       = true,
    auto_promote      = true,
    canary            = 1,
    stagger           = "30s"
  }
}

variable "migrate" {
  description = "The migrate strategy to assign to the application."
  type = object({
    max_parallel     = number
    min_healthy_time = string
    healthy_deadline = string
    health_check     = string
  })
  default = {
    max_parallel     = 1,
    min_healthy_time = "10s",
    healthy_deadline = "5m",
    health_check     = "checks"
  }
}


variable "ports" {
  description = "The ports to assign to the application."
  type = list(object({
    name   = string
    port   = number
    static = bool
  }))
  default = [
    {
      name   = "http"
      port   = 8080
      static = false
    }
  ]
}

variable "consul_services" {
  description = "The services to register to consul."
  type = list(object({
    name        = string
    port        = string
    tags        = list(string)
    canary_tags = list(string)
    prometheus  = bool
  }))
  default = []
}

variable "image" {
  description = "The image to deploy"
  type        = string
}


variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "extra_hosts" {
  description = "The extra hosts to add to the application."
  type        = list(string)
  default     = []
}

variable "entrypoint" {
  description = "The entrypoint to use for the application."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "The environment variables to add to the application."
  type        = map(string)
  default     = {}
}


variable "app_files" {
  description = "Local files that will be mounted at /local"
  type = list(object({
    // Absolute path OR Relative to your working directory
    src         = string
    destination = string
    env         = bool
  }))
  default = []
}
