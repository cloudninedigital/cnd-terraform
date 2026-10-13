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
- GitHub permissions to create:
  - Repositories
  - Repository deploy keys
- Required APIs enabled in the target GCP project:
  - Dataform API
  - Secret Manager API

## Required providers

This module uses these providers:

- `hashicorp/google`
- `integrations/github`
- `hashicorp/tls`

> Note: besides Google/TLS, an additional GitHub provider configuration is required for this module.

Example root setup:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
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
- `github_organization` (string, optional, default: `cloudninedigital`): Kept for compatibility with existing module interface.

## Outputs

- `dataform_repository_id`: Full GCP resource ID of the Dataform repository.
- `dataform_repository_name`: Short Dataform repository name.
- `github_repository_url`: SSH clone URL of the GitHub repository.
- `secret_version_id` (sensitive): Secret Manager version ID holding the SSH private key.

## Security note

The `host_public_key` used in SSH authentication is GitHub's public host key. It is not a private credential.
