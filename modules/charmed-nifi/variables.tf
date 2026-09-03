# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

variable "model_uuid" {
  description = "UUID of the juju model to deploy to."
  type        = string
}

variable "nifi_k8s" {
  description = "Inputs for nifi-k8s charm module."
  type = object({
    app_name = optional(string, "nifi")
    channel  = optional(string, "2.10/edge")
    units    = optional(number, 1)
    config   = optional(map(string), {})
    revision = optional(number, null)
  })
  default = {}
}

variable "git_integrator" {
  description = "Inputs for the optional git-integrator charm module. When enabled, deploys git-integrator and relates it to NiFi's git-registry endpoint."
  type = object({
    enabled  = optional(bool, false)
    app_name = optional(string, "git-integrator")
    channel  = optional(string, "1.0/edge")
    units    = optional(number, 1)
    config   = optional(map(string), {})
    revision = optional(number, null)
  })
  default = {}
}

variable "traefik" {
  description = "Inputs for the optional traefik-k8s charm module. When enabled, deploys traefik-k8s and relates it to NiFi's ingress endpoint."
  type = object({
    enabled  = optional(bool, false)
    app_name = optional(string, "traefik")
    channel  = optional(string, "latest/stable")
    units    = optional(number, 1)
    config   = optional(map(string), {})
    revision = optional(number, null)
  })
  default = {}
}
