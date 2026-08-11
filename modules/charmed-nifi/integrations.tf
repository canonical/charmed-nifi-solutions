# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

# Relate NiFi to the Git Integrator so it can source flow definitions from a
# git repository. Established only when git-integrator is enabled.
resource "juju_integration" "nifi_to_git_integrator" {
  count      = var.git_integrator.enabled ? 1 : 0
  model_uuid = var.model_uuid
  application {
    name     = module.nifi_k8s.application.name
    endpoint = module.nifi_k8s.requires["git-registry"]
  }
  application {
    name     = module.git_integrator[0].application.name
    endpoint = module.git_integrator[0].provides.git
  }
}
