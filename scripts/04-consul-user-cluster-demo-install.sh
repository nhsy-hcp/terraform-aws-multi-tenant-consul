set -e

EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/demo-echo-svc.yaml
kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
kubectl apply -f manifests/demo-httproute.yaml

APIGW_LB=$(kubectl get svc --context $EKS_USER_CLUSTER_CONTEXT -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo
echo  Demo URL: https://${APIGW_LB}/echo
echo

DEMO_URL=https://${APIGW_LB}/echo

# Wait for demo url
#while [[ "$(curl -sIko /dev/null -w '%{http_code}' --connect-timeout 5 $DEMO_URL)" != "200" ]]; do
while [[ "$(curl -sk --connect-timeout 5 $DEMO_URL)" == "" ]]; do
  echo Checking Demo URL ready...
  sleep 20
done

echo
echo Demo deployment complete
