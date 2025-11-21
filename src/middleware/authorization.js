const logger = require('../config/logger');

function authorize(allowedRoles = []) {
  return (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          error: 'Authentication required',
          message: 'You must be logged in to access this resource',
        });
      }

      const userRole = req.user.role;

      if (!allowedRoles.includes(userRole)) {
        logger.warn('Authorization failed', {
          userId: req.user.id,
          userRole,
          requiredRoles: allowedRoles,
          path: req.path,
        });

        return res.status(403).json({
          error: 'Forbidden',
          message: 'You do not have permission to access this resource',
        });
      }

      next();
    } catch (error) {
      logger.error('Authorization error', { error: error.message });
      return res.status(500).json({
        error: 'Authorization error',
        message: 'An error occurred during authorization',
      });
    }
  };
}

module.exports = {
  authorize,
};
