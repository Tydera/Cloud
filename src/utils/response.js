/**
 * Standard success response
 */
function success(res, data, message = 'Success', statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
}

/**
 * Standard error response
 */
function error(res, message = 'An error occurred', statusCode = 500, errors = null) {
  const response = {
    success: false,
    error: message,
  };

  if (errors) {
    response.errors = errors;
  }

  return res.status(statusCode).json(response);
}

/**
 * Validation error response
 */
function validationError(res, errors) {
  return error(res, 'Validation failed', 400, errors);
}

/**
 * Unauthorized response
 */
function unauthorized(res, message = 'Unauthorized') {
  return error(res, message, 401);
}

/**
 * Forbidden response
 */
function forbidden(res, message = 'Forbidden') {
  return error(res, message, 403);
}

/**
 * Not found response
 */
function notFound(res, message = 'Resource not found') {
  return error(res, message, 404);
}

/**
 * Conflict response
 */
function conflict(res, message = 'Resource already exists') {
  return error(res, message, 409);
}

module.exports = {
  success,
  error,
  validationError,
  unauthorized,
  forbidden,
  notFound,
  conflict,
};
