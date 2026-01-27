// otel.js
require('dotenv').config();
'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { PrometheusExporter } = require('@opentelemetry/exporter-prometheus');
const { resourceFromAttributes } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const promPort = Number(process.env.OTEL_PROM_PORT || 9466);

/**
 * 📊 Prometheus exporter (PULL model)
 */
const prometheusExporter = new PrometheusExporter(
  {
    port: promPort,
    endpoint: '/metrics',
  },
  () => {
    console.log(`📊 Metrics exposed at http://localhost:${promPort}/metrics`);
  }
);

/**
 * 🏷 Service identity
 */
const resource = resourceFromAttributes({
  [SemanticResourceAttributes.SERVICE_NAME]: 'cart-service',
  [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]:
    process.env.NODE_ENV || 'development',
});

/**
 * 🚀 Start OpenTelemetry SDK (METRICS ONLY)
 */
const sdk = new NodeSDK({
  resource,
  metricReader: prometheusExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
  ],
});

sdk.start();

process.on('SIGTERM', async () => {
  await sdk.shutdown();
  console.log('🛑 OpenTelemetry shut down');
});
