require('./otel');       // MUST be first
require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');
const Redis = require('ioredis');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Kafka, logLevel } = require('kafkajs');
const morgan = require('morgan');
const pino = require('pino');

const {
  usersSignedUp,
  usersLoggedIn,
  cacheHits,
  cacheMisses,
  kafkaPublishFailures,
} = require('./metrics');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });

const app = express();

// -------------------- Middleware --------------------
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

app.use(cors(corsOptions));
// app.options('/*', cors(corsOptions));
app.use(bodyParser.json());
app.use(morgan('combined'));

// -------------------- PostgreSQL --------------------
const pool = new Pool({
  user: process.env.PGUSER,
  host: process.env.PGHOST,
  database: process.env.PGDATABASE,
  password: process.env.PGPASSWORD,
  port: process.env.PGPORT,
});

pool.on('connect', () => logger.info('🐘 PostgreSQL connected'));
pool.on('error', (err) => logger.error({ err }, '❌ PostgreSQL pool error'));

// -------------------- Redis --------------------
const redis = new Redis(process.env.REDIS_URL);
redis.on('connect', () => logger.info('🟢 Redis connected'));
redis.on('error', (err) => logger.error({ err }, '❌ Redis error'));

// -------------------- Kafka --------------------
const kafka = new Kafka({
  clientId: process.env.KAFKA_CLIENT_ID,
  brokers: process.env.KAFKA_BROKERS.split(','),
  logLevel: logLevel.INFO,
});

const producer = kafka.producer();

async function publishUserEvent(eventType, user) {
  try {
    await producer.send({
      topic: process.env.KAFKA_TOPIC_USERS,
      messages: [
        {
          key: String(user.id),
          value: JSON.stringify({
            event: eventType,
            timestamp: new Date().toISOString(),
            payload: { id: user.id, email: user.email },
          }),
        },
      ],
    });
    logger.info({ userId: user.id, eventType }, '📨 User event published');
  } catch (err) {
    kafkaPublishFailures.add(1);
    logger.error({ err }, '❌ Failed to publish Kafka user event');
  }
}

// -------------------- Routes --------------------

// Signup
app.post('/signup', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

  const client = await pool.connect();
  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await client.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email',
      [email, hash]
    );
    const user = result.rows[0];

    usersSignedUp.add(1);
    // await publishUserEvent('USER_CREATED', user);

    res.status(201).json({ success: true, id: user.id, email: user.email });
    logger.info({ userId: user.id }, '✅ User signed up');
  } catch (err) {
    logger.error({ err }, '❌ Signup failed');
    res.status(400).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Login
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const client = await pool.connect();

  try {
    const result = await client.query('SELECT * FROM users WHERE email=$1', [email]);
    if (!result.rows.length) return res.status(401).json({ error: 'Invalid credentials' });

    const user = result.rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '2h' });
    await redis.set(`session:${user.id}`, token, 'EX', 60 * 60 * 2);

    usersLoggedIn.add(1);

    res.json({ token });
    logger.info({ userId: user.id }, '🔑 User logged in');
  } catch (err) {
    logger.error({ err }, '❌ Login failed');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Health
app.get('/health', (_, res) =>
  res.json({ status: 'ok', service: 'auth-service', time: new Date().toISOString() })
);

// -------------------- Start --------------------
const port = process.env.PORT || 3002;
app.listen(port, async () => {
  logger.info(`🚀 Auth service running on port ${port}`);
  await producer.connect();
  logger.info('✅ Kafka producer connected');
});
