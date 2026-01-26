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


## Env 

Perfect — let’s do this **step by step in practice**. We’ll take your `base/values.yaml` and create **dev and prod overrides** so you can have different image tags for each environment.

---

# 1️⃣ Base values.yaml (`apps/frontend/base/values.yaml`)

Example `values.yaml` in your base chart:

```yaml
replicaCount: 2

image:
  repository: devopsflow999/frontend
  tag: main-123   # default, we will override in dev/prod
  pullPolicy: IfNotPresent

service:
  port: 80

istio:
  host: frontend.localdev.me
  gateway: frontend-gateway

env:
  VITE_STRIPE_KEY: ""
```

---

# 2️⃣ Create dev override (`apps/frontend/overlays/dev/values-dev.yaml`)

```yaml
image:
  tag: dev-001   # override only the tag for dev
replicaCount: 1   # optional: fewer replicas for dev
env:
  VITE_STRIPE_KEY: "dev_stripe_key_123"
```

---

# 3️⃣ Create prod override (`apps/frontend/overlays/prod/values-prod.yaml`)

```yaml
image:
  tag: main-999   # override only the tag for prod
replicaCount: 3   # more replicas for prod
env:
  VITE_STRIPE_KEY: "prod_stripe_key_999"
```

---

# 4️⃣ Render Helm templates into overlay YAMLs

### For Dev:

```bash
cd apps/frontend/base
helm template frontend . -f values.yaml -f ../overlays/dev/values-dev.yaml -n demo > ../overlays/dev/frontend.yaml
```

### For Prod:

```bash
cd apps/frontend/base
helm template frontend . -f values.yaml -f ../overlays/prod/values-prod.yaml -n demo > ../overlays/prod/frontend.yaml
```

✅ After this:

* `frontend.yaml` in `dev` → uses `image: devopsflow999/frontend:dev-001`
* `frontend.yaml` in `prod` → uses `image: devopsflow999/frontend:main-999`

---

# 5️⃣ Kustomize overlay

Your `apps/frontend/overlays/dev/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: demo

resources:
  - frontend.yaml
  - frontend-secrets.yaml
```

And same for `prod/kustomization.yaml`, just pointing to the **prod frontend.yaml**.

---

# ✅ 6️⃣ Test with Kustomize

```bash
cd apps/frontend/overlays/dev
kustomize build .
```

* Check `image:` in the Rollout → should be `devopsflow999/frontend:dev-001`
* Same for prod overlay → should be `main-999`

---

Ah! Perfect — now we’ll make dev and prod overlays have their own namespaces too, so each environment is isolated. I’ll guide you step by step.

1️⃣ Decide namespaces

dev overlay → namespace: dev

prod overlay → namespace: prod

You can create namespaces manually or via Kustomize. Let’s do it with Kustomize, so ArgoCD can create them automatically.

2️⃣ Create namespace YAMLs
Dev namespace (apps/frontend/overlays/dev/namespace-dev.yaml)
apiVersion: v1
kind: Namespace
metadata:
  name: dev

Prod namespace (apps/frontend/overlays/prod/namespace-prod.yaml)
apiVersion: v1
kind: Namespace
metadata:
  name: prod

3️⃣ Update Kustomization files
Dev (apps/frontend/overlays/dev/kustomization.yaml)
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace-dev.yaml
  - frontend.yaml
  - frontend-secrets.yaml

namespace: dev   # this applies to all resources except Namespace itself

Prod (apps/frontend/overlays/prod/kustomization.yaml)
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace-prod.yaml
  - frontend.yaml
  - frontend-secrets.yaml

namespace: prod   # applies to all resources except Namespace itself


✅ This way:

All resources in dev overlay go to dev namespace

All resources in prod overlay go to prod namespace

Namespaces themselves are created first

4️⃣ Render Helm templates with namespace

When you run helm template:

Dev:
cd apps/frontend/base
helm template frontend . -f values.yaml -f ../overlays/dev/values-dev.yaml -n dev > ../overlays/dev/frontend.yaml

Prod:
cd apps/frontend/base
helm template frontend . -f values.yaml -f ../overlays/prod/values-prod.yaml -n prod > ../overlays/prod/frontend.yaml


The -n dev or -n prod ensures the rendered Rollout, Services, Gateway, etc., are in the correct namespace.

5️⃣ Test with Kustomize
cd apps/frontend/overlays/dev
kustomize build .


Check:

namespace: dev is applied to Rollout, Services, Gateway, VS, Secret

Namespace object itself is unchanged (name: dev)

Do the same for prod → resources should be in namespace prod.

