# terragrunt-brownfield

Example module demonstrating scriptable import of existing resources & baking hook scripts into modules.

The `import-resources-into-tfstate.sh` still required intimate knowledge of the resources created by your module, but this technique allows you to automatically import into tfstate, particularly helpful when you're bulk migrating resources or have multiple environments that manually running `terraform import` becomes monotonous or error prone. 

As we run multiple production deployments from the same terraform code base, this runs automatically for us in our terragrunt pipeline, reducing the TOIL involved in migrations. It also helps reduce TOIL & handoff when working in environments we don't have direct access to. 

<!-- BEGIN_TF_DOCS -->


## Example

```hcl
include {
  path = "global.hcl"
}

terraform {
  source = "..//."

  before_hook "import" {
    commands = ["apply", "plan"]
    execute  = ["./import-resources-into-tfstate.sh", get_terraform_command()]
  }
}

locals {
  unique_id = get_env("TT_UNIQUE_ID", "abcd")
  rg_name   = "terratest-${local.unique_id}"
}

inputs = {
  resource_group_name = local.rg_name
  location            = "uksouth"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure location, `az account list-locations` | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of an existing resource group. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | n/a |
<!-- END_TF_DOCS -->
