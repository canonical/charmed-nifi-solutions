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
