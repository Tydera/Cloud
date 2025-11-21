const db = require('../config/database');
const logger = require('../config/logger');

async function getCurrentUser(req, res) {
  try {
    const result = await db.query(
      `SELECT id, email, first_name, last_name, role, is_active, created_at, updated_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    const user = result.rows[0];

    res.json({
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role,
      isActive: user.is_active,
      createdAt: user.created_at,
      updatedAt: user.updated_at,
    });
  } catch (error) {
    logger.error('Get current user error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve user',
    });
  }
}

async function updateCurrentUser(req, res) {
  try {
    const { firstName, lastName } = req.body;

    const result = await db.query(
      `UPDATE users
       SET first_name = COALESCE($1, first_name),
           last_name = COALESCE($2, last_name),
           updated_at = NOW()
       WHERE id = $3
       RETURNING id, email, first_name, last_name, role`,
      [firstName, lastName, req.user.id]
    );

    const user = result.rows[0];

    logger.info('User updated', { userId: user.id });

    res.json({
      message: 'User updated successfully',
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
      },
    });
  } catch (error) {
    logger.error('Update user error', { error: error.message });
    res.status(500).json({
      error: 'Failed to update user',
    });
  }
}

async function getAllUsers(req, res) {
  try {
    const result = await db.query(
      `SELECT id, email, first_name, last_name, role, is_active, created_at
       FROM users
       ORDER BY created_at DESC`
    );

    res.json({
      users: result.rows.map((user) => ({
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        isActive: user.is_active,
        createdAt: user.created_at,
      })),
      total: result.rows.length,
    });
  } catch (error) {
    logger.error('Get all users error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve users',
    });
  }
}

async function getUserById(req, res) {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT id, email, first_name, last_name, role, is_active, created_at, updated_at
       FROM users WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    const user = result.rows[0];

    res.json({
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role,
      isActive: user.is_active,
      createdAt: user.created_at,
      updatedAt: user.updated_at,
    });
  } catch (error) {
    logger.error('Get user by ID error', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve user',
    });
  }
}

async function updateUser(req, res) {
  try {
    const { id } = req.params;
    const { firstName, lastName, role, isActive } = req.body;

    const result = await db.query(
      `UPDATE users
       SET first_name = COALESCE($1, first_name),
           last_name = COALESCE($2, last_name),
           role = COALESCE($3, role),
           is_active = COALESCE($4, is_active),
           updated_at = NOW()
       WHERE id = $5
       RETURNING id, email, first_name, last_name, role, is_active`,
      [firstName, lastName, role, isActive, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    const user = result.rows[0];

    logger.info('User updated by admin', { userId: user.id, adminId: req.user.id });

    res.json({
      message: 'User updated successfully',
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        isActive: user.is_active,
      },
    });
  } catch (error) {
    logger.error('Update user error', { error: error.message });
    res.status(500).json({
      error: 'Failed to update user',
    });
  }
}

async function deleteUser(req, res) {
  try {
    const { id } = req.params;

    const result = await db.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    logger.info('User deleted', { userId: id, deletedBy: req.user.id });

    res.json({
      message: 'User deleted successfully',
    });
  } catch (error) {
    logger.error('Delete user error', { error: error.message });
    res.status(500).json({
      error: 'Failed to delete user',
    });
  }
}

module.exports = {
  getCurrentUser,
  updateCurrentUser,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
};
