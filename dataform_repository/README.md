# Dataform Repository Module

This module provisions a complete Dataform-to-GitHub SSH setup:

- A private GitHub repository
- A deploy key on that repository
- A generated SSH key pair (`tls_private_key`)
- A Secret Manager secret/version containing the private key
- IAM access for the Dataform service agent to read the secret
- A `google_dataform_repository` connected to the GitHub repo over SSH

## Prerequisites

- Terraform 1.x
- Google Cloud permissions to create:
  - Dataform repositories
  - Secret Manager secrets/versions
  - Secret IAM bindings
  - Enabled APIs (the module enables the Dataform and Secret Manager APIs itself, and leaves them on when destroyed)
- GitHub permissions to create:
  - Repositories
  - Repository deploy keys

## Required providers

This module uses these providers:

- `hashicorp/google`
- `hashicorp/google-beta` (`google_dataform_repository` is beta only)
- `integrations/github`
- `hashicorp/tls`

> Note: besides Google/TLS, an additional GitHub provider configuration is required for this module.

Example root setup:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# Extra GitHub provider instance used by this module.
provider "github" {
  alias = "dataform_repo"
  owner = "cloudninedigital"
  token = var.github_token
}

module "dataform_repository" {
  source = "../../dataform_repository"

  providers = {
    github = github.dataform_repo
  }

  repository_name    = "example-dataform-repo"
  project            = var.project
  region             = var.region
  git_default_branch = "main"
  schema_suffix      = "dev"
}
```

## Inputs

- `repository_name` (string, required): Name of the Dataform/GitHub repository.
- `project` (string, required): GCP project ID.
- `region` (string, required): GCP region for Dataform.
- `git_default_branch` (string, optional, default: `main`): Default git branch.
- `schema_suffix` (string, optional, default: `null`): Workspace schema suffix.
- `existing_github_repository` (string, optional, default: `null`): Name of an existing GitHub repository (in the provider's `owner`) to connect instead of creating one. `repository_name` then only names the Dataform repository and secret. Dataform reads `workflow_settings.yaml` from the repository root; subdirectories are not supported.
- `service_account` (string, optional, default: `null`): Service account the repository's workflow/release configurations run as (needed under strict act-as). The Dataform service agent needs Service Account Token Creator on it.
- `github_organization` (string, optional, default: `cloudninedigital`): Unused; the organization comes from the `github` provider's `owner`. Kept for compatibility with existing module interface.

## Outputs

- `dataform_repository_id`: Full GCP resource ID of the Dataform repository.
- `dataform_repository_name`: Short Dataform repository name.
- `github_repository_url`: SSH clone URL of the GitHub repository.
- `secret_version_id` (sensitive): Secret Manager version ID holding the SSH private key.

## Notes

- Destroying the module archives the GitHub repository it created instead of deleting it. An existing repository (`existing_github_repository`) is left alone; only its deploy key is removed.
- With an existing repository, the GitHub token needs admin rights on it to add the deploy key, and the deploy key has write access to the whole repository.
- The Dataform service agent is created up front (`google_project_service_identity`), so a project where Dataform was never used works on the first apply.

## Security note

The `host_public_key` used in SSH authentication is GitHub's public host key. It is not a private credential.
