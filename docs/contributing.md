# How to contribute

We'd love to accept your patches and contributions to this project.

## Before you begin

### Sign our Contributor License Agreement

Contributions to this project must be accompanied by a
[Contributor License Agreement](https://cla.developers.google.com/about) (CLA).
You (or your employer) retain the copyright to your contribution; this simply
gives us permission to use and redistribute your contributions as part of the
project.

If you or your current employer have already signed the Google CLA (even if it
was for a different project), you probably don't need to do it again.

Visit <https://cla.developers.google.com/> to see your current agreements or to
sign a new one.

### Review our community guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).

## Contribution process

### Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

Your Pull Request must be approved by one of the [code owners](CODEOWNERS).


## Solution development guidelines

### Directory structure
Each solution must follow the directory structure below so that our CI/CD and Deploy pipelines can run properly.

- app: application code and necessary files to build i, for example: Dockerfile, requirements.txt
- assets: static files such as architecture.png used in the README.md
- build: [Cloud Build yaml](https://cloud.google.com/build/docs/build-config-file-schema) files to deploy and destroy the solution
- infra: Terraform files
- README.md: Readme file following [this template](./template_readme.md)
- prereq.sh: Shell script with all pre-requisities required before running Cloud Build.


### Label Strategy
You must to have a variable to define resource labels, and aggregate this variables with the solution's labels with locals.

```hcl
locals {
  resource_labels = merge(var.resource_labels, {
    deployed_by = "cloudbuild"
    env         = "sandbox"
    repo        = "click-to-deploy-solutions"
    solution    = "private-cloud-data-fusion"
    terraform   = "true"
  })
}

variable "resource_labels" {
  type        = map(string)
  description = "Resource labels"
  default     = {}
}
```

### Cloud SQL
Since Cloud SQL does not allow you to recreate an instance immediately after deletion due to name conflict, please use a random suffix to the instance name, for example:
```hcl

resource "random_id" "db_name_suffix" {
 byte_length = 4
}

resource "google_sql_database_instance" "instance" {
 name                = "${var.sql_instance_prefix}-${random_id.db_name_suffix.hex}"
 region              = var.region
 database_version    = "MYSQL_8_0"

 settings {
   tier        = "db-custom-1-3840"
   user_labels = local.resource_labels
 }
}
```

### Provider versioning
After you have tested your solution, please set the provider versions so that it won't break with new updates.
```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.46.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.46.0"
    }
  }
}
```

### Image tagging
Our pipelines run on Cloud Build, so users do not rely on Cloud Shell VMs for running terraform apply or destroy, helm deployments and so on. Cloud Build pipelines use containers to run the steps, so please tag your containers properly so that the pipeline will not break with unexpected changes.
For example, the steps below will always run with the terraform image `1.0.0`.

```
steps:
- id: 'tf apply'
  name: 'hashicorp/terraform:1.0.0'
  args: 
  - apply
  - -auto-approve
  dir: terraform
```

### Architecture Diagram

Please use Google Cloud official icons to build the solution's diagram. You can find them on https://cloud.google.com/icons/.

### Open in Cloud Shell button

Use the following url pattern for the button "Open in Cloud Shell", please note the workspace param must be set to the solution path within this repository.
```
<a href="https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/click-to-deploy-solutions&cloudshell_workspace=path-to-solution" target="_new">
    <img alt="Open in Cloud Shell" src="https://gstatic.com/cloudssh/images/open-btn.svg">
</a>
```
