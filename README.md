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

## Cost

| Deployment | GPU | Cost | Scaling |
|------------|-----|------|---------|
| Pod (Ollama) | A100 80GB Community | ~$1.64/hr | Always on |
