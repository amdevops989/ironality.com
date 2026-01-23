// index.js
require('dotenv').config();
require('./otel'); // Start OpenTelemetry before anything else
'use strict';

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const Stripe = require('stripe');
const axios = require('axios');

const metrics = require('./metrics');

const app = express();
app.use(cors());
app.use(express.json());

const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

// Environment variables
const ORDERS_SERVICE_URL = process.env.ORDERS_SERVICE_URL;
const SUCCESS_URL = process.env.SUCCESS_URL;
const CANCEL_URL = process.env.CANCEL_URL;
const PORT = process.env.PORT || 3005;

// -------------------- Routes -------------------- //

// Stripe Webhook (raw body)
app.post('/payments/webhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('⚠️ Webhook signature verification failed:', err.message);
    metrics.paymentsFailed.add(1);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log('🔔 Received Stripe event:', event.type);

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const orderId = session.metadata.orderId;
    const paymentIntent = session.payment_intent;

    try {
      await axios.put(`${ORDERS_SERVICE_URL}/${orderId}/paid`, { paymentIntent });
      console.log(`🟢 Order ${orderId} updated in Orders service`);
      metrics.paymentsSucceeded.add(1, { orderId });
      metrics.paymentAmountHistogram.record(session.amount_total / 100, { orderId });
    } catch (err) {
      console.error('❌ Failed to update Orders service:', err.message);
      metrics.paymentsFailed.add(1, { orderId });
    }
  }

  res.json({ received: true });
});

// Create Stripe Checkout Session
app.post('/payments/create-checkout-session', async (req, res) => {
  try {
    const { orderId, amount } = req.body;
    if (!orderId || !amount)
      return res.status(400).json({ error: 'Missing orderId or amount' });

    console.log(`🧾 Creating checkout for order ${orderId} with amount $${amount}`);
    metrics.checkoutSessionsCreated.add(1, { orderId });
    metrics.paymentAmountHistogram.record(amount, { orderId });

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: { name: `Order #${orderId}` },
            unit_amount: Math.round(amount * 100),
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${SUCCESS_URL}?orderId=${orderId}`,
      cancel_url: CANCEL_URL,
      metadata: { orderId },
    });

    console.log(`✅ Checkout session created: ${session.id}`);
    res.json({ url: session.url });
  } catch (err) {
    console.error('❌ Error creating checkout session:', err.message);
    metrics.paymentsFailed.add(1);
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/', (_req, res) => res.json({ status: 'Payments service running ✅' }));

// Start server
app.listen(PORT, () => console.log(`💳 Payments service listening on port ${PORT}`));
