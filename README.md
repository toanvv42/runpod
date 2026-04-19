# RunPod Gemma 4 31B Deployment

Deploy Gemma 4 31B on RunPod as a GPU pod with Ollama.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [pass](https://www.passwordstore.org/) with the following entries:
  - `pass apikey/runpod` — RunPod API key

## Structure

```
.
├── Makefile              # All commands
├── runpod.tf             # GPU Pod deployment (Ollama)
└── variables.tf          # Pod variables
```

## GPU Pod (Ollama)

Always-on pod running Ollama on A100 80GB. No auth — endpoint is open.

```bash
make init           # terraform init
make plan           # preview changes
make apply          # deploy pod
make output         # show endpoint URL
make destroy        # tear down pod
```

**Endpoint:** `https://<POD_ID>-11434.proxy.runpod.net/v1` (OpenAI-compatible, no API key needed)

## GitHub Actions

Manual deployment is available through [`.github/workflows/runpod-pod.yml`](./.github/workflows/runpod-pod.yml).

Set this repository secret before running the workflow:

- `RUNPOD_API_KEY` — RunPod API key used by the Terraform provider

Then open the `RunPod Pod` workflow in GitHub Actions and choose one of:

- `plan`
- `apply`
- `destroy`

The workflow also accepts `ollama_model` and `use_spot` inputs, which map directly to the Terraform variables in this repo.

`apply` and `destroy` use the protected GitHub Environment `runpod-production`. Configure required reviewers for that environment in GitHub before relying on those actions.

## Cost

| Deployment | GPU | Cost | Scaling |
|------------|-----|------|---------|
| Pod (Ollama) | A100 80GB Community | ~$1.64/hr | Always on |
