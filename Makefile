.PHONY: all apply plan destroy fmt

all: fmt plan apply

apply:
	@terraform init
	@terraform apply

plan:
	@terraform init
	@terraform validate
	@terraform plan

destroy:
	@terraform init
	@terraform destroy

fmt:
	@terraform fmt -recursive
