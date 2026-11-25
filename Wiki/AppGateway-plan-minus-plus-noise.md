# Application Gateway plan shows `-` and `+` for existing blocks

## Symptom

Adding one item (for example a new app) to an `azurerm_application_gateway` plans as an in-place update, but existing
`http_listener`, `backend_http_settings`, `probe` and `request_routing_rule` blocks appear as removed (`-`) and re-added (`+`):

```
Plan: 0 to add, 1 to change, 0 to destroy.
```

## It is a plan display issue, not an ARM delete and re-add

- The plan is one in-place update of the gateway resource (`~ update in-place`, `1 to change`). Nothing is destroyed or replaced.
- The provider sends the whole gateway to ARM in a single CreateOrUpdate call. The sub-objects are part of that one payload.
- The `id` of each `-` block equals the `id` of its `+` block (for example `.../httpListeners/alpha-listener`), so it is the same sub-object.

## Why Terraform shows it

These nested blocks are sets. Terraform matches set elements by their full content, not by name. If any attribute differs
between state and config, the old element is shown as `-` and the new one as `+`, even when the difference has no meaning.

The usual differences are optional attributes that Azure returns as `""` (or `0`) while the config leaves them `null`:

| Block                   | Attributes                                                                 |
| ----------------------- | -------------------------------------------------------------------------- |
| `http_listener`         | `ssl_profile_name`, `ssl_certificate_name`, `firewall_policy_id`           |
| `backend_http_settings` | `host_name`, `affinity_cookie_name`                                        |
| `probe`                 | `host`, `match.body`, `port` (`0` in state)                                |
| `request_routing_rule`  | `redirect_configuration_name`, `rewrite_rule_set_name`, `url_path_map_name` |

## How to confirm

Compare `before` and `after` for an existing item in the plan JSON. Only the attributes above should differ:

```powershell
terraform plan -var-file=add.tfvars -out=tfplan
terraform show -json tfplan | Out-File plan.json -Encoding utf8
```

`Compare-DemoPlan` in `AppGateway/azesDemo.ps1` does this and also counts the `-`/`+` blocks in the text plan.

## Mitigation

Set those optional attributes explicitly to `""` so config matches what Azure returns (`-var=explicit_empty=true` in this demo).
Some attributes, such as the probe `port`, cannot be set to the value held in state, so some noise may remain. It is still cosmetic.
