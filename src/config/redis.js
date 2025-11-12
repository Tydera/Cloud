const redis = require('redis');
const logger = require('./logger');

let client = null;

async function getRedisClient() {
  if (client && client.isOpen) {
    return client;
  }

  try {
    client = redis.createClient({
      socket: {
        host: process.env.REDIS_HOST || 'redis',
        port: parseInt(process.env.REDIS_PORT) || 6379,
      },
      password: process.env.REDIS_PASSWORD || undefined,
      database: parseInt(process.env.REDIS_DB) || 0,
    });

    client.on('error', (err) => {
      logger.error('Redis client error', { error: err.message });
    });

    client.on('connect', () => {
      logger.info('Redis client connected');
    });

    await client.connect();
    return client;
  } catch (error) {
    logger.error('Failed to connect to Redis', { error: error.message });
    throw error;
  }
}

async function get(key) {
  try {
    const client = await getRedisClient();
    return await client.get(key);
  } catch (error) {
    logger.error('Redis GET error', { key, error: error.message });
    return null;
  }
}

async function set(key, value, ttl = 3600) {
  try {
    const client = await getRedisClient();
    await client.setEx(key, ttl, value);
    return true;
  } catch (error) {
    logger.error('Redis SET error', { key, error: error.message });
    return false;
  }
}

async function del(key) {
  try {
    const client = await getRedisClient();
    await client.del(key);
    return true;
  } catch (error) {
    logger.error('Redis DEL error', { key, error: error.message });
    return false;
  }
}

module.exports = {
  getRedisClient,
  get,
  set,
  del,
};
