# Charmed NiFi Terraform Solution

This is a Terraform module that deploys Charmed NiFi using the [Terraform Juju provider](https://github.com/juju/terraform-provider-juju/).
For provider configuration, see the [Terraform provider documentation](https://registry.terraform.io/providers/juju/juju/latest/docs).

---

## Architecture Overview

This module deploys the following component:

| Component | Charm | Role |
| --- | --- | --- |
| `nifi` | `nifi-k8s` | Apache NiFi data flow automation platform. |
| `git-integrator` (optional) | `git-integrator` | Distributes git repository connection details to NiFi. Deployed only when `git_integrator.enabled` is `true`. |
| `traefik` (optional) | `traefik-k8s` | Exposes the NiFi web UI and REST API outside the cluster. Deployed only when `traefik.enabled` is `true`. |

---

## API

### Inputs

| Name | Type | Description | Required |
| --- | --- | --- | --- |
| `model_uuid` | string | Reference to an existing Juju model to deploy NiFi into | true |
| `nifi_k8s` | object | Configuration for the `nifi-k8s` charm module | false |
| `git_integrator` | object | Configuration for the optional `git-integrator` charm module. Only deployed when `enabled = true`. | false |
| `traefik` | object | Configuration for the optional `traefik-k8s` charm module. Only deployed when `enabled = true`. | false |

The NiFi charm input object supports:

| Field | Type | Description | Default |
| --- | --- | --- | --- |
| `app_name` | string | Application name to deploy | `nifi` |
| `channel` | string | Charm channel to deploy from | `2.10/edge` |
| `revision` | number | Charm revision to use | `null` |
| `units` | number | Number of application units | `1` |
| `config` | map(string) | Charm-specific configuration options | `{}` |

The Git Integrator input object supports:

| Field | Type | Description | Default |
| --- | --- | --- | --- |
| `enabled` | bool | Whether to deploy git-integrator and relate it to NiFi | `false` |
| `app_name` | string | Application name to deploy | `git-integrator` |
| `channel` | string | Charm channel to deploy from | `1.0/edge` |
| `revision` | number | Charm revision to use | `null` |
| `units` | number | Number of application units | `1` |
| `config` | map(string) | Charm-specific configuration options (e.g. `repository_url`) | `{}` |

The Traefik input object supports:

| Field | Type | Description | Default |
| --- | --- | --- | --- |
| `enabled` | bool | Whether to deploy traefik-k8s and relate it to NiFi | `false` |
| `app_name` | string | Application name to deploy | `traefik` |
| `channel` | string | Charm channel to deploy from | `latest/stable` |
| `revision` | number | Charm revision to use | `null` |
| `units` | number | Number of application units | `1` |
| `config` | map(string) | Charm-specific configuration options (e.g. `external_hostname`) | `{}` |

**Important:** The `config` map must include a `sensitive-props-key` entry with a value of at least 12 characters. This key is used to encrypt sensitive values in NiFi flow definitions. Without it, the charm will remain in BlockedStatus.

---

### Outputs

| Name | Description |
| --- | --- |
| `nifi_k8s` | NiFi charm module |
| `git_integrator` | Git Integrator application resource (`null` when not enabled) |
| `traefik` | Traefik application resource (`null` when not enabled) |

---

## Relations

The following relations are established when the matching input is enabled:

| Integration | Purpose |
| --- | --- |
| `nifi ↔ git-integrator` | Provides NiFi with git repository connection details over the `git` interface (`git-registry` endpoint). |
| `nifi ↔ traefik` | Exposes NiFi over the `ingress` interface. NiFi derives `nifi.web.proxy.host` and `nifi.web.proxy.context.path` from the ingress URL. |

---

## Usage

This solution module can be used standalone or as part of a higher-level Terraform orchestration layer.

### Example: Basic Deployment

```hcl
model_uuid = "<model-uuid>"

nifi_k8s = {
  config = {
    "sensitive-props-key" = "my-secret-key-12345"
  }
}
```

### Example: Custom Configuration

```hcl
model_uuid = "<model-uuid>"

nifi_k8s = {
  app_name = "my-nifi"
  channel  = "2.10/edge"
  units    = 1
  config = {
    "sensitive-props-key" = "my-very-secure-key-123"
    # Additional NiFi configuration options
  }
}
```

### Example: With Git Integrator

To source flow definitions from a git repository, enable the optional
`git-integrator` charm and point it at a repository:

```hcl
model_uuid = "<model-uuid>"

nifi_k8s = {
  config = {
    "sensitive-props-key" = "my-secret-key-12345"
  }
}

git_integrator = {
  enabled = true
  config = {
    repository_url = "https://github.com/canonical/git-integrator.git"
    tracking_ref   = "main"
  }
}
```

### Example: With Traefik ingress

By default the NiFi UI is only reachable inside the cluster. Enable Traefik to
give it an external URL:

```hcl
model_uuid = "<model-uuid>"

nifi_k8s = {
  config = {
    "sensitive-props-key" = "my-secret-key-12345"
  }
}

traefik = {
  enabled = true
}
```

Retrieve the external URL after deployment with:

```bash
juju run traefik/0 show-proxied-endpoints
```

---

## Testing

### Running Tests

For module validation and smoke tests (including `kgoss` API checks):

```bash
just test
```

`just test` performs the following:
1. Creates a fresh `nifi-test` Juju model
2. Generates a dynamic tfvars file with model UUID
3. Generates and configures a random sensitive-props-key
4. Applies the Terraform configuration
5. Waits for NiFi to reach active status
6. Runs `kgoss` checks to verify NiFi API health

The test validates:
- **NiFi version**: Confirms NiFi 2.10.0 is deployed and running
- **System diagnostics endpoint**: `http://nifi-0.nifi-endpoints.nifi-test.svc.cluster.local:8080/nifi-api/system-diagnostics`
- **Flow controller status**: `http://nifi-0.nifi-endpoints.nifi-test.svc.cluster.local:8080/nifi-api/flow/status`

---

### Cleanup

The test automatically cleans up on exit. To manually destroy:

```bash
just destroy test/terraform_test.tfvars
```

---

### Testing the optional charms

```bash
just test-git-integrator
just test-traefik
```

`just test-traefik` deploys with `traefik.enabled = true` and additionally runs
the `test/traefik` kgoss spec, which checks that the NiFi UI and the
`/nifi-api/flow/status` endpoint are both served through the ingress.

---

## Repository References

- https://github.com/canonical/nifi-k8s-operator
- https://github.com/canonical/git-integrator
- https://github.com/canonical/traefik-k8s-operator
