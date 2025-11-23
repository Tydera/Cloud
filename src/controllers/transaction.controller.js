const db = require('../config/database');
const logger = require('../config/logger');

async function getUserTransactions(req, res) {
  try {
    const result = await db.query(
      `SELECT t.id, t.account_id, t.transaction_type, t.amount, t.currency,
              t.description, t.reference_number, t.status, t.created_at, t.processed_at,
              a.account_number
       FROM transactions t
       JOIN accounts a ON t.account_id = a.id
       WHERE a.user_id = $1
       ORDER BY t.created_at DESC
       LIMIT 100`,
      [req.user.id]
    );

    res.json({
      transactions: result.rows.map((tx) => ({
        id: tx.id,
        accountId: tx.account_id,
        accountNumber: tx.account_number,
        transactionType: tx.transaction_type,
        amount: parseFloat(tx.amount),
        currency: tx.currency,
        description: tx.description,
        referenceNumber: tx.reference_number,
        status: tx.status,
        createdAt: tx.created_at,
        processedAt: tx.processed_at,
      })),
      total: result.rows.length,
    });
  } catch (error) {
    logger.error('Get user transactions error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve transactions',
    });
  }
}

async function getTransactionById(req, res) {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT t.*, a.account_number, a.user_id
       FROM transactions t
       JOIN accounts a ON t.account_id = a.id
       WHERE t.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Transaction not found',
      });
    }

    const tx = result.rows[0];

    // Check if user owns this transaction
    if (tx.user_id !== req.user.id) {
      return res.status(403).json({
        error: 'Forbidden',
      });
    }

    res.json({
      id: tx.id,
      accountId: tx.account_id,
      accountNumber: tx.account_number,
      transactionType: tx.transaction_type,
      amount: parseFloat(tx.amount),
      currency: tx.currency,
      description: tx.description,
      referenceNumber: tx.reference_number,
      status: tx.status,
      createdAt: tx.created_at,
      processedAt: tx.processed_at,
    });
  } catch (error) {
    logger.error('Get transaction by ID error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve transaction',
    });
  }
}

async function createTransaction(req, res) {
  const client = await db.getClient();

  try {
    const { accountId, transactionType, amount, description } = req.body;

    // Start transaction
    await client.query('BEGIN');

    // Check if account belongs to user
    const accountResult = await client.query(
      'SELECT user_id, balance, currency, status FROM accounts WHERE id = $1 FOR UPDATE',
      [accountId]
    );

    if (accountResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    const account = accountResult.rows[0];

    if (account.user_id !== req.user.id) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        error: 'Forbidden',
      });
    }

    if (account.status !== 'active') {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Account is not active',
      });
    }

    // Check sufficient balance for withdrawals
    const currentBalance = parseFloat(account.balance);
    const transactionAmount = parseFloat(amount);

    if (transactionType === 'withdrawal' && currentBalance < transactionAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Insufficient balance',
      });
    }

    // Calculate new balance
    const newBalance =
      transactionType === 'deposit'
        ? currentBalance + transactionAmount
        : currentBalance - transactionAmount;

    // Generate reference number
    const referenceNumber = `TXN${Date.now()}${Math.floor(Math.random() * 10000)}`;

    // Create transaction
    const txResult = await client.query(
      `INSERT INTO transactions
       (account_id, transaction_type, amount, currency, description, reference_number, status, created_at, processed_at)
       VALUES ($1, $2, $3, $4, $5, $6, 'completed', NOW(), NOW())
       RETURNING *`,
      [accountId, transactionType, amount, account.currency, description, referenceNumber]
    );

    // Update account balance
    await client.query(
      'UPDATE accounts SET balance = $1, updated_at = NOW() WHERE id = $2',
      [newBalance, accountId]
    );

    await client.query('COMMIT');

    const transaction = txResult.rows[0];

    logger.info('Transaction created', {
      userId: req.user.id,
      transactionId: transaction.id,
      amount: transaction.amount,
      type: transaction.transaction_type,
    });

    res.status(201).json({
      message: 'Transaction completed successfully',
      transaction: {
        id: transaction.id,
        accountId: transaction.account_id,
        transactionType: transaction.transaction_type,
        amount: parseFloat(transaction.amount),
        currency: transaction.currency,
        description: transaction.description,
        referenceNumber: transaction.reference_number,
        status: transaction.status,
        createdAt: transaction.created_at,
        processedAt: transaction.processed_at,
      },
      newBalance,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Create transaction error', { error: error.message });
    res.status(500).json({
      error: 'Failed to create transaction',
    });
  } finally {
    client.release();
  }
}

async function getAccountTransactions(req, res) {
  try {
    const { accountId } = req.params;

    // Check if account belongs to user
    const accountCheck = await db.query(
      'SELECT user_id FROM accounts WHERE id = $1',
      [accountId]
    );

    if (accountCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    if (accountCheck.rows[0].user_id !== req.user.id) {
      return res.status(403).json({
        error: 'Forbidden',
      });
    }

    const result = await db.query(
      `SELECT id, transaction_type, amount, currency, description,
              reference_number, status, created_at, processed_at
       FROM transactions
       WHERE account_id = $1
       ORDER BY created_at DESC
       LIMIT 100`,
      [accountId]
    );

    res.json({
      transactions: result.rows.map((tx) => ({
        id: tx.id,
        transactionType: tx.transaction_type,
        amount: parseFloat(tx.amount),
        currency: tx.currency,
        description: tx.description,
        referenceNumber: tx.reference_number,
        status: tx.status,
        createdAt: tx.created_at,
        processedAt: tx.processed_at,
      })),
      total: result.rows.length,
    });
  } catch (error) {
    logger.error('Get account transactions error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve transactions',
    });
  }
}

module.exports = {
  getUserTransactions,
  getTransactionById,
  createTransaction,
  getAccountTransactions,
};
