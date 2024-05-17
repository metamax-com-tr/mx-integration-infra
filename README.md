[![pipeline status](https://gitlab.orema.com.tr/metamax/infra/badges/main/pipeline.svg)](https://gitlab.orema.com.tr/metamax/infra/-/commits/main)
# Metamax Intagrations AWS Projet Infrastructure

This project is Infrastructure schema based Terraform. Accounting and Bank integrations are uping and running on this infra defined by that Terraform project. 

# Requiretments
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* Valid AWS Credential


# How to use
First you need AWS secret to access your AWS resources. After getting that you must set credentials on your shell environment.
```sh
 $ export AWS_ACCESS_KEY_ID = "AWS_ID"
 $ export AWS_SECRET_ACCESS_KEY = "AWS_SECRET"
 $ terraform init
 $ terraform apply
```

# How to use terrform Workspace

```sh

$ terraform workspace 
Usage: terraform [global options] workspace

  new, list, show, select and delete Terraform workspaces.

Subcommands:
    delete    Delete a workspace
    list      List Workspaces
    new       Create a new workspace
    select    Select a workspace
    show      Show the name of the current workspace
~/projects/infra/terraform (development)$ terraform workspace  list
  default
* development
  production
```

**Note: terraform.tfvars keeps AWS CLI profile. You must sure that the profile belongs to 'production' or 'development' AWS Account which appled on.**