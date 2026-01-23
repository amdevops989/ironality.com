require('dotenv').config();
const { Kafka, logLevel } = require('kafkajs');
const pino = require('pino');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });

// -------------------- Kafka Setup --------------------
const kafka = new Kafka({
  clientId: process.env.KAFKA_CLIENT_ID,
  brokers: process.env.KAFKA_BROKERS.split(','),
  logLevel: logLevel.INFO,
});

const consumer = kafka.consumer({ groupId: 'catalog-consumer-group' });

// -------------------- Consumer --------------------
async function startConsumer() {
  await consumer.connect();
  logger.info('✅ Kafka consumer connected');

  await consumer.subscribe({
    topic: process.env.KAFKA_TOPIC_PRODUCTS,
    fromBeginning: false, // only new messages
  });
  logger.info(`📥 Subscribed to topic ${process.env.KAFKA_TOPIC_PRODUCTS}`);

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        if (!message.value) {
          logger.warn(`⚠️ Skipping empty message on ${topic}`);
          return;
        }

        const event = JSON.parse(message.value.toString());
        logger.info({ event }, '📩 Product event received');
      } catch (err) {
        logger.error({ err, rawMessage: message.value?.toString() }, '❌ Failed to parse message');
      }
    },
  });
}

// -------------------- Start --------------------
startConsumer().catch((err) => {
  logger.fatal({ err }, '🔥 Consumer failed');
  process.exit(1);
});
