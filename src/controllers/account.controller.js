const db = require('../config/database');
const logger = require('../config/logger');

async function getUserAccounts(req, res) {
  try {
    const result = await db.query(
      `SELECT id, account_number, account_type, balance, currency, status, created_at, updated_at
       FROM accounts WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.id]
    );

    res.json({
      accounts: result.rows.map((account) => ({
        id: account.id,
        accountNumber: account.account_number,
        accountType: account.account_type,
        balance: parseFloat(account.balance),
        currency: account.currency,
        status: account.status,
        createdAt: account.created_at,
        updatedAt: account.updated_at,
      })),
      total: result.rows.length,
    });
  } catch (error) {
    logger.error('Get user accounts error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve accounts',
    });
  }
}

async function getAccountById(req, res) {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT id, user_id, account_number, account_type, balance, currency, status, created_at, updated_at
       FROM accounts WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    const account = result.rows[0];

    // Check if user owns this account
    if (account.user_id !== req.user.id) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'You do not have access to this account',
      });
    }

    res.json({
      id: account.id,
      accountNumber: account.account_number,
      accountType: account.account_type,
      balance: parseFloat(account.balance),
      currency: account.currency,
      status: account.status,
      createdAt: account.created_at,
      updatedAt: account.updated_at,
    });
  } catch (error) {
    logger.error('Get account by ID error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve account',
    });
  }
}

async function createAccount(req, res) {
  try {
    const { accountType, currency } = req.body;

    // Generate account number
    const accountNumber = `ACC${Date.now()}${Math.floor(Math.random() * 1000)}`;

    const result = await db.query(
      `INSERT INTO accounts (user_id, account_number, account_type, balance, currency, status, created_at, updated_at)
       VALUES ($1, $2, $3, 0.00, $4, 'active', NOW(), NOW())
       RETURNING id, account_number, account_type, balance, currency, status, created_at`,
      [req.user.id, accountNumber, accountType || 'savings', currency || 'USD']
    );

    const account = result.rows[0];

    logger.info('Account created', { userId: req.user.id, accountId: account.id });

    res.status(201).json({
      message: 'Account created successfully',
      account: {
        id: account.id,
        accountNumber: account.account_number,
        accountType: account.account_type,
        balance: parseFloat(account.balance),
        currency: account.currency,
        status: account.status,
        createdAt: account.created_at,
      },
    });
  } catch (error) {
    logger.error('Create account error', { error: error.message });
    res.status(500).json({
      error: 'Failed to create account',
    });
  }
}

async function updateAccount(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;

    // Check if account belongs to user
    const checkResult = await db.query('SELECT user_id FROM accounts WHERE id = $1', [id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    if (checkResult.rows[0].user_id !== req.user.id) {
      return res.status(403).json({
        error: 'Forbidden',
      });
    }

    const result = await db.query(
      `UPDATE accounts
       SET status = COALESCE($1, status),
           updated_at = NOW()
       WHERE id = $2
       RETURNING id, account_number, account_type, balance, currency, status`,
      [status, id]
    );

    const account = result.rows[0];

    logger.info('Account updated', { accountId: account.id, userId: req.user.id });

    res.json({
      message: 'Account updated successfully',
      account: {
        id: account.id,
        accountNumber: account.account_number,
        accountType: account.account_type,
        balance: parseFloat(account.balance),
        currency: account.currency,
        status: account.status,
      },
    });
  } catch (error) {
    logger.error('Update account error', { error: error.message });
    res.status(500).json({
      error: 'Failed to update account',
    });
  }
}

async function deleteAccount(req, res) {
  try {
    const { id } = req.params;

    // Check if account belongs to user and has zero balance
    const checkResult = await db.query(
      'SELECT user_id, balance FROM accounts WHERE id = $1',
      [id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    if (checkResult.rows[0].user_id !== req.user.id) {
      return res.status(403).json({
        error: 'Forbidden',
      });
    }

    if (parseFloat(checkResult.rows[0].balance) !== 0) {
      return res.status(400).json({
        error: 'Cannot delete account with non-zero balance',
      });
    }

    await db.query('DELETE FROM accounts WHERE id = $1', [id]);

    logger.info('Account deleted', { accountId: id, userId: req.user.id });

    res.json({
      message: 'Account deleted successfully',
    });
  } catch (error) {
    logger.error('Delete account error', { error: error.message });
    res.status(500).json({
      error: 'Failed to delete account',
    });
  }
}

async function getAccountBalance(req, res) {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT balance, currency, updated_at FROM accounts WHERE id = $1 AND user_id = $2`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Account not found',
      });
    }

    const account = result.rows[0];

    res.json({
      balance: parseFloat(account.balance),
      currency: account.currency,
      asOf: account.updated_at,
    });
  } catch (error) {
    logger.error('Get account balance error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve balance',
    });
  }
}

module.exports = {
  getUserAccounts,
  getAccountById,
  createAccount,
  updateAccount,
  deleteAccount,
  getAccountBalance,
};
