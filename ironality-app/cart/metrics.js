// metrics.js
const { metrics } = require('@opentelemetry/api');

const meter = metrics.getMeter('cart-service');

/* ---------------- Cart actions ---------------- */
const cartItemsAdded = meter.createCounter('cart_items_added_total', {
  description: 'Total number of items added to cart',
});

const cartCheckouts = meter.createCounter('cart_checkouts_total', {
  description: 'Total number of successful checkouts',
});

const cartCheckoutFailures = meter.createCounter('cart_checkout_failures_total', {
  description: 'Failed checkout attempts',
});

const cartReads = meter.createCounter('cart_reads_total', {
  description: 'Cart read operations',
});

/* ---------------- 💰 Money metrics ---------------- */

// Total revenue (lifetime)
const checkoutRevenueTotal = meter.createCounter(
  'cart_checkout_revenue_total',
  {
    description: 'Total checkout revenue (sum of all orders)',
    unit: 'currency',
  }
);

// Distribution of checkout amounts
const checkoutAmountHistogram = meter.createHistogram(
  'cart_checkout_amount',
  {
    description: 'Checkout amount distribution',
    unit: 'currency',
  }
);

module.exports = {
  cartItemsAdded,
  cartCheckouts,
  cartCheckoutFailures,
  cartReads,
  checkoutRevenueTotal,
  checkoutAmountHistogram,
};
