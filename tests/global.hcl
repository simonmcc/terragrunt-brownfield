terraform {
  extra_arguments "variables" {
    commands = get_terraform_commands_that_need_vars()
  }

  # fail as early & as fast as we can by checking access to Azure
  after_hook "terragrunt-read-config" {
    commands = ["terragrunt-read-config"]
    execute  = [find_in_parent_folders("./az-login.sh"), "ag1"]
  }
}
