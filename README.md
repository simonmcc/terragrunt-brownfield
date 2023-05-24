# terragrunt-brownfield

_**brown·field**_

> denoting or relating to urban sites for potential building development that have had previous development on them: Compare with greenfield.
"a contaminated brownfield site in the inner city"



As infrastructure engineers rarely get the opportunity to work in greenfield sites, where we get to create everything in the latest tool of our choice, so sometimes we need to import things that were built elsewhere. Sometimes we need to deal with growth & move resources between terraform state files to reduce blast radius.  The perceived wisdom in the terraform community is just to `terraform import` or `terraform state mv` our way to happiness. That's not something that scales or works well in environments where you don't have direct access & rely on tools & automation to run terraform/terragrunt for you.

We've developed a pattern of brownfield-aware terraform modules that use terragrunt hooks to import resources if they already exist, and allow terraform to create resources that don't already exist.  This still requires intimate knowledge of what your module creates, but this investment is put into a reusable script maintained with the module.

The `before_hook` script `import-resources-into-tfstate.sh` still requires intimate knowledge of the resources created by your module, but this technique allows you to automatically import into tfstate, particularly helpful when you're bulk migrating resources or have multiple environments that manually running `terraform import` becomes monotonous or error prone.

Additionally, our implementation of the script supports `apply` and `plan` mode, in plan mode we report what would happen & an in apply mode we perform the imports. 

We run multiple production deployments from the same terraform code base, this runs automatically for us in our terragrunt pipeline, reducing the TOIL involved in migrations and state split operations. It also helps reduce TOIL & handoff when working in environments we don't have direct access to.


## Example

Here's an example invocation of our module, in this case we're importing a resource group if it already exists.

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

inputs = {
  resource_group_name = "terratest-abcd"
  location            = "uksouth"
}
```

## Testing

> stop writing things you can't test

This module includes a [terratest](https://terratest.gruntwork.io/) integration test, which creates a resource group & then runs `terragrunt` so that the hook will import the group, terraform will fail if the resource group wasn't imported (as you can't create a duplicate group). 

## Development Workflow

[Makefile](Makefile) contains targets for formatting, updating docs & running tests, installing requires tools and running the terratest integration test.

* `make validate` terraform fmt, init, validate.
* `make test` run terratest integration tests.
* `make docs` update README.md via terraform-docs
* `make clean` clean up all of the .terraform & .terragrunt caches
* `make install_tools_macos` install required tools via [brew](https://brew.sh)

## Future Work

1. Demonstrate state migration (`terraform state rm` from one module, import into new module)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.56 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.57.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

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
