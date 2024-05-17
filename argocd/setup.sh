kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl port-forward svc/argocd-server -n argocd 9000:80
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl apply -f argo/argo-ingress.yaml -n argocd
argocd login argocd.use1-poc-gke.srv.media.net:443 --grpc-web
argocd cluster add <CONTEXT_NAME>

#create a new user
kubectl get configmap argocd-cm -n argocd -o yaml > argocd-cm.yml 
#add new user inside data
kubectl apply -f argocd-cm.yml -n argocd
kubectl get configmap argocd-rbac-cm -n argocd -o yaml > argocd-rbac-cm.yml
#give the user authorization
kubectl apply -f argocd-rbac-cm.yml -n argocd
#update password for new user
argocd account update-password --account argocd --current-password argocd1234 --new-password argocd12345
#image-updater
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

#workflow
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.2/install.yaml


kubectl port-forward svc/argo-server -n argo 2746:2746
https://localhost:2746/

kubectl apply -n argo -f - argo/login-sa-token.yaml

kubectl create clusterrole argo-workflow-role --verb=list,get,update --resource=workflows.argoproj.io -n argo 
kubectl create sa argo-workflow-sa -n argo
kubectl create clusterrolebinding argo-workflow-crb --clusterrole=argo-workflow-role --serviceaccount=argo:argo-workflow-sa -n argo
kubectl apply -n argo -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: argo-workflow.service-account-token
  annotations:
    kubernetes.io/service-account.name: argo-workflow-sa
type: kubernetes.io/service-account-token
EOF
ARGO_TOKEN="Bearer $(kubectl get secret argo-workflow.service-account-token -o=jsonpath='{.data.token}' | base64 --decode)"
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=argo:default --namespace=argo
#

image-updater=BEARER_TOKEN
argocd-image-updater run --health-port 0 --metrics-port 0