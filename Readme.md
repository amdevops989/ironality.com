## infra kafka postgres debezium kafka ui redis  using docker compose 




## ➜ curl -X POST http://localhost:8083/connectors \
     -H "Content-Type: application/json" \
     -d @connector-compose.json


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