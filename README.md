# terraform-aws-multi-tenant-consul
A lab setup for experimenting with Consul partitions on AWS EKS.

The follow AWS resources are deployed:
- 1x VPC
- 2x EKS clusters (admin cluster, user cluster) - addons installed Amazon EBS CSI Driver, Amazon VPC CNI
- 1x primary partition (default) on admin cluster
- 1x non-primary partition (part1) on user cluster
- Security groups - required for Consul intra cluster communications
- AWS Load Balancer Controller - installed on admin and user clusters, required for Consul API Gateway
- CloudWatch Logging - Useful EKS debugging

All EC2 instances are Spot to keep costs down.

If deploying a large number of pods then remember this is limited by the EC2 instance size.
You can use the script `./scripts/max-pods-calculator.sh` to calculate max pods.

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

### Install API gateway and demo
```
make consul-user-apigw
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

### Curl testing echo server
```
kubectl --context $EKS_USER_CLUSTER_CONTEXT run curltesting --image=curlimages/curl --restart=Never --command -ti --rm -- curl -kv --connect-timeout 5 http://[SVC IP]:8080
```
