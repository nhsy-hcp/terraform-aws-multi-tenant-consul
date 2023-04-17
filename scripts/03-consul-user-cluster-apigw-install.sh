set -e

EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

echo
echo Install Consul API Gateway on user cluster

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/consul-apigw-cert.yaml
kubectl apply -f manifests/consul-api-gateway.yaml
