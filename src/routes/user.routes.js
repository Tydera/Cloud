const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { authenticate } = require('../middleware/auth');
const { authorize } = require('../middleware/authorization');

// Get current user profile
router.get('/me', authenticate, userController.getCurrentUser);

// Update current user profile
router.put('/me', authenticate, userController.updateCurrentUser);

// Get all users (admin only)
router.get('/', authenticate, authorize(['admin']), userController.getAllUsers);

// Get user by ID (admin only)
router.get('/:id', authenticate, authorize(['admin']), userController.getUserById);

// Update user (admin only)
router.put('/:id', authenticate, authorize(['admin']), userController.updateUser);

// Delete user (admin only)
router.delete('/:id', authenticate, authorize(['admin']), userController.deleteUser);

module.exports = router;
