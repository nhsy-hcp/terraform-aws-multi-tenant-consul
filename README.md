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

### 3) Install Consul on EKS admin cluster
```
./scripts/consul-admin-cluster-install.sh
```
### 4) Install Consul on EKS user cluster
```
./scripts/consul-user-cluster-install.sh
```

### 5) Discover Admin Cluster Consul UI URL
```
echo https://$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

```
Don't forget to log in using the supplied bootstrap token
`61f69a27-028d-ad76-e4e5-b538334caf3e`

### 6) Install API gateway and the Service #TODO
```
./scripts/consul-user-cluster-apigw-install.sh
```

Check the UI and add required intentions (Go Partitions>part1 Namespaces>consul Services>api-gateway)

### 7) Discovering the API GW ELB #TODO
echo https://$(kubectl --context $EKS_USER_CLUSTER_CONTEXT get svc -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')

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
