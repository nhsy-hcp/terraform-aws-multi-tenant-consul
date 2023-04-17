# terraform-aws-multi-tenant-consul
A lab setup for experimenting with Consul partitions on AWS EKS.

The follow AWS resources are deployed:
- 1x VPC
- 2x EKS clusters (admin cluster, user cluster)
- 1x primary partition (default) on admin cluster
- 1x non-primary partition (part1) on user cluster

## Pre-Requisites
### Setup and test your AWS CLI credentials:
```
aws sts get-caller-identity
```
### Add licence 
Copy manifests/consul-license-template.yaml to manifests/consul-license.yaml and add license.
```
cp manifests/consul-license-template.yaml manifests/consul-license.yaml
```
Replace <LICENSE_BASE64_ENCODED> with base64 encoded license

### Add AWS Account ID 
Copy terraform.tfvars.example to terraform.tfvars
```
cp terraform.tfvars.example terraform.tfvars
```
Replace <AWS_ACCOUNT_ID> with AWS account ID.

## Automated install
### Create EKS admin + user clusters and install consul:
```
make all
```
Continue user cluster consul installation from step 4) Copy Secrets and prepare to user cluster.

## Step by Step install
### Create EKS admin + user clusters 
```
make deploy
```
### Install consul on admin cluster
```
make consul-admin
```

### Install consul on user cluster
```
make consul-user
```

### Discover Admin Cluster Consul UI URL
```
echo https://$(kubectl get svc --context $EKS_ADMIN_CLUSTER_CONTEXT -n consul consul-ui --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```
Consul logon token `61f69a27-028d-ad76-e4e5-b538334caf3e`

### Install API gateway and TLS cert
```
./scripts/03-consul-user-cluster-apigw-install.sh
```
Check the UI and add required intentions (Go Partitions>part1 Namespaces>consul Services>api-gateway)

### Install demo echoserver
```
./scripts/04-consul-user-cluster-demo-install.sh
```

### Discovering the API Gateway ELB
```
echo https://$(kubectl --context $EKS_USER_CLUSTER_CONTEXT get svc -n consul api-gateway --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Testing
### Shell setup
Use the following example to export environment variables and execute `kubectl` cli commands
```
source .env
kubectl --context $EKS_ADMIN_CLUSTER_CONTEXT get pods
kubectl --context $EKS_USER_CLUSTER_CONTEXT get pods
```

## Cleanup
### Automated destroy
```
make destroy
```
### Uninstall consul only
```
make consul-clean
```

## Troubleshooting
### CloudWatch EKS Control Plane logs
Logging has been enabled as per the documentation below
https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html

### Demo echo server
```
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4 --port=8080 --replicas=3
kubectl expose deployment hello-minikube --type=LoadBalancer
kubectl get pods
kubectl get svc
```