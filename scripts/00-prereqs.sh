set -e

EKS_ADMIN_CLUSTER_CONTEXT=`terraform output -raw eks_admin_cluster_kube_context`
EKS_USER_CLUSTER_CONTEXT=`terraform output -raw eks_user_cluster_kube_context`

aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_admin_cluster_name)
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_user_cluster_name)

kubectl --context $EKS_ADMIN_CLUSTER_CONTEXT cluster-info
kubectl --context $EKS_USER_CLUSTER_CONTEXT cluster-info
