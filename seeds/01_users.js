const bcrypt = require('bcrypt');

exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex('audit_logs').del();
  await knex('transactions').del();
  await knex('accounts').del();
  await knex('users').del();

  // Hash passwords
  const adminPassword = await bcrypt.hash('admin123', 12);
  const userPassword = await bcrypt.hash('user123', 12);

  // Inserts seed entries
  const users = await knex('users')
    .insert([
      {
        email: 'admin@finnaslaim.com',
        password_hash: adminPassword,
        first_name: 'Admin',
        last_name: 'User',
        role: 'admin',
        is_active: true,
      },
      {
        email: 'user@finnaslaim.com',
        password_hash: userPassword,
        first_name: 'Test',
        last_name: 'User',
        role: 'user',
        is_active: true,
      },
      {
        email: 'john.doe@example.com',
        password_hash: userPassword,
        first_name: 'John',
        last_name: 'Doe',
        role: 'user',
        is_active: true,
      },
    ])
    .returning('*');

  return users;
};
