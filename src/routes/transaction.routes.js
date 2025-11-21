const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transaction.controller');
const { authenticate } = require('../middleware/auth');

// Get all transactions for current user
router.get('/', authenticate, transactionController.getUserTransactions);

// Get transaction by ID
router.get('/:id', authenticate, transactionController.getTransactionById);

// Create new transaction
router.post('/', authenticate, transactionController.createTransaction);

// Get transactions for specific account
router.get('/account/:accountId', authenticate, transactionController.getAccountTransactions);

module.exports = router;
