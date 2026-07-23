# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

locals {
  # Extract sensitive-props-key from config if present
  sensitive_props_key_value = try(var.nifi_k8s.config["sensitive-props-key"], null)
}

# Create the Juju secret storing the sensitive properties key
resource "juju_secret" "nifi_sensitive_props_key" {
  count      = local.sensitive_props_key_value != null && local.sensitive_props_key_value != "" ? 1 : 0
  model_uuid = var.model_uuid
  name       = "nifi-sensitive-props-key"
  value = {
    "sensitive-props-key" = local.sensitive_props_key_value
  }
}

# Deploy NiFi using the charm module, passing the secret ID into the config
module "nifi_k8s" {
  source     = "git::https://github.com/canonical/nifi-k8s-operator//terraform?ref=track/2.10"
  model_uuid = var.model_uuid
  app_name   = var.nifi_k8s.app_name
  channel    = var.nifi_k8s.channel
  revision   = var.nifi_k8s.revision
  units      = var.nifi_k8s.units
  config = merge(
    var.nifi_k8s.config,
    length(juju_secret.nifi_sensitive_props_key) > 0 ? {
      "sensitive-props-key" = juju_secret.nifi_sensitive_props_key[0].secret_id
    } : {}
  )
}

# Grant the secret to NiFi AFTER it's deployed
resource "juju_access_secret" "nifi_sensitive_props_key" {
  count        = length(juju_secret.nifi_sensitive_props_key) > 0 ? 1 : 0
  model_uuid   = var.model_uuid
  secret_id    = juju_secret.nifi_sensitive_props_key[0].secret_id
  applications = [module.nifi_k8s.application.name]
  depends_on   = [module.nifi_k8s]
}
