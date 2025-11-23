const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validateRequest } = require('../middleware/validator');
const { loginSchema, registerSchema } = require('../validators/auth.validator');

// Register new user
router.post('/register', validateRequest(registerSchema), authController.register);

// Login
router.post('/login', validateRequest(loginSchema), authController.login);

// Logout
router.post('/logout', authController.logout);

// Refresh token
router.post('/refresh', authController.refreshToken);

// Verify token
router.get('/verify', authController.verifyToken);

module.exports = router;
