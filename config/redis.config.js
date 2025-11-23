/**
 * Redis Configuration for FinNaslain Financial Solution
 */

module.exports = {
  development: {
    host: process.env.REDIS_HOST || 'redis',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    db: parseInt(process.env.REDIS_DB || '0'),
    retryStrategy: (times) => {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
  },

  production: {
    host: process.env.REDIS_HOST,
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0'),
    retryStrategy: (times) => {
      if (times > 10) {
        return null; // Stop retrying
      }
      const delay = Math.min(times * 100, 3000);
      return delay;
    },
    reconnectOnError: (err) => {
      const targetError = 'READONLY';
      if (err.message.includes(targetError)) {
        return true;
      }
      return false;
    },
    maxRetriesPerRequest: 3,
    enableReadyCheck: true,
    enableOfflineQueue: true,
  },

  cache: {
    ttl: {
      short: 300, // 5 minutes
      medium: 1800, // 30 minutes
      long: 3600, // 1 hour
      day: 86400, // 24 hours
    },
  },
};
