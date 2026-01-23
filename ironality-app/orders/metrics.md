Perfect! Since you now have **OpenTelemetry + Prometheus metrics** integrated, here’s a **complete list of all metrics** your `orders-service` exposes and how to query them. I’ll separate them into **business metrics** (from `metrics.js`) and **auto-instrumented OTEL metrics**.

---

## **1️⃣ Business Metrics (custom)**

These are the counters and histograms you explicitly created:

| Metric Name                      | Type      | Description                              | Example PromQL Query                                                                                                                                                                      |
| -------------------------------- | --------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `orders_created_total`           | Counter   | Total number of orders created           | `orders_created_total` → total orders created<br>`rate(orders_created_total[1m])` → creation rate per minute                                                                              |
| `orders_paid_total`              | Counter   | Total number of orders successfully paid | `orders_paid_total` → total orders paid<br>`rate(orders_paid_total[5m])` → rate of orders being paid                                                                                      |
| `orders_creation_failures_total` | Counter   | Total failed order creation attempts     | `orders_creation_failures_total` → total failed attempts                                                                                                                                  |
| `orders_payment_failures_total`  | Counter   | Total failed payments                    | `orders_payment_failures_total` → total failed payments                                                                                                                                   |
| `orders_revenue_total`           | Counter   | Total revenue from paid orders           | `orders_revenue_total` → cumulative revenue<br>`rate(orders_revenue_total[1m])` → revenue rate per minute                                                                                 |
| `orders_amount`                  | Histogram | Distribution of order amounts            | `histogram_quantile(0.5, sum(rate(orders_amount_bucket[5m])) by (le))` → median order amount<br>`histogram_quantile(0.95, sum(rate(orders_amount_bucket[5m])) by (le))` → 95th percentile |

> **Note:** `histogram_quantile` is Prometheus’ way to get percentiles from histogram metrics.

---

## **2️⃣ OpenTelemetry Auto-Instrumented Metrics**

OTEL automatically instruments Node.js runtime and HTTP requests. Key metrics:

| Metric Name                             | Type      | Description                                    | Example PromQL Query                                                                                                                             |
| --------------------------------------- | --------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `process_cpu_seconds_total`             | Counter   | Total CPU seconds consumed by the Node process | `rate(process_cpu_seconds_total[1m])` → CPU usage rate                                                                                           |
| `process_resident_memory_bytes`         | Gauge     | Memory used by Node process                    | `process_resident_memory_bytes` → current memory usage                                                                                           |
| `nodejs_active_handles_total`           | Gauge     | Number of active handles in Node.js            | `nodejs_active_handles_total`                                                                                                                    |
| `nodejs_active_requests_total`          | Gauge     | Number of active requests in Node.js           | `nodejs_active_requests_total`                                                                                                                   |
| `http_server_requests_duration_seconds` | Histogram | HTTP request duration per endpoint             | `histogram_quantile(0.95, sum(rate(http_server_requests_duration_seconds_bucket[5m])) by (le, route))` → 95th percentile latency per route       |
| `http_server_requests_total`            | Counter   | Total number of HTTP requests                  | `rate(http_server_requests_total[5m])` → requests per second<br>`sum(http_server_requests_total) by (method, route)` → requests per method/route |
| `http_server_responses_total`           | Counter   | Total HTTP responses by status code            | `sum(http_server_responses_total) by (status_code)` → responses grouped by HTTP status                                                           |

> These auto-instrumented metrics are enabled via `getNodeAutoInstrumentations()` in `otel.js`.

---

## **3️⃣ How to query them in Prometheus**

### **Basic queries**

```promql
# Total orders created
orders_created_total

# Rate of orders created per minute
rate(orders_created_total[1m])

# Total revenue
orders_revenue_total

# Revenue per minute
rate(orders_revenue_total[1m])

# Median order amount in the last 5 minutes
histogram_quantile(0.5, sum(rate(orders_amount_bucket[5m])) by (le))

# 95th percentile latency for HTTP GET /orders
histogram_quantile(0.95, sum(rate(http_server_requests_duration_seconds_bucket{route="/orders",method="GET"}[5m])) by (le))
```

### **Combine metrics**

```promql
# Average revenue per paid order
rate(orders_revenue_total[5m]) / rate(orders_paid_total[5m])

# Failure rate of order creation
rate(orders_creation_failures_total[5m]) / rate(orders_created_total[5m])
```

---

✅ **Tips:**

1. You can browse **Prometheus metrics** directly in the browser:
   `http://localhost:9467/metrics`
2. Histograms create `*_bucket`, `*_sum`, `*_count` series—use `histogram_quantile()` for percentiles.
3. All custom business metrics are **prefixed with `orders_`**, so you can filter by `orders_` to see them quickly.

---

If you want, I can **also create a ready-made Prometheus dashboard JSON** for **Grafana/Kiali** with all these metrics and useful panels like:

* Orders per minute
* Revenue per minute
* Failures per type
* 95th percentile order latency

This way you can **just import it and have a full monitoring view**.

Do you want me to do that next?
