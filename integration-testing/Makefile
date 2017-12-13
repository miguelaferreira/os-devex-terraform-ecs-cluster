.PHONY: all plan apply destroy

variable_flags = -var-file secrets.tfvars
plan_file = terraform.tfplan

all: init plan apply

init:
	terraform init -upgrade=true

update:
	terraform get --update

plan:
	terraform plan -out $(plan_file) $(variable_flags)

apply:
	terraform apply $(plan_file)

destroy:
	terraform plan -destroy -out $(plan_file) $(variable_flags)
