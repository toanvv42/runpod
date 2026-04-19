TF_VAR_runpod_api_key := $(shell pass apikey/runpod)
export TF_VAR_runpod_api_key
TF_VAR_telegram_bot_token := $(shell pass telegram/bot_token 2>/dev/null)
export TF_VAR_telegram_bot_token
TF_VAR_telegram_chat_id := $(shell pass telegram/chat_id 2>/dev/null)
export TF_VAR_telegram_chat_id

AWS_REGION ?= ap-southeast-1
export AWS_REGION

.PHONY: init plan apply destroy output

.terraform/.init-done: runpod.tf
	terraform init -input=false
	@touch $@

init: .terraform/.init-done

plan: .terraform/.init-done
	terraform plan

apply: .terraform/.init-done
	terraform apply

destroy: .terraform/.init-done
	terraform destroy

output: .terraform/.init-done
	terraform output
