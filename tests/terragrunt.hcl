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
