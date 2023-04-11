A lab setup for experimenting with Consul partitions on AWS EKS.

The setup includes:
- one VPC
- two EKS clusters (admin cluster, user cluster)
- non-primary partition (part1)

## Pre-Requisites
### 1) Test your AWS CLI credentials:
```
aws sts get-caller-identity
```
### 2) Add licence 
Copy manifests/consul-license-template.yaml to manifests/consul-license.yaml and add license.
```
cp manifests/consul-license-template.yaml manifests/consul-license.yaml
```
Replace <LICENSE_BASE64_ENCODED> with base64 encoded license

### 3) Add AWS Account ID 
Copy terraform.tfvars.example to terraform.tfvars
```
cp terraform.tfvars.example terraform.tfvars
```
Replace <AWS_ACCOUNT_ID> with AWS account ID.

## Fully automated install #TODO
### 1) Create EKS admin + user clusters and install consul:
```
make all
```
Continue user cluster consul installation from step 4) Copy Secrets and prepare to user cluster.

## Partially automated
### 1) Create EKS admin + user clusters 
```
make deploy
```
### 2) Configure the kubernetes contexts:
```
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_admin_cluster_name)
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_user_cluster_name)

export EKS_ADMIN_CLUSTER_CONTEXT=$(terraform output -raw eks_admin_cluster_kube_context)
export EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)
```

### 3) Install Consul in EKS admin cluster
```
kubectl config use-context $EKS_ADMIN_CLUSTER_CONTEXT
kubectl config current-context

kubectl apply -f manifests/consul-namespace.yaml
kubectl apply -f manifests/consul-license.yaml
kubectl apply -f manifests/consul-bootstrap-token.yaml
kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.3"

helm install consul hashicorp/consul -n consul --values manifests/consul-admin-cluster-values-v1.0.6.yaml --version=1.0.6
kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
kubectl get all -n consul
```
### 4) Copy Secrets and prepare to user cluster
```
kubectl config use-context $EKS_ADMIN_CLUSTER_CONTEXT
kubectl config current-context
kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -f manifests/consul-namespace.yaml
kubectl get secret -n consul consul-ca-cert -o yaml | kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -n consul -f -
kubectl get secret -n consul consul-ca-key -o yaml | kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -n consul -f -
kubectl get secret -n consul consul-gossip-encryption-key -o yaml | kubectl --context $EKS_USER_CLUSTER_CONTEXT apply -n consul -f -

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT
kubectl config current-context
kubectl apply -f manifests/consul-license.yaml
kubectl apply -f manifests/consul-bootstrap-token.yaml
kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.3"
```

### 6) Update consul-user-cluster-values.yaml with correct URLs
```
export EKS_USER_CLUSTER_K8S_LB=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$EKS_USER_CLUSTER_CONTEXT\")].cluster.server}")
export EKS_ADMIN_CLUSTER_CONSUL_LB=$(kubectl --context $EKS_ADMIN_CLUSTER_CONTEXT get svc -n consul consul-expose-servers --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo EKS_USER_CLUSTER_K8S_LB: $EKS_USER_CLUSTER_K8S_LB
echo EKS_ADMIN_CLUSTER_CONSUL_LB: $EKS_ADMIN_CLUSTER_CONSUL_LB

sed -e "s|<EKS_USER_CLUSTER_K8S_LB>|${EKS_USER_CLUSTER_K8S_LB}|g" -e "s|<EKS_ADMIN_CLUSTER_CONSUL_LB>|${EKS_ADMIN_CLUSTER_CONSUL_LB}|g" manifests/consul-user-cluster-values-template-v1.0.6.yaml > manifests/consul-user-cluster-values.yaml
cat manifests/consul-user-cluster-values.yaml
```
### 7) Install Consul in user cluster
```
helm install consul hashicorp/consul -n consul --values manifests/consul-user-cluster-values.yaml --version=1.0.6 --dry-run
helm install consul hashicorp/consul -n consul --values manifests/consul-user-cluster-values.yaml --version=1.0.6
kubectl wait --for=condition=ready pod --all --namespace consul --timeout=120s
kubectl get all -n consul
```

### 10) Discovering cluster-a Consul UI URL #TODO
```
echo "ADMIN CLUSTER LB:" $(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo https://$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -skv https://$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```
Don't forget to log in using the supplied bootstrap token
`61f69a27-028d-ad76-e4e5-b538334caf3e`


### 11) Installing the API gateway and the Service #TODO

kubectl config use-context $EKS_USER_CLUSTER_CONTEXT

kubectl apply -f manifests/consul-apigw-cert.yaml 
kubectl apply -f manifests/consul-api-gateway.yaml
kubectl apply -f manifests/demo-echo-svc.yaml
kubectl apply -f manifests/demo-httproute.yaml

Check the UI and add required intentions (Go Partitions>part1 Namespaces>consul Services>api-gateway)

### 12) Discovering the API GW ELB #TODO
echo https://$(kubectl --context $EKS_USER_CLUSTER_CONTEXT get svc -n consul  | grep api-gateway | awk '{print $4}')

## Cleanup
### Fully Automated
```
make destroy
```
### Manual #TODO
```
kubectl config use-context $CLUSTER_B_CONTEXT
kubectl delete -f example-echo-svc.yaml
kubectl delete -f consul-apigw-cert.yaml 
kubectl delete -f api-gateway.yaml
kubectlk delete -f httproute.yaml

helm uninstall consul -n consul
kubectl config use-context $CLUSTER_A_CONTEXT
helm uninstall consul -n consul
kubectl delete pvc -n consul -l chart=consul-helm
terraform destroy
```