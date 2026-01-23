'use strict';
const { metrics } = require('@opentelemetry/api');

const meter = metrics.getMeter('payments-service');

/* -------------------- Business Metrics -------------------- */

// Count of checkout sessions created
const checkoutSessionsCreated = meter.createCounter('checkout_sessions_created_total', {
  description: 'Total number of Stripe checkout sessions created',
});

// Count of successful payments
const paymentsSucceeded = meter.createCounter('payments_succeeded_total', {
  description: 'Total number of successful payments',
});

// Count of failed payments
const paymentsFailed = meter.createCounter('payments_failed_total', {
  description: 'Total number of failed payments',
});

// Histogram of payment amounts
const paymentAmountHistogram = meter.createHistogram('payment_amounts', {
  description: 'Distribution of payment amounts',
  unit: 'currency',
});

module.exports = {
  checkoutSessionsCreated,
  paymentsSucceeded,
  paymentsFailed,
  paymentAmountHistogram,
};
