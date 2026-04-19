# Repository Guidelines

## Project Structure & Module Organization
This repository provisions RunPod deployments with Terraform.

- [`runpod.tf`](./runpod.tf) and [`variables.tf`](./variables.tf) define the GPU pod deployment for Ollama.
- [`Makefile`](./Makefile) is the main entry point for common Terraform commands.

Avoid editing generated Terraform state files (`terraform.tfstate`, backups) unless you are intentionally repairing state.

## Build, Test, and Development Commands

- `make init` initializes the root Terraform workspace.
- `make plan` previews root pod changes.
- `make apply` deploys the root pod.
- `make output` prints root outputs such as the Ollama endpoint.
- `make destroy` tears down the root pod.

## Coding Style & Naming Conventions
Use Terraform/HCL formatting conventions: two-space indentation, aligned attribute blocks, and lowercase snake_case for variable and resource names. Keep shell scripts POSIX-friendly where practical and prefer `set -e` for fail-fast behavior. Run `terraform fmt` before committing changes to `.tf` files.

## Testing Guidelines
There is no separate unit test suite in this repository. Validate changes with:

- `terraform fmt -recursive`
- `terraform validate`
- `terraform plan`

For the pod module, the `null_resource.setup` provisioners provide a runtime smoke test after deployment. Treat a successful plan as the minimum review gate; deployment should only happen after reviewing the diff.

## Commit & Pull Request Guidelines
This checkout does not include Git history, so there is no repository-specific commit pattern to mirror. Use short, imperative commit messages such as `Add pod endpoint output`. For pull requests, include:

- a brief description of the deployment change,
- the commands run (`plan`, `apply`, etc.),
- any RunPod prerequisites,
- screenshots or copied output only when they help verify the result.

## Security & Configuration Tips
Secrets are read from `pass` and exposed through environment variables. Do not hardcode API keys in Terraform files or shell scripts.
