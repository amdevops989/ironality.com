// index.js
require('./otel'); // 🔴 MUST BE FIRST
require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');
const Redis = require('ioredis');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const pino = require('pino');

/* ---------------- Logger ---------------- */
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
});

/* ---------------- Metrics ---------------- */
const {
  cartItemsAdded,
  cartCheckouts,
  cartCheckoutFailures,
  cartReads,
  checkoutRevenueTotal,
  checkoutAmountHistogram,
} = require('./metrics');





const app = express();
app.use(bodyParser.json());
const cors = require('cors');

/* ---------------- CORS ---------------- */
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // 🔑 VERY IMPORTANT

/* ---------------- Redis ---------------- */
const redis = new Redis(process.env.REDIS_URL);

redis.on('connect', () => {
  logger.info(
    { service: 'redis', url: process.env.REDIS_URL },
    '🟢 Redis connected'
  );
});

redis.on('error', (err) => {
  logger.error({ err }, '❌ Redis error');
});

/* ---------------- PostgreSQL ---------------- */
const pool = new Pool({
  user: process.env.PGUSER,
  host: process.env.PGHOST,
  database: process.env.PGDATABASE,
  password: process.env.PGPASSWORD,
  port: Number(process.env.PGPORT),
});

pool.on('connect', () => {
  logger.info(
    {
      service: 'postgres',
      host: process.env.PGHOST,
      db: process.env.PGDATABASE,
    },
    '🐘 PostgreSQL connected'
  );
});

pool.on('error', (err) => {
  logger.error({ err }, '❌ PostgreSQL pool error');
});

/* ---------------- Auth ---------------- */
function authMiddleware(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth) {
    logger.warn('🔒 Missing Authorization header');
    return res.sendStatus(401);
  }

  try {
    const token = auth.split(' ')[1];
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (err) {
    logger.warn({ err }, '🔒 Invalid JWT');
    res.sendStatus(401);
  }
}

/* ---------------- Routes ---------------- */

// Add item to cart
app.post('/cart/add', authMiddleware, async (req, res) => {
  const { productId, qty } = req.body;
  const userId = req.user.userId;

  await redis.hincrby(`cart:${userId}`, productId, qty || 1);
  cartItemsAdded.add(qty || 1);

  logger.info(
    { userId, productId, qty: qty || 1 },
    '🛒 Item added to cart'
  );

  res.json({ success: true });
});

// View cart
app.get('/cart', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const items = await redis.hgetall(`cart:${userId}`);

  cartReads.add(1);

  logger.info({ userId }, '📦 Cart read');

  res.json(items);
});

// Checkout
app.post('/cart/checkout', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const client = await pool.connect();

  try {
    // 1️⃣ Get cart items from Redis
    const items = await redis.hgetall(`cart:${userId}`);
    if (!Object.keys(items).length) {
      return res.status(400).json({ error: 'Cart is empty' });
    }

    // 2️⃣ Calculate total price by fetching product prices from Postgres
    let totalAmount = 0;
    for (const [productId, qtyStr] of Object.entries(items)) {
      const qty = Number(qtyStr);
      const r = await client.query('SELECT price FROM products WHERE id=$1', [productId]);
      if (r.rows.length) {
        const price = Number(r.rows[0].price);
        totalAmount += price * qty;
      } else {
        logger.warn({ userId, productId }, '⚠️ Product not found, skipping');
      }
    }

    if (totalAmount === 0) {
      return res.status(400).json({ error: 'No valid products in cart' });
    }

    // 3️⃣ Insert order in Postgres
    await client.query('BEGIN');
    const result = await client.query(
      'INSERT INTO orders (user_id, amount, status) VALUES ($1,$2,$3) RETURNING id',
      [userId, totalAmount, 'pending']
    );
    await client.query('COMMIT');

    // 4️⃣ Record metrics
    cartCheckouts.add(1);
    checkoutRevenueTotal.add(totalAmount);
    checkoutAmountHistogram.record(totalAmount);

    // 5️⃣ Clear cart
    await redis.del(`cart:${userId}`);

    logger.info(
      { userId, orderId: result.rows[0].id, amount: totalAmount },
      '✅ Checkout successful'
    );

    res.json({
      success: true,
      orderId: result.rows[0].id,
      amount: totalAmount,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    cartCheckoutFailures.add(1);

    logger.error({ err, userId }, '❌ Checkout failed');
    res.status(500).json({ error: 'checkout failed' });
  } finally {
    client.release();
  }
});


/* ---------------- Start ---------------- */
const port = process.env.PORT || 3003;
app.listen(port, () => {
  logger.info(
    {
      service: 'cart-service',
      port,
      env: process.env.NODE_ENV || 'development',
    },
    '🚀 Cart service started'
  );
});
