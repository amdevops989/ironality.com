require('dotenv').config();

'use strict';

/**
 * OpenTelemetry must be initialized BEFORE any other imports
 */

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { PrometheusExporter } = require('@opentelemetry/exporter-prometheus');
const { resourceFromAttributes } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

/**
 * Prometheus exporter
 */
const prometheusExporter = new PrometheusExporter(
  {
    port: Number(process.env.OTEL_PROM_PORT || 9464),
    endpoint: '/metrics',
  },
  () => {
    console.log(`📊 Prometheus metrics available at http://localhost:${process.env.OTEL_PROM_PORT}/metrics`);
  }
);

/**
 * Resource definition (NEW WAY)
 */
const resource = resourceFromAttributes({
  [SemanticResourceAttributes.SERVICE_NAME]: 'catalog-service',
  [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]:
    process.env.NODE_ENV || 'development',
});

/**
 * OpenTelemetry SDK
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

/**
 * Start SDK
 */
sdk.start();

/**
 * Graceful shutdown
 */
process.on('SIGTERM', async () => {
  try {
    await sdk.shutdown();
    console.log('🛑 OpenTelemetry shutdown complete');
  } catch (err) {
    console.error('❌ OpenTelemetry shutdown error', err);
  }
});
