resource "juju_secret" "nifi_sensitive_props_key" {
  count      = var.nifi_k8s.sensitive_props_key != null ? 1 : 0
  model_uuid = var.model_uuid
  name       = "${var.nifi_k8s.app_name}-sensitive-props-key"
  value = {
    "sensitive-props-key" = var.nifi_k8s.sensitive_props_key
  }
}

resource "juju_access_secret" "nifi_sensitive_props_key" {
  count        = var.nifi_k8s.sensitive_props_key != null ? 1 : 0
  model_uuid   = var.model_uuid
  secret_id    = juju_secret.nifi_sensitive_props_key[0].secret_id
  applications = [var.nifi_k8s.app_name]
}

resource "juju_application" "nifi_k8s" {
  name       = var.nifi_k8s.app_name
  model_uuid = var.model_uuid

  charm {
    name     = "nifi-k8s"
    channel  = var.nifi_k8s.channel
    base     = var.nifi_k8s.base
    revision = var.nifi_k8s.revision
  }

  units = var.nifi_k8s.units

  config = merge(
    var.nifi_k8s.config,
    var.nifi_k8s.sensitive_props_key != null ? {
      "sensitive-props-key" = juju_secret.nifi_sensitive_props_key[0].secret_id
    } : {}
  )
}