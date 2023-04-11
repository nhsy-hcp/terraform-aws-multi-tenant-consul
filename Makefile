.PHONY: all init deploy plan consul consul-admin consul-user consul-clean destroy fmt clean

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
	@aws eks --region $(REGION) update-kubeconfig --name $(EKS_ADMIN_CLUSTER_NAME)
	#@kubectl rollout restart deployment ebs-csi-controller -n kube-system
	@kubectl cluster-info
	-@aws eks --region $(REGION) update-kubeconfig --name $(EKS_USER_CLUSTER_NAME)
	-@kubectl rollout restart deployment ebs-csi-controller -n kube-system
	-@kubectl cluster-info
	-@kubectl config use-context $(EKS_ADMIN_CLUSTER_CONTEXT)
	-@kubectl config current-context
	@sleep 5

consul: consul-admin #consul-user

consul-admin:
	@cp consul-admin-cluster.tf.tpl consul-admin-cluster.tf
	@terraform init
	@terraform apply -auto-approve
	@kubectl config use-context $(EKS_ADMIN_CLUSTER_CONTEXT)
	@kubectl config current-context
	@kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
	@kubectl get all -n consul
	@sleep 5

consul-user:
	# TODO
	@kubectl config use-context $(EKS_USER_CLUSTER_CONTEXT)
	@kubectl config current-context
	@kubectl get all -n consul

consul-clean:
	-@helm uninstall --kube-context $(EKS_ADMIN_CLUSTER_CONTEXT) -n consul consul
	-@helm uninstall --kube-context $(EKS_USER_CLUSTER_CONTEXT) -n consul consul
	-@kubectl --context $(EKS_ADMIN_CLUSTER_CONTEXT) delete pvc -n consul -l chart=consul-helm
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete pvc -n consul -l chart=consul-helm
	-@kubectl --context $(EKS_ADMIN_CLUSTER_CONTEXT) delete namespace consul
	-@kubectl --context $(EKS_USER_CLUSTER_CONTEXT) delete namespace consul

plan: init
	@terraform validate
	@terraform plan

destroy: init consul-clean
	-@rm consul-admin-cluster.tf
	@terraform destroy -auto-approve

fmt:
	@terraform fmt -recursive

clean:
	-rm -rf .terraform/
	-rm .terraform.lock.hcl
	-rm terraform.tfstate*
	-rm consul-admin-cluster.tf
