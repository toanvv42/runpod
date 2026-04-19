TF_VAR_runpod_api_key := $(shell pass apikey/runpod)
export TF_VAR_runpod_api_key

.PHONY: init plan apply destroy output

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

output:
	terraform output
