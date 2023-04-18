set -e

EKS_ADMIN_CLUSTER_CONTEXT=$(terraform output -raw eks_admin_cluster_kube_context)
EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

echo
echo Install Consul in admin cluster
kubectl config use-context $EKS_ADMIN_CLUSTER_CONTEXT
kubectl config current-context

kubectl apply -f manifests/consul-namespace.yaml
kubectl apply -f manifests/consul-license.yaml
kubectl apply -f manifests/consul-bootstrap-acl-token.yaml

helm install consul hashicorp/consul -n consul --values manifests/consul-admin-cluster-values-v1.1.1.yaml --version=1.1.1 --dry-run
helm install consul hashicorp/consul -n consul --values manifests/consul-admin-cluster-values-v1.1.1.yaml --version=1.1.1 #--dry-run
kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
kubectl get all -n consul
echo

CONSUL_UI_LB=$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

while [[ "${CONSUL_UI_LB}" == "" ]]; do
  echo Waiting for Consul UI LB
  CONSUL_UI_LB=$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  sleep 10
done

CONSUL_UI_URL=https://$CONSUL_UI_LB

echo
echo  Consul UI: $CONSUL_UI_URL
echo

while [[ "$(curl -sIko /dev/null -w '%{http_code}' --connect-timeout 5 $CONSUL_UI_URL)" != "301" ]]; do
  echo Checking Consul UI ready...
  sleep 20
done

echo
echo Consul token:  $(kubectl --context $EKS_ADMIN_CLUSTER_CONTEXT get secrets/bootstrap-acl-token --template='{{.data.token | base64decode }}' -n consul)

echo
echo Consul install on admin cluster complete
