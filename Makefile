SHELL := /usr/bin/env bash
TF_DIR := terraform
PLAN_OUT := plan.out
PLAN_JSON := plan.json

.PHONY: init plan plan-json test apply destroy

init:
	cd $(TF_DIR) && terraform init -upgrade

plan:
	cd $(TF_DIR) && terraform plan -out $(PLAN_OUT)

plan-json: plan
	cd $(TF_DIR) && terraform show -json $(PLAN_OUT) > $(PLAN_JSON)
	@echo "Wrote $(TF_DIR)/$(PLAN_JSON)"

test: plan-json
	conftest test $(TF_DIR)/$(PLAN_JSON) --policy policies/tfplan

apply:
	cd $(TF_DIR) && terraform apply $(PLAN_OUT)

destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve
