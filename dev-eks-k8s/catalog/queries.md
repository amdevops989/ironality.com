###############################################################
########  iMPORTAN    T########################################


2️⃣ Real-world metrics monitored

Typical SRE/DevOps metrics for canary:

Success rate / Error rate

istio_requests_total{response_code=~"5.."}

Must stay above 99–99.9% for auto-promote

Latency

histogram_quantile(0.95, istio_request_duration_milliseconds_bucket{...})

P95 latency spikes indicate degraded performance

Traffic distribution

Ensure canary receives expected % of traffic (e.g., 10%, 20%, 50%)

Retries / Timeouts

istio_requests_retries_total

response_flags=UT|UR|UH

Saturation / Resource usage

CPU, memory, pod availability


3️⃣ Real-world simulation

Step 1: Ramp-up traffic to canary

1–5% traffic → 50% → 100%

Observe metrics after each step

Step 2: Load test / chaos simulation

Simulate latency spikes, errors, retries (like your K6 script)

Check if success rate drops below threshold

Step 3: Auto-promote or rollback

Argo Rollouts decides based on AnalysisTemplate:

successCondition: result[0] > 99

failureCondition: result[0] < 99

Step 4: Observability

Use Prometheus + Grafana dashboards

Monitor p95, p99 latency, error rates, throughput (RPS)


Example of RealWorld 

apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-analysis
  namespace: demo
spec:
  args:
    - name: service
    - name: namespace
  metrics:
    - name: success-rate
      interval: 30s
      successCondition: result[0] > 99
      failureCondition: result[0] < 99
      provider:
        prometheus:
          address: http://prometheus.monitoring.svc:9090
          query: |
            100 * sum(rate(istio_requests_total{destination_service="{{args.service}}",reporter="destination",response_code=~"2.."}[1m]))
            / sum(rate(istio_requests_total{destination_service="{{args.service}}",reporter="destination"}[1m]))
    - name: p95-latency
      interval: 30s
      failureCondition: result[0] > 2  # seconds
      provider:
        prometheus:
          address: http://prometheus.monitoring.svc:9090
          query: |
            histogram_quantile(0.95,
              sum(rate(istio_request_duration_milliseconds_bucket{destination_service="{{args.service}}",reporter="destination"}[1m])) by (le)
            ) / 1000
    - name: error-rate
      interval: 30s
      failureCondition: result[0] > 1  # %
      provider:
        prometheus:
          address: http://prometheus.monitoring.svc:9090
          query: |
            100 * sum(rate(istio_requests_total{destination_service="{{args.service}}",reporter="destination",response_code=~"5.."}[1m]))
            / sum(rate(istio_requests_total{destination_service="{{args.service}}",reporter="destination"}[1m]))





## curling only canary pods : 
while true; do
  curl -H "x-canary: true" \
       -o /dev/null -s -w "%{http_code}\n" \
       http://frontend.localdev.me/
  sleep 1
done


## curling all versions stable and canary : 
while true; do
  curl -o /dev/null -s -w "%{http_code}\n" http://frontend.localdev.me/
  sleep 1

## querying canary only svc : 
# Canary request rate
sum(rate(istio_requests_total{
  destination_service="catalog-canary.demo.svc.cluster.local",
  response_code=~"2..",reporter="destination"
}[1m]))


## qyrying stable svc 

# Canary request rate
sum(rate(istio_requests_total{
  destination_service="catalog-stable.demo.svc.cluster.local",reporter="destination",
  response_code=~"2..",reporter="destination"
}[1m]))


## Success Rate Canary %
sum(rate(istio_requests_total{
    reporter="destination",
    destination_service_name="catalog-canary",
    response_code="200"
}[1m]))
/
sum(rate(istio_requests_total{
    reporter="destination",
    destination_service_name="catalog-canary"
}[1m]))
