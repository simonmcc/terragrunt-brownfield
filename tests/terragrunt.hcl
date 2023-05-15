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
  # load these from the environment so that the terratest test harness can set them
  rg_name     = get_env("TT_RG_NAME", "terratest-abcd")
  rg_location = get_env("TT_RG_LOCATION", "uksouth")
}

inputs = {
  resource_group_name = local.rg_name
  location            = local.rg_location
}
