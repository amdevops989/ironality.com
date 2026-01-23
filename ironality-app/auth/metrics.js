const { metrics } = require('@opentelemetry/api');

const meter = metrics.getMeter('auth-service');

// Users lifecycle
const usersSignedUp = meter.createCounter('auth_users_signed_up_total', {
  description: 'Total number of users signed up',
});

const usersLoggedIn = meter.createCounter('auth_users_logged_in_total', {
  description: 'Total number of users logged in',
});

// Cache metrics
const cacheHits = meter.createCounter('auth_cache_hits_total', {
  description: 'Redis cache hits',
});

const cacheMisses = meter.createCounter('auth_cache_misses_total', {
  description: 'Redis cache misses',
});

// Kafka metrics
const kafkaPublishFailures = meter.createCounter('auth_kafka_publish_failures_total', {
  description: 'Kafka publish failures',
});

module.exports = {
  usersSignedUp,
  usersLoggedIn,
  cacheHits,
  cacheMisses,
  kafkaPublishFailures,
};
