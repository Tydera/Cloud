const app = require('./app');
const logger = require('./config/logger');
const db = require('./config/database');

const PORT = process.env.PORT || 8080;
const NODE_ENV = process.env.NODE_ENV || 'development';

async function startServer() {
  try {
    // Test database connection
    await db.testConnection();
    logger.info('Database connection established');

    // Start server
    const server = app.listen(PORT, '0.0.0.0', () => {
      logger.info(`FinNaslain Financial Solution started`, {
        port: PORT,
        environment: NODE_ENV,
        nodeVersion: process.version,
      });
    });

    // Handle server errors
    server.on('error', (error) => {
      if (error.syscall !== 'listen') {
        throw error;
      }

      switch (error.code) {
        case 'EACCES':
          logger.error(`Port ${PORT} requires elevated privileges`);
          process.exit(1);
          break;
        case 'EADDRINUSE':
          logger.error(`Port ${PORT} is already in use`);
          process.exit(1);
          break;
        default:
          throw error;
      }
    });

    return server;
  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
}

// Start the server
startServer();

module.exports = startServer;
