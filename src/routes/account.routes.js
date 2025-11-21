const express = require('express');
const router = express.Router();
const accountController = require('../controllers/account.controller');
const { authenticate } = require('../middleware/auth');

// Get all accounts for current user
router.get('/', authenticate, accountController.getUserAccounts);

// Get account by ID
router.get('/:id', authenticate, accountController.getAccountById);

// Create new account
router.post('/', authenticate, accountController.createAccount);

// Update account
router.put('/:id', authenticate, accountController.updateAccount);

// Delete account
router.delete('/:id', authenticate, accountController.deleteAccount);

// Get account balance
router.get('/:id/balance', authenticate, accountController.getAccountBalance);

module.exports = router;
