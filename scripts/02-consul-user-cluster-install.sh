set -e

#aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_admin_cluster_name)
#aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_user_cluster_name)

EKS_ADMIN_CLUSTER_CONTEXT=$(terraform output -raw eks_admin_cluster_kube_context)
EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)

echo
echo Install Consul in user cluster
kubectl config use-context $EKS_ADMIN_CLUSTER_CONTEXT
kubectl config current-context
kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -f manifests/consul-namespace.yaml
kubectl get secret -n consul consul-ca-cert -o yaml | kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -n consul -f -
kubectl get secret -n consul consul-ca-key -o yaml | kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -n consul -f -
kubectl get secret -n consul consul-gossip-encryption-key -o yaml | kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -n consul -f -

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT
kubectl config current-context
kubectl apply -f manifests/consul-license.yaml
kubectl apply -f manifests/consul-bootstrap-acl-token.yaml

EKS_USER_CLUSTER_K8S_LB=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$EKS_USER_CLUSTER_CONTEXT\")].cluster.server}")
EKS_ADMIN_CLUSTER_CONSUL_LB=$(kubectl --context $EKS_ADMIN_CLUSTER_CONTEXT get svc -n consul consul-expose-servers --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo
echo EKS_USER_CLUSTER_K8S_LB: $EKS_USER_CLUSTER_K8S_LB
echo EKS_ADMIN_CLUSTER_CONSUL_LB: $EKS_ADMIN_CLUSTER_CONSUL_LB
echo
sed -e "s|<EKS_USER_CLUSTER_K8S_LB>|${EKS_USER_CLUSTER_K8S_LB}|g" -e "s|<EKS_ADMIN_CLUSTER_CONSUL_LB>|${EKS_ADMIN_CLUSTER_CONSUL_LB}|g" manifests/consul-user-cluster-values-template-v1.1.1.yaml > manifests/consul-user-cluster-values.yaml

kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.3"
helm install consul hashicorp/consul -n consul --values manifests/consul-user-cluster-values.yaml --version=1.1.1 --dry-run
helm install consul hashicorp/consul -n consul --values manifests/consul-user-cluster-values.yaml --version=1.1.1
kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
kubectl get all -n consul

echo
echo Consul install on user cluster complete