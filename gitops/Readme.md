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

## build catalog
 kustomize build .


## new tp !

create files whith helm charts 

then :

helm template frontend . -f values.yaml -n demo > ../overlays/dev/frontend.yaml

This creates a single YAML including Rollout, Services, VS, Gateway, ConfigMap

Overlay kustomization.yaml will point to:

resources:
  - frontend.yaml
  - frontend-sealedsecret.yaml

After this, frontend overlay works exactly like catalog.

Test locally : 

cd apps/frontend/overlays/dev
kustomize build .
