kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4 --port=8080 --replicas=3
kubectl expose deployment hello-minikube --type=LoadBalancer
kubectl get pods
kubectl get svc