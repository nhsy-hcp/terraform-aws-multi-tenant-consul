A lab setup for experimenting with Consul partitions on AWS EKS (EC2).
The setup includes:
- one VPC
- two EKS clusters (one with servers, another with clients)
- non-primary partition (part1)


### 1) Test your AWS CLI credentials:
```
aws sts get-caller-identity
```
### 2) Create EKS clusters:
```
terraform init
terraform apply
```
### 3) Configure the kubernetes contexts:
```
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_admin_cluster_name)
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw eks_user_cluster_name)

export EKS_ADMIN_CLUSTER_CONTEXT=$(terraform output -raw eks_admin_cluster_kube_context)
export EKS_USER_CLUSTER_CONTEXT=$(terraform output -raw eks_user_cluster_kube_context)
```
### 4) Add a license into license.yaml

### 5) Install Consul in EKS admin cluster
```
kubectl config use-context $EKS_ADMIN_CLUSTER_CONTEXT
kubectl config current-context

# kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=$(terraform output -raw iam_ebs_csi_controller_role_eks_admin_cluster)
kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=$(terraform output -raw ebs_csi_irsa_role_eks_admin_cluster_iam_role_arn)
kubectl rollout restart deployment ebs-csi-controller -n kube-system

kubectl apply -f k8s/consul-namespace.yaml
kubectl apply -f k8s/consul-license.yaml
kubectl apply -f k8s/consul-bootstrap-token.yaml
kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.3"

helm install consul hashicorp/consul -n consul --values k8s/consul-admin-values-v1.0.6.yaml --version=1.0.6
watch -d -n3 kubectl get all -n consul 
```
### 6) Copy Secrets to cluster-b
```
kubectl --context $CLUSTER_B_CONTEXT create namespace consul
kubectl get secret -n consul consul-ca-cert -o yaml | kubectl --context $CLUSTER_B_CONTEXT apply -n consul -f -
kubectl get secret -n consul consul-ca-key -o yaml | kubectl --context $CLUSTER_B_CONTEXT apply -n consul -f -
kubectl get secret -n consul consul-gossip-encryption-key -o yaml | kubectl --context $CLUSTER_B_CONTEXT apply -n consul -f -
```
### 7) Prepare cluster-b
```
kubectl config use-context $CLUSTER_B_CONTEXT
kubectl config current-context
kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=$(terraform output -raw iam_ebs_csi_controller_role_cluster-b)
kubectl rollout restart deployment ebs-csi-controller -n kube-system

kubectl apply -f license.yaml
kubectl apply -f bootstrap-token.yaml
kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.3"
```

### 8) Update consul_values_b.yaml with correct URLs
```
export CLUSTER_B_EKS_ENDPOINT=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$CLUSTER_B_CONTEXT\")].cluster.server}")
export CLUSTER_A_CONSUL_LB=$(kubectl --context $CLUSTER_A_CONTEXT get svc -n consul | grep consul-expose-servers | awk '{print $4}')
sed -e "s|<cluster-b_eks_api_endpoint>|${CLUSTER_B_EKS_ENDPOINT}|g" -e "s|<cluster-a_external_server_lb>|${CLUSTER_A_CONSUL_LB}|g" consul_values_b_template.yaml > consul_values_b.yaml
```
### 9) Install Consul in cluster-b
```
helm install consul hashicorp/consul -n consul --values consul_values_b.yaml --version=1.0.6
```

### 10) Discovering cluster-a Consul UI URL
```
echo "ADMIN CLUSTER LB:" $(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo https://$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -skv https://$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```
Don't forget to log in using the supplied bootstrap token
61f69a27-028d-ad76-e4e5-b538334caf3e


### 11) Installing the API gateway and the Service

kubectl config use-context $CLUSTER_B_CONTEXT

kubectl apply -f example-echo-svc.yaml
kubectl apply -f consul-apigw-cert.yaml 
kubectl apply -f api-gateway.yaml
kubectl apply -f httproute.yaml

Check the UI and add required intentions (Go Partitions>part1 Namespaces>consul Services>api-gateway)

### 12) Discovering the API GW ELB
echo https://$(kubectl --context $CLUSTER_B_CONTEXT get svc -n consul  | grep api-gateway | awk '{print $4}')


### 13) Hitting the issue

Example:
 % curl https://ae9b60f68add241838c28a94527b41d0-2131983789.eu-north-1.elb.amazonaws.com 
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to ae9b60f68add241838c28a94527b41d0-2131983789.eu-north-1.elb.amazonaws.com:443 

k logs -n consul consul-api-gateway-controller-7c46769655-nv7qf
2023-04-03T16:29:14.332Z [ERROR] envoy/middleware.go:84: consul-api-gateway-server.sds-server: error parsing spiffe path, skipping: error="invalid spiffe path" path=/ap/part1/ns/consul/dc/dc1/svc/api-gateway

% k logs -n consul api-gateway-77b9cff68d-pq69m 
{"timestamp":"2023-04-03 16:31:38.551","thread":"13","level":"warning","name":"config","source":"./source/common/config/grpc_stream.h:160","message":"StreamSecrets gRPC config stream closed: 16, unable to authenticate request"}

### 14) Deleting everything

kubectl config use-context $CLUSTER_B_CONTEXT
kubectl delete -f example-echo-svc.yaml
kubectl delete -f consul-apigw-cert.yaml 
kubectl delete -f api-gateway.yaml
kubectlk delete -f httproute.yaml

helm uninstall consul -n consul
kubectl config use-context $CLUSTER_A_CONTEXT
helm uninstall consul -n consul

terraform destroy


