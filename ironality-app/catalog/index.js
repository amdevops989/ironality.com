require('./otel');        // <-- OpenTelemetry FIRST
require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');
const Redis = require('ioredis');
const { Kafka, logLevel } = require('kafkajs');
const pino = require('pino');
const morgan = require('morgan');

const {
  productsCreated,
  productsUpdated,
  productsDeleted,
  cacheHits,
  cacheMisses,
  kafkaPublishFailures,
} = require('./metrics');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const app = express();

// Use FRONTEND_URL env variable for allowed origin
const allowedOrigin = process.env.FRONTEND_URL || 'https://travelersources.com';

app.use(cors({
  origin: allowedOrigin,
  methods: ['GET','POST','PUT','DELETE','OPTIONS'],
  allowedHeaders: '*',
  credentials: true,
  maxAge: 3600 // 1 hour
}));
app.use(bodyParser.json());
app.use(morgan('combined'));

// -------------------- PostgreSQL --------------------
const pool = new Pool({
  user: process.env.PGUSER,
  host: process.env.PGHOST,
  database: process.env.PGDATABASE,
  password: process.env.PGPASSWORD,
  port: Number(process.env.PGPORT),
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Log each new client connection
pool.on('connect', () => {
  logger.info('🐘 PostgreSQL client connected');
});

// Log pool errors
pool.on('error', (err) => {
  logger.error({ err }, '❌ PostgreSQL pool error');
});

// Verify connection at startup
async function verifyPostgresConnection() {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1'); // simple test query
    client.release();

    logger.info({
      database: process.env.PGDATABASE,
      host: process.env.PGHOST,
      port: process.env.PGPORT,
    }, '✅ PostgreSQL connected successfully');
  } catch (err) {
    logger.fatal({ err }, '❌ PostgreSQL connection failed');
    throw err;
  }
}

// -------------------- Redis --------------------
const redis = new Redis(process.env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
});

redis.on('connect', () => {
  logger.info('🟢 Redis connected');
});

redis.on('error', (err) => {
  logger.error({ err }, '❌ Redis error');
});

// -------------------- Kafka --------------------
const kafka = new Kafka({
  clientId: process.env.KAFKA_CLIENT_ID || 'catalog-service',
  brokers: process.env.KAFKA_BROKERS.split(','),
  logLevel: logLevel.INFO,
});

const producer = kafka.producer();

// -------------------- Kafka Event Publisher --------------------
async function publishProductEvent(eventType, product) {
  try {
    await producer.send({
      topic: process.env.KAFKA_TOPIC_PRODUCTS,
      messages: [
        {
          key: String(product.id),
          value: JSON.stringify({
            event: eventType,
            timestamp: new Date().toISOString(),
            payload: product,
          }),
        },
      ],
    });
  } catch (err) {
    kafkaPublishFailures.add(1);
    logger.error({ err }, 'Kafka publish failed');
  }
}

// -------------------- Routes --------------------

// Create product
app.post('/products', async (req, res) => {
  const { name, description, price, image_url } = req.body;
  if (!name || !price) {
    return res.status(400).json({ error: 'name and price are required' });
  }

  const client = await pool.connect();
  try {
    const result = await client.query(
      `INSERT INTO products (name, description, price, image_url)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [name, description || null, price, image_url || null]
    );

    const product = result.rows[0];
    productsCreated.add(1);

    // await publishProductEvent('PRODUCT_CREATED', product);
    await redis.del('products:all');

    res.status(201).json(product);
  } catch (err) {
    logger.error({ err }, 'Create product failed');
    res.status(500).json({ error: 'internal_error' });
  } finally {
    client.release();
  }
});

// Get all products
app.get('/products', async (_, res) => {
  try {
    const cache = await redis.get('products:all');
    if (cache) {
      cacheHits.add(1);
      return res.json(JSON.parse(cache));
    }

    cacheMisses.add(1);
    const result = await pool.query('SELECT * FROM products ORDER BY id DESC');
    await redis.set('products:all', JSON.stringify(result.rows), 'EX', 60);

    res.json(result.rows);
  } catch (err) {
    logger.error({ err }, 'Fetch products failed');
    res.status(500).json({ error: 'internal_error' });
  }
});

// Get single product
app.get('/products/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM products WHERE id = $1',
      [req.params.id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'not_found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    logger.error({ err }, 'Fetch product failed');
    res.status(500).json({ error: 'internal_error' });
  }
});

// Update product
app.put('/products/:id', async (req, res) => {
  const { name, description, price, image_url } = req.body;
  const client = await pool.connect();

  try {
    const result = await client.query(
      `UPDATE products
       SET name=$1, description=$2, price=$3, image_url=$4
       WHERE id=$5
       RETURNING *`,
      [name, description, price, image_url, req.params.id]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'not_found' });
    }

    productsUpdated.add(1);
    const product = result.rows[0];

    // await publishProductEvent('PRODUCT_UPDATED', product);
    await redis.del('products:all');

    res.json(product);
  } catch (err) {
    logger.error({ err }, 'Update product failed');
    res.status(500).json({ error: 'internal_error' });
  } finally {
    client.release();
  }
});

// Delete product
app.delete('/products/:id', async (req, res) => {
  const client = await pool.connect();

  try {
    const result = await client.query(
      'DELETE FROM products WHERE id=$1 RETURNING *',
      [req.params.id]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'not_found' });
    }

    productsDeleted.add(1);
    // await publishProductEvent('PRODUCT_DELETED', result.rows[0]);
    await redis.del('products:all');

    res.json({ success: true });
  } catch (err) {
    logger.error({ err }, 'Delete product failed');
    res.status(500).json({ error: 'internal_error' });
  } finally {
    client.release();
  }
});

// Health
app.get('/health', (_, res) => {
  res.json({
    status: 'ok',
    service: 'catalog-service',
    time: new Date().toISOString(),
  });
});

// -------------------- Startup --------------------
async function start() {
  // Verify DB connection first
  await verifyPostgresConnection();

  // Connect Kafka producer
  await producer.connect();
  logger.info('✅ Kafka producer connected');

  // Start Express server
  const port = process.env.PORT || 3001;
  app.listen(port, () =>
    logger.info(`🚀 Catalog service running on port ${port}`)
  );
}

// Catch fatal startup errors
start().catch((err) => {
  logger.error({ err }, 'Fatal startup error');
  process.exit(1);
});
