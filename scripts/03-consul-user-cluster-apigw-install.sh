set -e

EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

echo
echo Install Consul API Gateway on user cluster

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/consul-apigw-cert.yaml
kubectl apply -f manifests/consul-api-gateway.yaml

## Wait for API Gateway service
APIGW_SVC=$(kubectl get svc api-gateway --context $EKS_USER_CLUSTER_CONTEXT -n consul)

while [[ "${APIGW_SVC}" == "" ]]; do
  echo Waiting for Consul API Gateway service
  APIGW_SVC=$(kubectl get svc api-gateway --context $EKS_USER_CLUSTER_CONTEXT -n consul)
  sleep 10
done

echo
echo Consul API Gateway deployment complete
