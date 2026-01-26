🧭 BIG PICTURE (read once)
ArgoCD Application
   ↓
Kustomize (overlay/dev)
   ↓
Helm Chart (catalog)
   ↓
Kubernetes (namespace: demo)


## check 
pwd
/home/ironops/Desktop/Mega-Project/gitops/apps/catalog/base
➜  base git:(main) ✗ helm template catalog .