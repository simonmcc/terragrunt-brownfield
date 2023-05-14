package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSkeleton(t *testing.T) {
	// UniqueID used to create a unique resource group to contain the resources
	// truncated to 4 char and lowered so we don't bust Azure's 24 char limit
	uniqueId := strings.ToLower(random.UniqueId()[:4])

	os.Setenv("TT_UNIQUE_ID", uniqueId)

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir:    ".",
		TerraformBinary: "terragrunt",
	})

	// Clean up resources with "terragrunt destroy" at the end of the test.
	defer terraform.TgDestroyAll(t, terraformOptions)

	// Run "terragrunt init" and "terragrunt apply". Fail the test if there are any errors.
	terraform.TgApplyAll(t, terraformOptions)

	// TODO: now remove the resource group from tfstate to verify clean import
	// remove from tfstate
	// run apply, terraform should report no-op as it's imported in the hook

	// Run `terraform output` to get the values of output variables and check they have the expected values.
	rg_name := terraform.Output(t, terraformOptions, "name")

	// Check resource group name
	assert.Equal(t, rg_name, "terratest-"+uniqueId)
}
