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

After a successful `apply`, the pod endpoint is sent to Telegram if `telegram_bot_token` and `telegram_chat_id` are set. The endpoint is no longer printed in the default Terraform output.

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
- Ollama endpoint
- model name

If you prefer to use environment variables directly, export `TF_VAR_telegram_bot_token` and `TF_VAR_telegram_chat_id` before running Terraform.

## GitHub Actions

Manual deployment is available through [`.github/workflows/runpod-pod.yml`](./.github/workflows/runpod-pod.yml).

Set this repository secret before running the workflow:

- `AWS_ACCESS_KEY_ID` — IAM access key for the Terraform S3 backend user
- `AWS_SECRET_ACCESS_KEY` — IAM secret key for the Terraform S3 backend user
- `RUNPOD_API_KEY` — RunPod API key used by the Terraform provider
- `TELEGRAM_BOT_TOKEN` — Telegram bot token used by Terraform to send the deployment message
- `TELEGRAM_CHAT_ID` — Telegram channel username or numeric chat ID for the message target

Then open the `RunPod Pod` workflow in GitHub Actions and choose one of:

- `plan`
- `apply`
- `destroy`

The workflow also accepts `ollama_model` and `use_spot` inputs, which map directly to the Terraform variables in this repo.

For `apply`, the workflow now requires the Telegram secrets too so the endpoint notification can be sent after the pod becomes ready.

`apply` and `destroy` use the protected GitHub Environment `runpod-production`. Configure required reviewers for that environment in GitHub before relying on those actions.

## Terraform Backend

Terraform state is stored in S3:

- Bucket: `terraform-state-421427265342-ap-southeast-1-runpod`
- Key: `runpod/terraform.tfstate`
- Region: `ap-southeast-1`

For local use, run Terraform with AWS credentials that can access that bucket, for example via `aws-vault exec`.

## Cost

| Deployment | GPU | Cost | Scaling |
|------------|-----|------|---------|
| Pod (Ollama) | A100 80GB Community | ~$1.64/hr | Always on |
