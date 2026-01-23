require('dotenv').config();
const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'welcome-consumer',
  brokers: process.env.KAFKA_BROKERS.split(','),
});

const consumer = kafka.consumer({ groupId: 'welcome-service' });

async function run() {
  await consumer.connect();
  await consumer.subscribe({
    topic: process.env.KAFKA_TOPIC_USERS,
    fromBeginning: false,
  });

  console.log('👋 Welcome consumer running...');

  await consumer.run({
    eachMessage: async ({ message }) => {
      if (!message.value) return;

      const event = JSON.parse(message.value.toString());

      // Debezium INSERT only
      if (event.op !== 'c') return;

      const user = event.after;
      if (!user?.email) return;

      // 🎉 Welcome message
      console.log(`🎉 Welcome ${user.email}! Thanks for signing up.`);
    },
  });
}

run().catch(console.error);
