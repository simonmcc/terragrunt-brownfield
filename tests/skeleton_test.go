package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSkeleton(t *testing.T) {
	// UniqueID used to create a unique resource group to contain the resources
	// truncated to 4 char and lowered so we don't bust Azure's 24 char limit
	uniqueId := strings.ToLower(random.UniqueId()[:4])

	rg_name := "terratest-" + uniqueId
	rg_location := "uksouth"

	os.Setenv("TT_RG_NAME", rg_name)
	os.Setenv("TT_RG_LOCATION", rg_location)

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir:    ".",
		TerraformBinary: "terragrunt",
	})

	// Clean up resources with "terragrunt destroy" at the end of the test.
	defer terraform.TgDestroyAll(t, terraformOptions)

	// Use the Azure CLI to create the resource that should be imported:
	create_rg := shell.Command{
		Command: "az",
		Args: []string{"group",
			"create",
			"--location", rg_location,
			"--name", rg_name,
		},
	}
	shell.RunCommandAndGetOutput(t, create_rg)

	// Run "terragrunt init" and "terragrunt apply". Fail the test if there are any errors.
	// Unfortunatly terragrunt doesn't have an idempotent check option, we can't actually tell
	// that terraform ran & detected no changes, but if the az cli create failed or the before_hook
	// didn't import the resource group, we would have failed (can't create duplicate RGs)
	terraform.TgApplyAll(t, terraformOptions)

	// Run `terraform output` to get the values of output variables and check they have the expected values.
	output_rg_name := terraform.Output(t, terraformOptions, "name")

	// Check resource group name
	assert.Equal(t, output_rg_name, rg_name)
}
