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
| `base` | string | Base to deploy the application with | `null` |
| `revision` | number | Charm revision to use | `null` |
| `units` | number | Number of application units | `1` |
| `config` | map(string) | Charm-specific configuration options | `{}` |
| `sensitive_props_key` | string | Sensitive properties encryption key (min 12 characters) | `null` |

**Note:** The `sensitive_props_key` is required for NiFi to become active. This key is used to encrypt sensitive values in flow definitions.

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
  sensitive_props_key = "my-secret-key-12345"
}
```

### Example: Custom Configuration

```hcl
model_uuid = "<model-uuid>"

nifi_k8s = {
  app_name            = "my-nifi"
  channel             = "2.10/edge"
  units               = 1
  sensitive_props_key = "my-very-secure-key-123"
  config = {
    # Additional NiFi configuration options
  }
}
```

---

## Testing

### Running Tests

For module validation and smoke tests (including `kgoss` service/API checks):

```bash
just test
```

`just test` performs the following:
1. Creates a fresh `nifi-test` Juju model
2. Applies the Terraform configuration from [test/terraform_test_local_executor.tfvars](test/terraform_test_local_executor.tfvars)
3. Waits for NiFi to reach active status
4. Runs `kgoss` checks to verify NiFi cluster connectivity

The test validates:
- NiFi API accessibility (`http://nifi-endpoints.nifi-test.svc.cluster.local:8443/nifi-api/controller/cluster`)
- Cluster node status (CONNECTED)

---

### Cleanup

To remove the deployment and destroy the associated Juju model:

```bash
just destroy test/terraform_test_local_executor.tfvars
```

---

## Repository References

- https://github.com/canonical/nifi-k8s-operator
