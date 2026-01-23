// metrics.js
'use strict';

const { metrics } = require('@opentelemetry/api');

const meter = metrics.getMeter('orders-service');

/* -------------------- Business Metrics -------------------- */

// Count of orders created
const ordersCreated = meter.createCounter('orders_created_total', {
  description: 'Total number of orders created',
});

// Count of orders marked as paid
const ordersPaid = meter.createCounter('orders_paid_total', {
  description: 'Total number of orders successfully paid',
});

// Count of failed order creations
const ordersCreationFailures = meter.createCounter('orders_creation_failures_total', {
  description: 'Failed order creation attempts',
});

// Count of failed payments
const ordersPaymentFailures = meter.createCounter('orders_payment_failures_total', {
  description: 'Failed payment attempts',
});

// Total revenue from paid orders
const ordersRevenueTotal = meter.createCounter('orders_revenue_total', {
  description: 'Total revenue from paid orders',
  unit: 'currency',
});

// Histogram of order amounts (paid or pending)
const orderAmountHistogram = meter.createHistogram('orders_amount', {
  description: 'Distribution of order amounts',
  unit: 'currency',
});

/* -------------------- Export -------------------- */
module.exports = {
  ordersCreated,
  ordersPaid,
  ordersCreationFailures,
  ordersPaymentFailures,
  ordersRevenueTotal,
  orderAmountHistogram,
};
