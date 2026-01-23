// otel.js
require('dotenv').config();
'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { PrometheusExporter } = require('@opentelemetry/exporter-prometheus');
const { resourceFromAttributes } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// Prometheus metrics exporter
const prometheusExporter = new PrometheusExporter(
  {
    port: Number(process.env.OTEL_PROM_PORT || 9467),
    endpoint: '/metrics',
  },
  () => {
    console.log(`📊 Prometheus metrics available at http://localhost:${process.env.OTEL_PROM_PORT}/metrics`);
  }
);

const resource = resourceFromAttributes({
  [SemanticResourceAttributes.SERVICE_NAME]: 'orders-service',
  [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
});

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
  try {
    await sdk.shutdown();
    console.log('🛑 OpenTelemetry shutdown complete');
  } catch (err) {
    console.error('❌ OpenTelemetry shutdown error', err);
  }
});
