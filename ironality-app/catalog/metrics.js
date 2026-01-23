const { metrics } = require('@opentelemetry/api');

const meter = metrics.getMeter('catalog-service');

// Product lifecycle
const productsCreated = meter.createCounter(
  'catalog_products_created_total',
  {
    description: 'Total number of products created',
  }
);

const productsUpdated = meter.createCounter(
  'catalog_products_updated_total',
  {
    description: 'Total number of products updated',
  }
);

const productsDeleted = meter.createCounter(
  'catalog_products_deleted_total',
  {
    description: 'Total number of products deleted',
  }
);

// Cache
const cacheHits = meter.createCounter(
  'catalog_cache_hits_total',
  {
    description: 'Redis cache hits',
  }
);

const cacheMisses = meter.createCounter(
  'catalog_cache_misses_total',
  {
    description: 'Redis cache misses',
  }
);

// Kafka
const kafkaPublishFailures = meter.createCounter(
  'catalog_kafka_publish_failures_total',
  {
    description: 'Kafka publish failures',
  }
);

module.exports = {
  productsCreated,
  productsUpdated,
  productsDeleted,
  cacheHits,
  cacheMisses,
  kafkaPublishFailures,
};
