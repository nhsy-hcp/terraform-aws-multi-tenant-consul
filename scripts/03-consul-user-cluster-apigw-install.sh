set -e

EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

echo
echo Install Consul API Gateway on user cluster

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/consul-apigw-cert.yaml
kubectl apply -f manifests/consul-api-gateway.yaml

## Wait for API Gateway service
kubectl wait --context $EKS_USER_CLUSTER_CONTEXT -n consul --for=condition=ready gateway/api-gateway --timeout=90s

# Wait for API Gateway pod
kubectl wait --context $EKS_USER_CLUSTER_CONTEXT -n consul --for=condition=ready pod -l api-gateway.consul.hashicorp.com/name=api-gateway --timeout=90s

# Wait for API Gateway LB
APIGW_LB=$(kubectl get svc --context $EKS_USER_CLUSTER_CONTEXT -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

while [[ "${APIGW_LB}" == "" ]]; do
  echo Waiting for Consul UI LB
  APIGW_LB=$(kubectl get svc --context $EKS_USER_CLUSTER_CONTEXT -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  sleep 10
done

echo
echo Consul API Gateway deployment complete
