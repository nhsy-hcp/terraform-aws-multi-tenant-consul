set -e

EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/demo-echo-svc.yaml
kubectl apply -f manifests/demo-httproute.yaml
