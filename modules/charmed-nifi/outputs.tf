# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

output "nifi_k8s" {
  description = "NiFi application resource."
  value       = module.nifi_k8s.application
}

output "git_integrator" {
  description = "Git Integrator application resource (null when not enabled)."
  value       = var.git_integrator.enabled ? module.git_integrator[0].application : null
}

output "traefik" {
  description = "Traefik application resource (null when not enabled)."
  value       = var.traefik.enabled ? module.traefik[0].application : null
}
