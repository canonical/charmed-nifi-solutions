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

# Deploy the optional Git Integrator charm, which distributes git repository
# connection details to NiFi via the git-registry relation.
module "git_integrator" {
  count      = var.git_integrator.enabled ? 1 : 0
  source     = "git::https://github.com/canonical/git-integrator//terraform?ref=git-integrator-rev5"
  model_uuid = var.model_uuid
  app_name   = var.git_integrator.app_name
  channel    = var.git_integrator.channel
  units      = var.git_integrator.units
  config     = var.git_integrator.config
  revision   = var.git_integrator.revision
}

# Deploy the optional Traefik charm, which exposes the NiFi web UI and REST API
# outside the cluster. The charm module sets `trust` itself, so no extra
# permissions need granting here.
module "traefik" {
  count      = var.traefik.enabled ? 1 : 0
  source     = "git::https://github.com/canonical/traefik-k8s-operator//terraform?ref=traefik-k8s-rev440"
  model_uuid = var.model_uuid
  app_name   = var.traefik.app_name
  channel    = var.traefik.channel
  units      = var.traefik.units
  config     = var.traefik.config
  revision   = var.traefik.revision
}
