EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

echo Consul token:  $(kubectl --context $EKS_ADMIN_CLUSTER_CONTEXT get secrets/bootstrap-acl-token --template='{{.data.token | base64decode }}' -n consul)
