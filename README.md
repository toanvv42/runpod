# RunPod Gemma 4 31B Deployment

Deploy Gemma 4 31B on RunPod as a GPU pod with Ollama.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [pass](https://www.passwordstore.org/) with the following entries:
  - `pass apikey/runpod` — RunPod API key
  - `pass telegram/bot_token` — optional Telegram bot token for deployment notifications
  - `pass telegram/chat_id` — optional Telegram chat or channel ID for deployment notifications
- AWS credentials with access to the S3 backend bucket `terraform-state-421427265342-ap-southeast-1-runpod`

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
make output         # show Terraform outputs
make destroy        # tear down pod
```

After a successful `apply`, the pod endpoints are sent to Telegram if `telegram_bot_token` and `telegram_chat_id` are set. Terraform also exposes both the native Ollama API and the OpenAI-compatible API as outputs.

### Endpoint Selection

Prefer the native Ollama API for direct integrations:

- Native Ollama API: `https://<pod-id>-11434.proxy.runpod.net/api`
- OpenAI-compatible API: `https://<pod-id>-11434.proxy.runpod.net/v1`

The OpenAI-compatible `/v1` endpoint should be treated as experimental. In testing with `gemma4:31b`, it may expose a non-standard `message.reasoning` field and can consume completion budget before producing `message.content`. Use `/api/chat` or `/api/generate` when you want the most predictable behavior from Ollama itself.

### Image Pinning

The Terraform variable `ollama_image_name` controls the deployed container image:

```bash
TF_VAR_ollama_image_name=ollama/ollama:latest make apply
```

Override this variable to pin a specific Ollama release or to deploy a custom wrapper image if you want to put a compatibility proxy in front of the native Ollama server.

## Telegram Notifications

To receive the deployment result in a Telegram channel:

1. Create a Telegram bot with [@BotFather](https://t.me/BotFather).
1. Add the bot to a private channel and promote it to admin so it can post messages.
1. Store these secrets in `pass`:
   - `telegram/bot_token`
   - `telegram/chat_id`
1. Run `make apply` as usual.

The notification includes:

- pod ID
- native Ollama API endpoint
- OpenAI-compatible API endpoint (marked experimental)
- model name

If you prefer to use environment variables directly, export `TF_VAR_telegram_bot_token` and `TF_VAR_telegram_chat_id` before running Terraform.

## GitHub Actions

Manual deployment is available through [`.github/workflows/runpod-pod.yml`](./.github/workflows/runpod-pod.yml).

Set this repository secret before running the workflow:

- `AWS_ROLE_TO_ASSUME` — IAM role ARN that GitHub Actions assumes with OIDC
- `RUNPOD_API_KEY` — RunPod API key used by the Terraform provider
- `TELEGRAM_BOT_TOKEN` — Telegram bot token used by Terraform to send the deployment message
- `TELEGRAM_CHAT_ID` — Telegram channel username or numeric chat ID for the message target

Then open the `RunPod Pod` workflow in GitHub Actions and choose one of:

- `plan`
- `apply`
- `destroy`

The workflow also accepts `ollama_model` and `use_spot` inputs, which map directly to the Terraform variables in this repo.

For `apply`, the workflow now requires the Telegram secrets too so the endpoint notification can be sent after the pod becomes ready.

GitHub Actions authenticates to AWS using OpenID Connect, so you no longer need long-lived AWS access key secrets in GitHub. You do need an IAM role in AWS that trusts `token.actions.githubusercontent.com` and is scoped to this repository.

`apply` and `destroy` use the protected GitHub Environment `runpod-production`. Configure required reviewers for that environment in GitHub before relying on those actions.

## Terraform Backend

Terraform state is stored in S3:

- Bucket: `terraform-state-421427265342-ap-southeast-1-runpod`
- Key: `runpod/terraform.tfstate`
- Region: `ap-southeast-1`

For local use, run Terraform with AWS credentials that can access that bucket, for example via `aws-vault exec`.

Example local AWS verification:

```bash
aws-vault exec toanvvsg -- aws sts get-caller-identity
```

Example OIDC role creation flow:

1. Create or confirm the GitHub OIDC provider exists in AWS.
2. Create an IAM role trusted by `token.actions.githubusercontent.com`.
3. Attach only the S3 and IAM permissions this Terraform stack needs.
4. Store the role ARN in GitHub as `AWS_ROLE_TO_ASSUME`.

## Cost

| Deployment | GPU | Cost | Scaling |
|------------|-----|------|---------|
| Pod (Ollama) | A100 80GB Community | ~$1.64/hr | Always on |
