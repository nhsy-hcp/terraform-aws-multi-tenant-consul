.PHONY: all init apply plan destroy fmt clean

all: apply

init:
	@terraform init

apply: fmt init
	@terraform apply -auto-approve
	@aws eks --region `terraform output -raw region` update-kubeconfig --name `terraform output -raw eks_admin_cluster_name`
	@kubectl rollout restart deployment ebs-csi-controller -n kube-system
	@-cp consul-admin-cluster.tf.tpl consul-admin-cluster.tf
	@terraform apply -auto-approve

plan: fmt init
	@terraform validate
	@terraform plan

destroy: init
	-@rm consul-admin-cluster.tf
	@terraform destroy -auto-approve -target helm_release.consul_admin_cluster
	@terraform destroy -auto-approve -target module.eks_admin_cluster
	@terraform destroy -auto-approve

fmt:
	@terraform fmt -recursive

clean:
	-rm -rf .terraform/
	-rm .terraform.lock.hcl
	-rm terraform.tfstate*
	-rm consul-admin-cluster.tf
