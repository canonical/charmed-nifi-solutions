# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

output "nifi_k8s" {
  description = "NiFi application resource."
  value       = module.nifi_k8s.application
}
