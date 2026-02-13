RoadMap
---

## **1️⃣ AWS Foundation / Org Level Modules (with KMS)**

* **AWS Organization / Accounts / SSO**
* **AWS Config**
* **CloudTrail**
* **SSM Parameter Store**
* **KMS**

  * Used for encrypting SSM parameters, secrets, EBS volumes, RDS, and S3 buckets.
  * Must be created **before** workloads or other resources that require encryption.

---
##
## **2️⃣ Networking / Cluster Base**

* **VPC**
* **IAM Roles for EKS**
* **EKS Cluster**
* **Karpenter**
* **ExternalDNS**

---

## **3️⃣ Security / Policy Layer**

* **Falco**
* **PSA (Pod Security Admission)**
* **Kyverno**
* **Sealed-Secrets**

> PSA first, then Kyverno. Sealed-Secrets requires KMS if using AWS for secret encryption.

---

## **4️⃣ Certificate / Ingress / Mesh**

* **Cert-Manager**
* **Istio**
* **Route53**
* **Ingress Gateways with TLS secrets**

---

## **5️⃣ Observability / Monitoring Layer (with AlertRules)**

* **Prometheus + Grafana**
* **Loki + PVC**
* **AlertRules** (PrometheusRule CRDs)

  * Define alerts for CPU, memory, pod restarts, node issues, etc.
  * Must be deployed **after Prometheus** but **before workloads** so you can monitor apps immediately.

---

## **6️⃣ GitOps / Deployment**

* **ArgoCD**
* **Argo Rollouts**

---

## **7️⃣ Stateful / Data Layer**

* **Postgres + PVC**
* **Kafka + PVC**
* **Debezium**
* **Redis + PVC**
* **K10 Backup**

> KMS can be used here to encrypt secrets, PVCs, and S3 backups.

---

## **8️⃣ Serverless / Event Modules**

* **Lambdas**
* **EventBridge**

---

## **9️⃣ Application Microservices**

* Frontend → `travelersources.com`
* Catalog API → `api.travelersources.com/catalog`
* Auth API → `api.travelersources.com/auth`
* Cart API → `api.travelersources.com/cart`
* Orders API → `api.travelersources.com/orders`
* Payments API → `api.travelersources.com/payments`

> At this stage, TLS, DNS, PSA, KMS encryption, AlertRules, and security policies are all in place.

---

### **Updated Quick Reference Table (with KMS + AlertRules)**

| Step | Modules                                    | Notes                      |
| ---- | ------------------------------------------ | -------------------------- |
| 1    | AWS Org, SSO, Config, CloudTrail, SSM, KMS | Foundation + encryption    |
| 2    | VPC, IAM, EKS, Karpenter, ExternalDNS      | Cluster + DNS              |
| 3    | Falco, PSA, Kyverno, Sealed-Secrets        | Pod-level security         |
| 4    | Cert-Manager, Istio, Route53               | TLS + ingress              |
| 5    | Prometheus + Grafana, Loki, AlertRules     | Observability + monitoring |
| 6    | ArgoCD + Argo Rollouts                     | GitOps & deployment        |
| 7    | Postgres, Kafka, Debezium, Redis, K10      | Stateful apps              |
| 8    | Lambdas, EventBridge                       | Serverless / triggers      |
| 9    | Application Microservices                  | Frontend + APIs            |


