set -e

EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/demo-echo-svc.yaml
kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
kubectl apply -f manifests/demo-httproute.yaml

# wait for api gateway pod ready status
kubectl wait --for=condition=ready pod -l api-gateway.consul.hashicorp.com/name=api-gateway --namespace consul --timeout=120s

APIGW_LB=$(kubectl get svc --context $EKS_USER_CLUSTER_CONTEXT -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

while [[ "${APIGW_LB}" == "" ]]; do
  echo Waiting for Consul UI LB
  APIGW_LB=$(kubectl get svc --context $EKS_USER_CLUSTER_CONTEXT -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  sleep 10
done

echo
echo  Demo URL: https://${APIGW_LB}/echo
echo

DEMO_URL=https://${APIGW_LB}/echo

while [[ "$(curl -sIko /dev/null -w '%{http_code}' --connect-timeout 5 $DEMO_URL)" != "200" ]]; do
  echo Checking Demo URL ready...
  sleep 20
done

echo
echo Demo deployment complete