# Charmed NiFi Terraform Solution

This is a Terraform module that deploys Charmed NiFi using the [Terraform Juju provider](https://github.com/juju/terraform-provider-juju/).
For provider configuration, see the [Terraform provider documentation](https://registry.terraform.io/providers/juju/juju/latest/docs).

---

## Architecture Overview

This module deploys the following component:

| Component | Charm | Role |
| --- | --- | --- |
| `nifi` | `nifi-k8s` | Apache NiFi data flow automation platform. |

---

## API

### Inputs

| Name | Type | Description | Required |
| --- | --- | --- | --- |
| `model_uuid` | string | Reference to an existing Juju model to deploy NiFi into | true |
| `nifi_k8s` | object | Configuration for the `nifi-k8s` charm module | false |

The NiFi charm input object supports:

| Field | Type | Description | Default |
| --- | --- | --- | --- |
| `app_name` | string | Application name to deploy | `nifi` |
| `channel` | string | Charm channel to deploy from | `2.10/edge` |
| `revision` | number | Charm revision to use | `null` |
| `units` | number | Number of application units | `1` |
| `config` | map(string) | Charm-specific configuration options | `{}` |

**Important:** The `config` map must include a `sensitive-props-key` entry with a value of at least 12 characters. This key is used to encrypt sensitive values in NiFi flow definitions. Without it, the charm will remain in BlockedStatus.

---

### Outputs

| Name | Description |
| --- | --- |
| `nifi_k8s` | NiFi charm module |

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

## Repository References

- https://github.com/canonical/nifi-k8s-operator
