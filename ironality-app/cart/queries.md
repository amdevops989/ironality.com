cart_checkout_amount_sum


cart_checkout_amount_count


cart_checkout_amount_sum / cart_checkout_amount_count


rate(cart_checkout_amount_sum[1m])


Perfect — since you are using **Prometheus via OpenTelemetry**, the `cart_checkout_amount` is a **histogram**, not a simple counter. That affects how you query it. Let me explain carefully.

---

## 1️⃣ What Prometheus stores for a histogram

If you have:

```js
const checkoutAmountHistogram = meter.createHistogram('cart_checkout_amount', {...});
```

Prometheus automatically creates **multiple metrics**:

| Metric name                   | What it means                             |
| ----------------------------- | ----------------------------------------- |
| `cart_checkout_amount_bucket` | Count of checkouts ≤ each bucket boundary |
| `cart_checkout_amount_sum`    | Sum of all checkout amounts               |
| `cart_checkout_amount_count`  | Total number of checkout events           |

**Example:**

```text
cart_checkout_amount_bucket{le="50"} 2
cart_checkout_amount_bucket{le="100"} 5
cart_checkout_amount_bucket{le="200"} 7
cart_checkout_amount_sum 620
cart_checkout_amount_count 7
```

---

## 2️⃣ Common queries

### a) Total checkout revenue

```promql
cart_checkout_amount_sum
```

✅ Sum of all checkout amounts recorded.

### b) Number of checkouts

```promql
cart_checkout_amount_count
```

✅ Total count of checkout events.

### c) Average order value

```promql
cart_checkout_amount_sum / cart_checkout_amount_count
```

✅ Average checkout amount.

### d) Rate of revenue per minute

```promql
rate(cart_checkout_amount_sum[1m])
```

✅ How much money is coming in per minute.

### e) P95 / P99 order value

```promql
histogram_quantile(
  0.95,
  sum by (le) (rate(cart_checkout_amount_bucket[5m]))
)
```

✅ 95th percentile of order values over last 5 minutes.

---

## 3️⃣ Quick example for Grafana panel

* **Panel title:** `Checkout Revenue per Minute`
* **PromQL:**

```promql
rate(cart_checkout_amount_sum[1m])
```

* **Panel title:** `Average Order Value`
* **PromQL:**

```promql
cart_checkout_amount_sum / cart_checkout_amount_count
```

* **Panel title:** `P95 Order Value`
* **PromQL:**

```promql
histogram_quantile(
  0.95,
  sum by (le) (rate(cart_checkout_amount_bucket[5m]))
)
```

---

## 4️⃣ Optional: simple table of last checkout amounts

If you want a **list of last N checkouts**, you need to **log them** separately or push them to **Kafka**, because Prometheus only aggregates.

---

If you want, I can write a **ready-to-use PromQL cheat sheet** for all your **cart metrics** (`items added`, `checkouts`, `checkout amount`, `failures`) for Grafana dashboards.

Do you want me to do that?
