## infra kafka postgres debezium kafka ui redis  using docker compose 




## ➜ curl -X POST http://localhost:8083/connectors \
     -H "Content-Type: application/json" \
     -d @pg-connector.json


## ➜  curl http://localhost:8083/connectors/pg-auth-catalog-orders/status



curl -X POST http://localhost:3001 \  -H "Content-Type: application/json" \
  -d '{                              
    "name": "Sony WH‑1000XM5 Headphones",
    "description": "Industry‑leading noise‑canceling wireless headphones.",
    "price": 399.99,
    "image_url": "https://m.media-amazon.com/images/I/71o8Q5XJS5L._AC_SL1500_.jpg"
  }'

### Product 2 - Nintendo Switch OLED
curl -X POST http://localhost:3001 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nintendo Switch OLED",
    "description": "Handheld gaming console with OLED screen.",
    "price": 349.99,
    "image_url": "https://cdn.cloudflare.steamstatic.com/steam/apps/1627270/header.jpg"
  }'

##   update :

  curl -X PUT http://localhost:3001/products/7 \
-H "Content-Type: application/json" \
-d '{
  "name": "Nintendo Switch OLED",
  "description": "Handheld gaming console with OLED screen.",
  "price": 329.99,
  "image_url": "https://cdn.cloudflare.steamstatic.com/steam/apps/1627270/header.jpg"
}'

{"id":7,"name":"Nintendo Switch OLED","description":"Handheld gaming console with OLED screen.","price":"329.99","image_url":"https://cdn.cloudflare.steamstatic.com/steam/apps/1627270/header.jpg","created_at":"2026-01-21T17:37:17.419Z"}% 

## delete 

curl -X DELETE http://localhost:3001/products/7
## installing prometheus 

mkdir -p ~/prometheus
nano ~/prometheus/prometheus.yml


**proemthes.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'catalog-service'
    static_configs:
      - targets: ['host.docker.internal:9464']  ## make ip of docker : ip addr show docker0

docker run -p 9090:9090 -v ~/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus


Grfana: 
docker run -d \
  --name=grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  --network host \
  grafana/grafana:latest



Sure! Based on your current metrics.js, here’s the full list of metrics your catalog service is exporting via OpenTelemetry to Prometheus:

Product Lifecycle Metrics
Metric Name	Type	Description
catalog_products_created_total	Counter	Total number of products created
catalog_products_updated_total	Counter	Total number of products updated
catalog_products_deleted_total	Counter	Total number of products deleted
Redis Cache Metrics
Metric Name	Type	Description
catalog_cache_hits_total	Counter	Number of times a cache hit occurred in Redis
catalog_cache_misses_total	Counter	Number of times a cache miss occurred in Redis
Kafka Metrics
Metric Name	Type	Description
catalog_kafka_publish_failures_total	Counter	Number of times Kafka publishing failed


now the goal is cdc! when new user signs up an email is sent to him welcome !!
when new product added , or deleted or updated ....
metrics of all signup counters and products added ...


fine it s not the goal all of this , but the integration of it in the system , we can say it s ok 

next move : slo dashboards , 
argo helm kustommize secrets and 

## ✅ Your diagnosis is 100% correct
You are seeing two Kafka messages because TWO different producers are emitting events:

## scrap config! 
🧠 Best practice (what I recommend for your setup)

Since you have multiple Node services:

job_name: 'auth-service'
job_name: 'catalog-service'
job_name: 'welcome-consumer's

🚨 Best practice (what YOU should do)

👉 One service = one port = one job

Since you are running multiple Node services, do this:

Service	Port	Job
auth-service	9465	auth-service
catalog-service	9464	catalog-service
welcome-consumer	9466	welcome-consumer
✅ Final verdict

✔ Prometheus allows it
❌ You should NOT do it
✔ Use different ports or single job


docker run -d -p 9090:9090 -v ~/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus

docker run -d \                                                                                         
  --name=grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  --network host \
  grafana/grafana:latest

  ## trivy 

  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.68.2

  trivy image --severity CRITICAL,HIGH --ignore-unfixed --no-progress cart-service:latest


for trivy there is an issue with glob and tar and i find out that is normal

sol : 
1️⃣ Minimal attack surface

Distroless images contain only what’s needed to run your app (Node runtime in your case).

No shell (bash), no package managers (apt, yum), no extra tools.

Less software → fewer vulnerabilities → less for an attacker to exploit.

2️⃣ Smaller OS footprint

Your image only includes the runtime + necessary system libraries.

Regular node:slim images include extra utilities like curl, tar, apt → these can have CVEs.

Smaller base = easier to audit + faster scanning.

3️⃣ Reduced CVEs

Distroless only packages actively maintained libraries for the runtime.

Trivy scans show 0 HIGH/CRITICAL vulnerabilities for your Node.js app on Distroless.

Regular images often show OS CVEs even if your Node packages are clean.

4️⃣ Immutable & read-only

Distroless encourages read-only filesystem for production containers, which mitigates risks if an attacker gains access.

⚡ Tradeoff

Pros: Secure, smaller, cleaner, fewer CVEs.

Cons:



No shell → debugging inside container is harder

Must copy everything your app needs during build


i used distroless for all backend and for frontend 
i keep the same dockerfile but add 
RUN apk update && apk add --no-cache libpng=1.6.54-r0
in nodejs and nginx and it passes the trivy scan

## minikube : 

Got it! Here’s a **step-by-step cheat sheet for Minikube nodes, profiles, and creating a new node/profile**.

---

## 1️⃣ Check your current Minikube nodes

```bash
minikube status
```

You’ll see something like:

```
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

---

## 2️⃣ List all Minikube profiles

```bash
minikube profile list
```

Example output:

```
|---------|---------|---------|---------|---------|
| Profile | VM Driver | Runtime | IP      | Version |
|---------|---------|---------|---------|---------|
| minikube | docker   | docker  | 192.168.49.2 | v1.30.1 |
| test     | docker   | docker  | 192.168.49.3 | v1.30.1 |
|---------|---------|---------|---------|---------|
```

✅ Each profile is basically a **separate Minikube cluster**.

---

## 3️⃣ Start a new Minikube node (profile)

```bash
minikube start -p <profile-name> --driver=docker --cpus=2 --memory=4096
```

Example:

```bash
minikube start -p test --driver=docker --cpus=2 --memory=4096
```

* `-p test` → name of the new profile/cluster
* `--cpus=2` → number of CPU cores
* `--memory=4096` → RAM in MB
* `--driver=docker` → use Docker driver (recommended for local)

---

## 4️⃣ Switch between Minikube profiles

```bash
minikube profile list    # see all profiles
minikube profile <name>  # set active profile
```

Example:

```bash
minikube profile test
```

> After this, any `kubectl` command uses this profile’s cluster.

---

## 5️⃣ Check nodes in the current cluster

```bash
kubectl get nodes
```

Example:

```
NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    control-plane  10m   v1.28.0
```

> Each profile has its own set of nodes.

---

## 6️⃣ Stop and delete a Minikube profile

* Stop:

```bash
minikube stop -p test
```

* Delete:

```bash
minikube delete -p test
```

---

### ✅ Summary

* **Profile** = separate Minikube cluster
* Use `-p <name>` to create, start, or delete
* `minikube profile <name>` switches active profile
* `kubectl get nodes` checks nodes inside the active cluster

---

## Sealed Secrets
1- install kubeseal

KUBESEAL_VERSION="0.34.0" # Replace with the latest version
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
kubeseal --version

2 - install kubeseal manually

kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml

2.1 - helm install

helm repo add bitnami-labs https://bitnami-labs.github.io/sealed-secrets/
helm install my-sealed-secrets bitnami-labs/sealed-secrets --version 2.18.0

3- create secret ! 

kubeseal \
  --controller-name=sealed-secrets \   ## service name of sealed controller
  --controller-namespace=kube-system \
  --format yaml < auth-secrets.yaml > auth-sealedsecret.yaml


4️##  Best practices

Use RBAC to limit who can access secrets in the cluster.

Enable encryption at rest for Kubernetes Secrets (e.g., EncryptionConfiguration in K8s).

Avoid logging secrets in your apps.

Use SealedSecrets + RBAC + K8s encryption → strong GitOps workflow.


## tfvars terraform 

1-Local
terraform plan -var-file="secret.tfvars"
terraform apply -var-file="secret.tfvars"


2-github

dont push tfvars and use it only when plan of course you use github secrets and when paln and apply you call it 

3- Optional: Terraform Cloud / Vault

For professional setups, you can store secrets in Terraform Cloud variables, AWS Secrets Manager, or HashiCorp Vault.

Terraform can pull them directly without storing secrets in local files.

## postgres ###

i faced some issues installing postgress using helm and terraform 

use oci chart works fine 

now we move to pvc with minikube : 
   ## terraform to destroy only one service: 
     terraform state list  
     terraform destroy -target=helm_release.kafka

for kafka after multiple tries i decide to use simple terraform with kubernetes resources and it works fine 
also for debezium i did the same thing and it works appearly only with debezium/connect:2.6 i will push this image to my repo incase of lost in main repo

then i do curl post after portForwarding svc  : 
curl -X POST http://localhost:8083/connectors \
     -H "Content-Type: application/json" \
     -d @pg-connector.json

  ## test cdc: 
   ssh to postgres pod then 
   psql -U appuser -d mv100db

   INSERT INTO products (name, description, price, image_url)
VALUES (
    'A Fake Nintendo Switch OLED',
    'Handheld gaming console with OLED screen.',
    349,
    'https://cdn.cloudflare.steamstatic.com/steam/apps/1627270/header.jpg'
);

then check kafka ui to see msg in kafka product topic

## other postgres command : 
SELECT * FROM products;
\dt to list all tables 

  INSERT INTO products (name, description, price, image_url)
VALUES (
    'A Fake Nintendo Switch OLED',
    'Handheld gaming console with OLED screen.',
    349,
    'https://cdn.cloudflare.steamstatic.com/steam/apps/1627270/header.jpg'
);
INSERT 0 1

check : 
curl http://localhost:8083/connectors/pg-auth-catalog-orders/status

i used multiple ns for every svc 
redis installed




## now back to ci especially for frontend ,

i made the stripe key as build args and tell the multi repo ci when service = frontend use those arg for orders catalog .. apis url , but for stripe key i made it
as a secret in github and then it will secure , not inside the container not anywhere :: fantastic


and then using k8s argo rollout and sealed secret 

kubectl create secret generic frontend-secrets \
  --from-literal=VITE_STRIPE_KEY=pk_test_51RaNzg4TJHeKoXcgSPviBiP7dixSbHCfU4lvSSCCX9LDUc4ebYILr5XOEaL3iJf9h3lMjO6w9Z6gnDW5lPD4wJXN00tI4PoG5y \
  --namespace=demo \
  --dry-run=client -o yaml > secret.yaml

  or 

  # stripe-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: frontend-secrets
  namespace: demo
type: Opaque
stringData:
  VITE_STRIPE_KEY: pk_test_5xxxx


kubeseal --format yaml < stripe-secret.yaml > stripe-sealedsecret.yaml

kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  --format yaml < stripe-secret.yaml > stripe-sealedsecret.yaml


## mtls