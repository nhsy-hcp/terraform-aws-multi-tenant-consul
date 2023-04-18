.PHONY: all init deploy plan consul consul-admin consul-user consul-user-apigw consul-clean consul-admin-clean consul-user-clean destroy fmt clean

EKS_ADMIN_CLUSTER_NAME=`terraform output -raw eks_admin_cluster_name`
EKS_USER_CLUSTER_NAME=`terraform output -raw eks_user_cluster_name`
EKS_ADMIN_CLUSTER_CONTEXT=`terraform output -raw eks_admin_cluster_kube_context`
EKS_USER_CLUSTER_CONTEXT=`terraform output -raw eks_user_cluster_kube_context`
REGION=`terraform output -raw region`

all: deploy consul

init: fmt
	@aws sts get-caller-identity
	@terraform init

deploy: init
	@terraform apply -auto-approve
	@sleep 5
	@scripts/00-prereqs.sh
	@kubectl config use-context $(EKS_ADMIN_CLUSTER_CONTEXT)
	@kubectl config current-context

consul: consul-admin consul-user consul-user-apigw

consul-admin:
	@scripts/01-consul-admin-cluster-install.sh
	@echo Pausing for admin cluster consul initialisation
	@sleep 180

consul-user:
	@scripts/02-consul-user-cluster-install.sh
	@echo Pausing for user cluster consul initialisation
	@sleep 180

consul-user-apigw:
	@scripts/03-consul-user-cluster-apigw-install.sh
	@echo Pausing for user cluster API GW initialisation
	@sleep 180
	@scripts/04-consul-user-cluster-demo-install.sh

consul-clean: consul-user-clean consul-admin-clean

consul-admin-clean:
	-@helm uninstall --kube-context $(EKS_ADMIN_CLUSTER_CONTEXT) -n consul consul
	-@kubectl --context $(EKS_ADMIN_CLUSTER_CONTEXT) delete pvc -n consul -l chart=consul-helm
	-@kubectl --context $(EKS_ADMIN_CLUSTER_CONTEXT) delete namespace consul

consul-user-clean:
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete -f manifests/demo-echo-svc.yaml
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete -f manifests/demo-httproute.yaml
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete -f manifests/consul-apigw-cert.yaml
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete -f manifests/consul-api-gateway.yaml
	-@helm uninstall --kube-context $(EKS_USER_CLUSTER_CONTEXT) -n consul consul
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete pvc -n consul -l chart=consul-helm
	-@sleep 30
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete namespace consul

plan: init
	@terraform validate
	@terraform plan

destroy: init consul-clean
	@terraform destroy -auto-approve

fmt:
	@terraform fmt -recursive

clean:
	-rm -rf .terraform/
	-rm .terraform.lock.hcl
	-rm terraform.tfstate*
